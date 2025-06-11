#!/bin/bash
#
# Dépendance : .env

# INIT CONST
screenlist_filename="screenList"

# SET CONST
pathfile_screenList="$CONFIG_DIR/$screenlist_filename"

# CHECK
if  [ ! -d "$CONFIG_DIR" ]; then
    if ! mkdir -p "$CONFIG_DIR"; then
        echo "Impossible de créer le répertoire de configuration dans $CONFIG_DIR. Vérifiez les droits d'écriture ou changez la clé \$CONFIG_DIR dans le .env"
        exit 1
    fi
else
    if [ ! -w "$CONFIG_DIR" ]; then
        echo "Droits d'écriture requis pour $CONFIG_DIR. Vérifiez les droits d'écriture ou changez la clé \$CONFIG_DIR dans le .env"
        exit 1
    fi
fi

# FUNCTIONS
save_config_file() {
    xrandr --listmonitors > "$pathfile_screenList"
}
read_config_file(){
    return $(cat "$pathfile_screenList")
}
nout() { # notification output
    if [ -z "$1" ]; then
        out="nout() : Erreur d'utilisation, la fonction attends une string."
        echo "$out"
        notify-send -u normal "$out"
    else
        echo "$1"
        notify-send -u normal "$1"
    fi
}
fnout() { # fail notification output
    if [ -z "$1" ]; then
        out="nout() : Aucun message d'erreur passé."
        echo "$out" >$2
        notify-send -u critical "$out"
    else
        echo "$1" >$2
        notify-send -u critical "$1"
    fi
    exit 1
}