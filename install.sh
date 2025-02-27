#!/bin/bash

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
    echo "Erreur, l'utilisateur doit avoir une authentification github vuia SSH."
    exit 1
fi
# Installation de l'architecture perso
ARCHITECTURE_PERSO=true
while true; do
    read -n 1 -p "Appliquer l'architecture ~/dev (conseillé) ? Le dossier ~dev contiendra les repos github perso, externes (services), et local_scripts (ce repo), pour minimiser le nombre de dossiers cachés dans ~/. et regrouper tous les repo gitub. (o/n) " response_architecture
    # Vérification de la réponse
    if [[ $response_architecture == "o" ]]; then
        break
    elif [[ $response_architecture == "n" ]]; then
        ARCHITECTURE_PERSO=false
        break
    else
        echo "Réponse invalide. Veuillez entrer 'o' (Oui) ou 'n' (Non)."
    fi
done


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
if [ $ARCHITECTURE_PERSO ]; then
    # Gestion de ~/dev/repos_externes
    if ! [ $REPOS_EXTERNES_EXISTS ]; then
        mkdir -p "$PATH_REPOS_EXTERNES"
        REPOS_EXTERNES_EXISTS=true
    fi
        
    # Gestion de ~/dev/local_scripts
    if ! [ $PWD == "$PATH_LOCAL_SCRIPTS"]; then # Si le programme n'est pas executé dans ~/dev/local_scripts on cherchera à l'y placer (avec accord de l'utilisateur) sinon on est bien executé depuis le bon endroit
        if [ $LOCAL_SCRIPTS_EXISTS ]; then # Si ~/dev/local_scripts existe, on attend une réponse de l'utilisateur, le script install n'est pas executé depuis ~/dev/local_scripts mais ~/dev/local_scripts existe. Faut-il l'écraser et prendre sa place ?
            while true; do
                read -n 1 -p "Le répertoire '$PATH_LOCAL_SCRIPTS' existe déjà, mais le script est executé depuis '$PWD'. écraser '$PATH_LOCAL_SCRIPTS' pour y déplacer le repository de '$PWD' ? (o/n) " response_ecraser
                # Vérification de la réponse
                if [[ $response_ecraser == "o" ]]; then
                    echo "Supression de '$PATH_LOCAL_SCRIPTS'"
                    sudo rm -rf $PATH_LOCAL_SCRIPTS
                    echo "Création du répertoire vide '$PATH_LOCAL_SCRIPTS'"
                    mkdir -p "$PATH_LOCAL_SCRIPTS"
                    echo "Déplacement dans le répertoire '$PATH_LOCAL_SCRIPTS'"
                    mv "$PWD" "$PATH_LOCAL_SCRIPTS"
                    LOCAL_SCRIPTS_EXISTS=true
                    break
                elif [[ $response_ecraser == "n" ]]; then
                    break
                else
                    echo "Réponse invalide. Veuillez entrer 'o' (Oui) ou 'n' (Non)."
                fi
            done
        else # Si ~/dev/local_scripts n'existe pas on le créé et on bouge le repo dedans
            echo "Création du répertoire '$PATH_LOCAL_SCRIPTS'"
            mkdir -p "$PATH_LOCAL_SCRIPTS"
            echo "Déplacement dans le répertoire '$PATH_LOCAL_SCRIPTS'"
            mv "$PWD" "$PATH_LOCAL_SCRIPTS"
            LOCAL_SCRIPTS_EXISTS=true
        fi
    fi
fi


# -- ÉTAPE 3 [EN COURS]
# Installation des dépendance
echo "Mise a jour des dépendances"
sudo apt update
sudo apt install -y xrandr pactl xdotool wmctrl jq curl
sudo apt install -y php php-dom php-xml php-mysql
sudo apt install -y 


# -- ÉTAPE 4
# Ajout des alias
cat >> $HOME_FOLDER/.bashrc << 'EOF'
# Alias local_scripts
alias postman="nohup ~/dev/repos_externes/postman/postman-agent --no-sandbox >/dev/null 2>&1 &"
alias a2new="sudo bash ~/dev/local_scripts/newApache2Project.sh"
alias yt-dlp="python3 ~/dev/local_scripts/yt-dlp.py -P '~/Téléchargements/yt-dlp'"
alias dns-update="bash ~/dev/local_scripts/hostsUpdater.sh"
alias llm-context-file="bash ~/dev/local_scripts/llmContext.sh"
EOF