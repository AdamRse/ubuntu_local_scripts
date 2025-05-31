#!/bin/bash

source ./utils/fct.sh

# -- ÉTAPE 1
#Pour trouver le dossier home de l'utilisateur, même si le script est lancé en sudo
if [ "$(id -u)" -eq 0 ]; then #On est en sudo
    HOME_FOLDER="/home/$(whoami)"
    if ! [ -d "$HOME_FOLDER" ]; then # Le dossier perso n'a pas été trouvé
        echo -e "Erreur, impossible de trouver le dossier /home/<user>, le nom d'utilisateur ne correspond à aucun répertoire de /home.\nRelancez le programme sans droits d'administrateur (sans sudo)."
        exit 1
    fi
else
    HOME_FOLDER=$HOME
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
PATH_LOCAL_SCRIPTS="$HOME_FOLDER/dev/local_scripts"
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
if [ "$ARCHITECTURE_PERSO" = true ]; then
    # Gestion de ~/dev/repos_externes
    if ! [ "$REPOS_EXTERNES_EXISTS" = false ]; then
        mkdir -p "$PATH_REPOS_EXTERNES"
        REPOS_EXTERNES_EXISTS=true
    fi
        
    # Gestion de ~/dev/local_scripts
    if ! [ $PWD == "$PATH_LOCAL_SCRIPTS" ]; then # Si le programme n'est pas executé dans ~/dev/local_scripts on cherchera à l'y placer (avec accord de l'utilisateur) sinon on est bien executé depuis le bon endroit
        if [ $LOCAL_SCRIPTS_EXISTS ]; then # Si ~/dev/local_scripts existe, on attend une réponse de l'utilisateur, le script install n'est pas executé depuis ~/dev/local_scripts mais ~/dev/local_scripts existe. Faut-il l'écraser et prendre sa place ?
            if ask_yn "Le répertoire '$PATH_LOCAL_SCRIPTS' existe déjà, mais le script est executé depuis '$PWD'. écraser '$PATH_LOCAL_SCRIPTS' pour y déplacer le repository de '$PWD' ?"; then
                echo "Supression de '$PATH_LOCAL_SCRIPTS'"
                sudo rm -rf $PATH_LOCAL_SCRIPTS
                echo "Création du répertoire vide '$PATH_LOCAL_SCRIPTS'"
                mkdir -p "$PATH_LOCAL_SCRIPTS"
                echo "Déplacement dans le répertoire '$PATH_LOCAL_SCRIPTS'"
                mv "$PWD" "$PATH_LOCAL_SCRIPTS"
                LOCAL_SCRIPTS_EXISTS=true
            fi
        else # Si ~/dev/local_scripts n'existe pas on le créé et on bouge le repo dedans
            echo "Création du répertoire '$PATH_LOCAL_SCRIPTS'"
            mkdir -p "$PATH_LOCAL_SCRIPTS"
            echo "Déplacement dans le répertoire '$PATH_LOCAL_SCRIPTS'"
            mv "$PWD" "$PATH_LOCAL_SCRIPTS"
            LOCAL_SCRIPTS_EXISTS=true
        fi
    fi
fi
# installer les repos périfériques gaming ?
GAMING_INSTALL=false
if ask_yn "Installer les repos liés aux périfériques gaming ?"; then
    GAMING_INSTALL=true
fi

# -- ÉTAPE 3
# Installation des dépendance
echo "Mise a jour des dépendances"
sudo apt update
sudo apt install -y xrandr pactl xdotool wmctrl jq curl wget

# -- ÉTAPE 4
# Ajout des alias
cat >> $HOME_FOLDER/.config/aliases << 'EOF'
# Alias local_scripts
alias postman="nohup ~/dev/repos_externes/postman/postman-agent --no-sandbox >/dev/null 2>&1 &"
alias a2new="sudo bash ~/dev/local_scripts/newApache2Project.sh"
alias yt-dlp="python3 ~/dev/local_scripts/yt-dlp.py -P '~/Téléchargements/yt-dlp'"
alias dns-update="bash ~/dev/local_scripts/hostsUpdater.sh"
alias llm-context-file="bash ~/dev/local_scripts/llmContext.sh"
EOF
echo -e "\n# Source local aliases\nsource \$HOME/.config/aliases" >> ~/.bashrc

# -- ÉTAPE 5
# Repos

#PHP
sudo apt install -y ca-certificates apt-transport-https software-properties-common curl lsb-release
sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list
sudo apt update -y

# Repos gaming
if $GAMING_INSTALL; then
    # XONE (controlleur xbox one)
    if $ARCHITECTURE_PERSO; then
        cd "$PATH_REPOS_EXTERNES"
    fi
    git clone https://github.com/medusalix/xone && cd xone && sudo ./install.sh
    sudo xone-get-firmware.sh

    # CKB-NEXT (souris corsair)
    if $ARCHITECTURE_PERSO; then
        cd "$PATH_REPOS_EXTERNES"
    fi
    sudo apt install build-essential cmake libudev-dev qtbase5-dev zlib1g-dev libpulse-dev libquazip5-dev libqt5x11extras5-dev libxcb-screensaver0-dev libxcb-ewmh-dev libxcb1-dev qttools5-dev git libdbusmenu-qt5-dev
    git clone https://github.com/ckb-next/ckb-next.git && cd ckb-next
    sudo bash quickinstall
fi

# -- ÉTAPE 6
# Installation du reste utile
echo "Mise a jour des dépendances"
sudo apt install -y btop nginx steam snapd gimp simba vlc ufw tree python3 libreoffice kate ffmpeg filezilla composer usb-creator-gtk flatpak kde-config-flatpak
sudo snap install --classic --no-prompt code

# -- ÉTAPE 7
# téléchargements

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
