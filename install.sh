#!/bin/bash

# ############## OPTIONS
restart_after=false

# ############## VARS, Utilisées dans le script
home_folder=""
user_name=""
user_group=""
profile_file=""
user_path=""
is_github_auth=false
is_dev_architecture=false
is_gaming=false
is_set_github=false
is_install_docker=false
is_install_dev=false
is_install_code=false
is_yt_dlp=false

# ############## CONST
RED="\e[31m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

# ############## FUNTIONS
ask_yn () {
    if [ -z "$1" ]; then
        echo "fonction ask_yn() : Aucun paramètre passé" >&2
        exit 1
    fi

    while true; do
        read -n 1 -p "$1 (o/n)" response
        # Vérification de la réponse
        if [[ $response == "o" || $response == "O" ]]; then
            echo ""
            return 0
        elif [[ $response == "n" || $response == "N" ]]; then
            echo ""
            return 1
        else
            echo ""
            echo -e "'$response' : Réponse invalide. Veuillez entrer 'o' (Oui) ou 'n' (Non).\n"
        fi
    done
}

lout() {
    if [ -z "$1" ]; then
        echo -e "${RED}fonction lout() : Aucun message passé.${ENDCOLOR}" >&2
        return 1
    fi

    echo -e "$1"
    return 0
}

fout() {
    if [ -z "$1" ]; then
        echo -e "${RED}fonction fout() : Aucun message passé.${ENDCOLOR}" >&2
        exit 1
    fi

    echo -e "${RED}Erreur : $1${ENDCOLOR}" >&2
    exit 1
}

wout() {
    if [ -z "$1" ]; then
        echo -e "${RED}fonction wout() : Aucun message passé.${ENDCOLOR}" >&2
        exit 1
    fi

    echo -e "${YELLOW}Attention : $1${ENDCOLOR}" >&2
}

title_section() {
    if [ -z "$1" ]; then
        echo -e "${YELLOW}fonction title_section() : Aucun message passé.${ENDCOLOR}" >&2
    fi
    #level of section title
    local level="${2:-1}"
    local title="$1"
    
    # Styles pour différents niveaux
    case "$level" in
        1)
            echo -e "\n\n################################################\n/ / / / $1 / / / /\n################################################"
            ;;
        2)
            echo -e "\n\n--- --- ---[ $1 ]--- --- ---"
            ;;
        3)
            echo -e "\n\n......| $1 |......"
            ;;
        *)
            echo -e "\n\n################################################\n/ / / / $1 / / / /\n################################################"
            ;;
    esac
}

#set_users_permissions "<target>" "[permission numérique]" "Bool:[is_recursive]"
set_users_permissions() {
    [ -z "$1" ] && fout "fonction set_permissions() : Aucun paramètre 1 passé."
    local path="$1"
    local permission="775"

    if [ -n "$2" ]; then
        permission="$2"
    fi
    if [ -n "$3" ] && $3; then
        sudo chmod -R "${permission}" "$path" && sudo chown -R "${user_name}:${user_group}" "$path"
    else
        sudo chmod "${permission}" "$path" && sudo chown "${user_name}:${user_group}" "$path"
    fi
}

# ############## CHECKS
title_section "CHECK"

user_name="$(logname)"
user_group="$(id -gn ${user_name})"
home_folder="$(getent passwd ${user_name} | cut -d: -f6)"

[ -z "$user_name" ] && fout "Nom d'utilisateur non trouvé"
[ -z "$user_group" ] && fout "Groupe principal de l'utilisateur ${user_name} non trouvé"
[ -z "$home_folder" ] && [ -d "$home_folder" ] && fout "Dossier home de l'utilisateur ${user_name} non trouvé"

lout "Utilisateur : ${user_name}\n\
    Groupe principal : ${user_group}\n\
    Répertoire home : ${home_folder}"

lout "Récupération du fichier profile bash"
if [ -f "${home_folder}/.bash_profile" ]; then
    profile_file="${home_folder}/.bash_profile"
elif [ -f "${home_folder}/.bash_login" ]; then
    profile_file="${home_folder}/.bash_login"
elif [ -f "${home_folder}/.profile" ]; then
    profile_file="${home_folder}/.profile"
else
    wout "Le fichier de profil bash n'existe pas. Les variables du profil seront ajoutées à ${home_folder}/.profile pour exemple."
    echo "" > "${home_folder}/.profile"
    profile_file="${home_folder}/.profile"
fi

lout "\nTest de connexion à github"
ssh -T git@github.com 2>/dev/null
github_status=$?

if [ "$github_status" -eq 1 ]; then
    lout "Authentification GitHub détectée"
    is_github_auth=true
else
    wout "Aucune connexion GitHub via SSH détectée"
    is_github_auth=false
fi

# ############## ASK OPTIONS
title_section "PREPARATION"
lout "Les questions sont posées au début, le reste du script s'executera seul."
sudo echo ""

ask_yn "Installer des features de développement web ?" && is_install_dev=true
if is_install_dev; then
    ask_yn "Installer l'architecture '/home/dev' pour les projets github ?" && is_dev_architecture=true
    ask_yn "Installer Docker ?" && is_install_docker=true
    ask_yn "Installer les packages de code (PHP, Node.js, Nginx...) ?" && is_install_code=true
    if ! $is_github_auth; then
        ask_yn "Si vous souhaitez paramétrer une connexion github, ajoutez vos clés SSH dans '$home_folder/.ssh' avec le nom '$user_name@github', validez ensuite votre réponse ici :\
            \nParamétrer github maintenant ?" && is_set_github=true
    fi
fi
ask_yn "Installer un environement de jeu vidéo ?" && is_gaming=true
ask_yn "Installer yt-dlp pour télécharger sur youtube ?" && is_yt_dlp=true

# ############## PREPARE

sudo apt update && sudo apt upgrade -y

# ############## MAIN

title_section "INSTALLATION"

# DEV WEB #

# Architecture globale
if $is_install_dev; then
    title_section "Architecture globale" 2

    # création du fichier d'alias
    dir_config="${home_folder}/.config"
    file_alias="${dir_config}/alias"
    if [ ! -f "$file_alias" ]; then
        mkdir -p "${dir_config}"
        set_users_permissions "${dir_config}"
        set_users_permissions "${file_alias}"
        echo -e "# Liste des alias de commande bash pour ${home_folder}/.bashrc\n\
        alias ll='ls -la'" > "${file_alias}"
    fi
    echo "source '${file_alias}'" >> "${home_folder}/.bashrc"

    # docker
    if $is_install_docker; then # A TESTER
        lout "-- Installation de docker --"
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo usermod -aG docker $user_name
    fi

    # code tools
    if $is_install_code; then # A TESTER
        echo "-- Installation des langages web --"
        sudo apt install -y software-properties-common lsb-release
        sudo add-apt-repository ppa:ondrej/php -y
        sudo apt update
    fi
fi

# Architecture /home/dev
if $is_dev_architecture; then
    title_section "Architecture /home/dev" 2

    dir_projects="${home_folder}/dev/projets"

    mkdir -p "${dir_projects}"
    set_users_permissions "${home_folder}/dev" 775 true

    echo "export PJ=\"\$HOME/dev/projets\"/" >> "${profile_file}"
    echo "export DEV=\"\$HOME/dev\"/" >> "${profile_file}"
fi

# yt-dlp
if $is_yt_dlp; then # PAS REGARDÉ
    title_section "yt-dlp" 2
    
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