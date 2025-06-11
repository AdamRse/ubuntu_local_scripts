#!/bin/bash
#
# Dépendance : .env

# INIT CONST
screenlist_filename="screenList"

# SET CONST
pathfile_screenList="$CONFIG_DIR/$screenlist_filename"

# FUNCTIONS
nout() { # notification output (continue le script)
    if [ -z "$1" ]; then
        out="nout() : Erreur d'utilisation, la fonction attends une string."
        echo "$out"
        notify-send -u normal "$out"
    else
        echo "$1"
        notify-send -u normal "$1"
    fi
}
fnout() { # fail notification output (interrompt le script : exit 1)
    if [ -z "$1" ]; then
        out="fnout() : Aucun message d'erreur passé."
        echo "$out" >$2
        notify-send -u critical "$out"
    else
        echo "$1" >$2
        notify-send -u critical "$1"
    fi
    exit 1
}
wnout() { # warning notification output (continue le script)
    if [ -z "$1" ]; then
        out="wnout() : Aucun message de warning passé."
        echo "$out" >$2
        notify-send -u critical "$out"
    else
        echo "$1" >$2
        notify-send -u critical "$1"
    fi
}
save_config_file() {
    xrandr --listmonitors > "$pathfile_screenList" || fnout 
}
read_config_file(){
    return $(cat "$pathfile_screenList")
}

# CHECKS
# Accès répertoire de config
if  [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR" || fnout "Impossible de créer le répertoire de configuration dans $CONFIG_DIR. Vérifiez les droits d'écriture ou changez la clé \$CONFIG_DIR dans le .env"
else
    if [ ! -w "$CONFIG_DIR" ]; then
        fnout "Droits d'écriture requis pour $CONFIG_DIR. Vérifiez les droits d'écriture ou changez la clé \$CONFIG_DIR dans le .env"
    fi
fi
# Accès fichiers de config
if [ ! -f "$pathfile_screenList" ] || [ ! -w "$pathfile_screenList" ] || [ ! -r "$pathfile_screenList" ]; then
    fnout "Le fichier '$pathfile_screenList' n'est pas accessible en écriture"
fi