#!/bin/bash
#===============================================================================
# Nom:         install.sh
# Description: Installe les paquets de base pour un PC de bureau (Jeu+Code)
# Auteur:      Adam Rousselle
# Version:     1.0.0
# Date:        2025-06-09
# Usage:       ./install.sh
#===============================================================================

script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")

source "$script_dir/utils/global/fct.sh"

restart_after=false

# -- ÉTAPE 1
#Pour mieux gérer les variables d'environement, on ne doit pas lancer en sudo par défaut, mais seulement
if [ -n "$SUDO_USER" ]; then # On est en sudo
    fout "Le script ne doit pas être lancé en sudo (le mot de passe sudo sera ensuite demmandé pour gérer les variables d'environement)"
else
    HOME_FOLDER=$HOME
    USER=$(whoami)
fi
sudo echo -e "----------------------------------\nLancement du script d'installation\n----------------------------------\n\n"

if ask_yn "Pour prendre en compte les variables d'environement, l'ordinateur devra redémarrer. Autoriser le redémarrage à la fin de l'installation ? (refuser pour voir les logs)"; then
    restart_after=true
fi

#Vérifier que git est installé avec un utilisateur valide
git --version || { echo "Veuillez installer et configurer un utilisateur git."; exit 1; }
ssh -T git@github.com
GITHUB_STATUS=$?
if [ $GITHUB_STATUS -eq 1 ]; then
    echo "Authentification GitHub réussie"
else
    echo "Erreur, l'utilisateur doit avoir une authentification github via SSH."
    exit 1
fi
# Installation de l'architecture perso
ARCHITECTURE_PERSO=true
if ask_yn "Appliquer l'architecture ~/dev (conseillé) ? Le dossier ~/dev contiendra les repos github perso, externes (services), et local_scripts (ce repo), pour minimiser le nombre de dossiers cachés dans ~/. et regrouper tous les repo gitub."; then
    ARCHITECTURE_PERSO=true
else
    ARCHITECTURE_PERSO=false
fi


# -- ÉTAPE 2
#On créé l'architecture perso et on déplace le répertoire local_scripts si besoin
PATH_LOCAL_SCRIPTS="$HOME_FOLDER/dev/projets/local_scripts"
PATH_REPOS_EXTERNES="$HOME_FOLDER/dev/repos_externes"
# On vérifie si les répertoires ~/dev/local_scripts et ~/dev/repos_externes existent pour ranger des repo plus tard si besoin
if [ -d "$PATH_LOCAL_SCRIPTS" ]; then
    LOCAL_SCRIPTS_EXISTS=true
else
    LOCAL_SCRIPTS_EXISTS=false
fi
if [ -d "$PATH_REPOS_EXTERNES" ]; then
    REPOS_EXTERNES_EXISTS=true
else
    REPOS_EXTERNES_EXISTS=false
fi
# On regarde si on doit respecter l'architecture ~/dev/
if $ARCHITECTURE_PERSO; then
    # Gestion de ~/dev/repos_externes
    if ! [ "$REPOS_EXTERNES_EXISTS" = false ]; then
        mkdir -p "$PATH_REPOS_EXTERNES"
        REPOS_EXTERNES_EXISTS=true
    fi
        
    # Gestion de ~/dev/local_scripts
    if ! [ $script_dir == "$PATH_LOCAL_SCRIPTS" ]; then # Si le programme n'est pas executé dans ~/dev/local_scripts on cherchera à l'y placer (avec accord de l'utilisateur) sinon on est bien executé depuis le bon endroit
        if [ $LOCAL_SCRIPTS_EXISTS ]; then # Si ~/dev/local_scripts existe, on attend une réponse de l'utilisateur, le script install n'est pas executé depuis ~/dev/local_scripts mais ~/dev/local_scripts existe. Faut-il l'écraser et prendre sa place ?
            if ask_yn "Le répertoire '$PATH_LOCAL_SCRIPTS' existe déjà, mais le script est executé depuis '$script_dir'. écraser '$PATH_LOCAL_SCRIPTS' pour y déplacer le repository de '$script_dir' ?"; then
                echo "Supression de '$PATH_LOCAL_SCRIPTS'"
                sudo rm -rf $PATH_LOCAL_SCRIPTS
                echo "Création du répertoire vide '$PATH_LOCAL_SCRIPTS'"
                mkdir -p "$PATH_LOCAL_SCRIPTS"
                echo "Déplacement dans le répertoire '$PATH_LOCAL_SCRIPTS'"
                mv "$script_dir" "$PATH_LOCAL_SCRIPTS"
                LOCAL_SCRIPTS_EXISTS=true
            fi
        else # Si ~/dev/local_scripts n'existe pas on le créé et on bouge le repo dedans
            echo "Création du répertoire '$PATH_LOCAL_SCRIPTS'"
            mkdir -p "$PATH_LOCAL_SCRIPTS"
            echo "Déplacement dans le répertoire '$PATH_LOCAL_SCRIPTS'"
            mv "$script_dir" "$PATH_LOCAL_SCRIPTS"
            LOCAL_SCRIPTS_EXISTS=true
        fi
    fi
fi
# Quelles options installer ?
GAMING_INSTALL=false
if ask_yn "Installer les repos liés aux périfériques gaming ?"; then
    GAMING_INSTALL=true
fi
WEB_DEV_INSTALL=false
if ask_yn "Installer les langages de programmation (PHP) ?"; then
    WEB_DEV_INSTALL=true
fi
DOCKER_INSTALL=false
if ask_yn "Installer Docker ?"; then
    DOCKER_INSTALL=true
fi

# -- ÉTAPE 3
# Installation des dépendance de local_scripts
echo "Mise a jour des dépendances"
sudo apt update
sudo apt install -y x11-xserver-utils pulseaudio pulseaudio-utils xdotool wmctrl jq curl wget libnotify sshfs sshpass make


# -- ÉTAPE 4
# Ajout des commandes et alias
lout "Lancement du script de commandes et aliases"
chmod +x "$script_dir/updateCommand.sh"
bash "$script_dir/updateCommand.sh"
# Ajout de yt-dlp
dlp_error=false
if [ ! -f "$script_dir/yt-dlp.py" ] && [ ! -f "$script_dir/yt-dlp" ], then
    lout "yt-dlp non trouvé, installation..."
    wget -P "$script_dir" "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp" || dlp_error=true
    if $dlp_error; then
        wout "Impossible de télécharger yt-dlp. Veillez télécharger le binaire sous le nom \"yt-dlp\" et l'ajouter au PATH avec les droits d'execution."
    else
        lout "Ajout des droits d'execution à $script_dir/yt-dlp"
        chmod +x "$script_dir/yt-dlp"
        if [ -n "$LOCAL_BIN"]; then
            lout "Déplacement du yt-dlp vers $LOCAL_BIN"
            mkdir -p "$LOCAL_BIN"
            mv "$script_dir/yt-dlp" "$LOCAL_BIN"
        fi
    fi
fi

# -- ÉTAPE 5
# Web devs tools

#PHP
if $WEB_DEV_INSTALL; then
    echo "INSTALLATION DES LANGAGES DE PROGRAMMATION"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y software-properties-common lsb-release
    sudo add-apt-repository ppa:ondrej/php -y
    sudo apt update
fi
#DOCKER
if $DOCKER_INSTALL; then
    echo "INSTALLATION DE DOCKER"
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker $USER
fi

# Repos gaming
if $GAMING_INSTALL; then
    # XONE (controlleur xbox one)
    if $ARCHITECTURE_PERSO; then
        cd "$PATH_REPOS_EXTERNES"
    fi
    sudo apt install dkms cabextract
    git clone git@github.com:dlundqvist/xone.git && cd xone && sudo ./install.sh
    sudo xone-get-firmware.sh

    # CKB-NEXT (souris corsair)
    if $ARCHITECTURE_PERSO; then
        cd "$PATH_REPOS_EXTERNES"
    fi
    sudo apt install build-essential cmake libudev-dev qtbase5-dev zlib1g-dev libpulse-dev libquazip5-dev libqt5x11extras5-dev libxcb-screensaver0-dev libxcb-ewmh-dev libxcb1-dev qttools5-dev git libdbusmenu-qt5-dev
    git clone https://github.com/ckb-next/ckb-next.git && cd ckb-next
    sudo bash quickinstall

    # HEROIC GAME LAUNCHER
    cd "$HOME"
    echo "Installation d'Heroic Game Launcher"
    # Récupération de la dernière version via l'API GitHub
    LATEST_RELEASE=$(curl -s "https://api.github.com/repos/Heroic-Games-Launcher/HeroicGamesLauncher/releases/latest")
    VERSION=$(echo "$LATEST_RELEASE" | jq -r '.tag_name')
    DEB_URL=$(echo "$LATEST_RELEASE" | jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url')
    # Téléchargement du .deb
    echo "Téléchargement de la version $VERSION..."
    curl -LO "$DEB_URL"
    # Installation du paquet
    DEB_FILE=$(basename "$DEB_URL")
    sudo apt install -y "./$DEB_FILE"
    # Nettoyage
    rm -f "$DEB_FILE"
fi

# -- ÉTAPE 6
# Installation du reste utile
echo "Mise a jour des dépendances"
sudo apt install -y btop nginx steam snapd gimp vlc ufw tree python3 libreoffice kate ffmpeg ffprobe filezilla composer usb-creator-gtk flatpak kde-config-flatpak
sudo snap install --classic --no-prompt code

# -- ÉTAPE 7
# téléchargements
