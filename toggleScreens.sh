#!/bin/bash

CONFIG_DIR="$HOME/.config/local_scripts"
CONFIG_FILE="$CONFIG_DIR/.screen_config"

# Vérifier si le dossier existe avec les bons droits
check_config_dir() {
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR" 2>/dev/null
        if [ ! -d "$CONFIG_DIR" ]; then
            notify-send -u critical "ToggleScreen.sh : Erreur Configuration Écrans" "Impossible de créer le dossier $CONFIG_DIR. Veuillez le créer manuellement avec : mkdir -p $CONFIG_DIR"
            exit 1
        fi
    fi

    if [ ! -w "$CONFIG_DIR" ]; then
        chmod 755 "$CONFIG_DIR" 2>/dev/null
        if [ ! -w "$CONFIG_DIR" ]; then
            notify-send -u critical "ToggleScreen.sh : Erreur Configuration Écrans" "Impossible de modifier les droits sur $CONFIG_DIR. Veuillez exécuter : chmod 755 $CONFIG_DIR"
            exit 1
        fi
    fi
}

# Fonction pour sauvegarder la configuration actuelle des écrans
save_monitor_config() {
    check_config_dir
    xrandr --listmonitors > "$CONFIG_FILE"
}

# Fonction pour obtenir la position d'un moniteur
get_monitor_position() {
    local monitor=$1
    grep -w "$monitor" "$CONFIG_FILE" | grep -o '[0-9]\+x[0-9]\++[0-9]\++[0-9]\+' | cut -d'+' -f2,3
}

# Fonction pour obtenir la résolution d'un moniteur
get_monitor_resolution() {
    local monitor=$1
    grep -w "$monitor" "$CONFIG_FILE" | grep -o '[0-9]\+x[0-9]\+' | head -1
}

# Fonction pour identifier les moniteurs
identify_monitors() {
    # Identifier l'écran du milieu (celui en 21:9, ratio ~2.37)
    MONITOR_MIDDLE=$(xrandr --listmonitors | grep -v "Monitors:" | awk '{split($3,res,"x"); if (res[1]/res[2] > 2.3) print $NF}')
    
    # Obtenir la position des autres moniteurs depuis la configuration sauvegardée
    if [ -f "$CONFIG_FILE" ]; then
        # Lire les positions depuis le fichier de configuration
        middle_pos=$(get_monitor_position "$MONITOR_MIDDLE")
        
        # Identifier les moniteurs gauche et droit en fonction de leurs positions relatives
        MONITOR_LEFT=$(xrandr --listmonitors | grep -v "Monitors:" | awk '{print $NF}' | while read monitor; do
            if [ "$monitor" != "$MONITOR_MIDDLE" ]; then
                pos=$(get_monitor_position "$monitor")
                x_pos=$(echo "$pos" | cut -d'+' -f1)
                middle_x=$(echo "$middle_pos" | cut -d'+' -f1)
                if [ "$x_pos" -lt "$middle_x" ]; then
                    echo "$monitor"
                fi
            fi
        done)
        
        MONITOR_RIGHT=$(xrandr --listmonitors | grep -v "Monitors:" | awk '{print $NF}' | while read monitor; do
            if [ "$monitor" != "$MONITOR_MIDDLE" ] && [ "$monitor" != "$MONITOR_LEFT" ]; then
                echo "$monitor"
            fi
        done)
    else
        # Valeurs par défaut si pas de configuration sauvegardée
        MONITOR_LEFT="DP-5"
        MONITOR_RIGHT="DP-1"
    fi

    # Définir les sorties audio
    AUDIO_SINK_TV=$(pactl list short sinks | grep hdmi | awk '{print $1}')
    AUDIO_SINK_DESK=$(pactl list short sinks | grep analog | awk '{print $1}')
}

# Fonction pour le mode gaming canapé
mode_gaming_canap() {
    identify_monitors
    
    # Désactiver les écrans gauche et milieu
    xrandr --output $MONITOR_LEFT --off
    xrandr --output $MONITOR_MIDDLE --off
    
    # Mettre l'écran de droite en écran principal
    xrandr --output $MONITOR_RIGHT --primary --auto

    # Configuration audio
    AUDIO_SINK_TV=$(pactl list short sinks | grep hdmi | awk '{print $1}')

    timeout=60
    elapsed=0
    
    while [ -z "$AUDIO_SINK_TV" ] && [ $elapsed -lt $timeout ]; do
        AUDIO_SINK_TV=$(pactl list short sinks | grep hdmi | awk '{print $1}')
        
        if [ -z "$AUDIO_SINK_TV" ]; then
            notify-send "Configuration Audio" "Recherche de la sortie HDMI..."
            sleep 1
            ((elapsed+=1))
        else
            pactl set-default-sink $AUDIO_SINK_TV
            pactl set-sink-volume $AUDIO_SINK_TV 100%
            notify-send "Configuration Audio" "Sortie HDMI configurée"
        fi
    done

    if [ $elapsed -ge $timeout ]; then
        notify-send -u critical "Erreur Audio" "Impossible de trouver la sortie HDMI"
    fi

    steam steam://open/bigpicture
}

# Fonction pour le mode bureau
mode_bureau() {
    identify_monitors
    
    if [ ! -f "$CONFIG_FILE" ]; then
        notify-send "Configuration Écrans" "Première utilisation - Sauvegarde de la configuration"
        save_monitor_config
    fi
    
    # Récupérer les résolutions depuis la configuration sauvegardée
    left_res=$(get_monitor_resolution "$MONITOR_LEFT")
    middle_res=$(get_monitor_resolution "$MONITOR_MIDDLE")
    right_res=$(get_monitor_resolution "$MONITOR_RIGHT")
    
    # Configurer les écrans selon la disposition sauvegardée
    xrandr --output $MONITOR_LEFT --mode $left_res --auto --left-of $MONITOR_MIDDLE
    xrandr --output $MONITOR_MIDDLE --primary --mode $middle_res --auto --right-of $MONITOR_LEFT
    xrandr --output $MONITOR_RIGHT --mode $right_res --auto --right-of $MONITOR_MIDDLE
    
    # Configuration audio
    AUDIO_SINK_DESK=$(pactl list short sinks | grep analog | awk '{print $1}')
    pactl set-default-sink $AUDIO_SINK_DESK

    # Fermer Steam Big Picture si nécessaire
    if pgrep -x "steam" > /dev/null; then
        steam steam://close/bigpicture
    fi

    notify-send "Configuration Écrans" "Mode bureau activé"
}

# Vérifier le dossier de configuration au démarrage
check_config_dir

# Programme principal
if [[ "$1" == "desk" ]]; then
    mode_bureau
elif [[ "$1" == "tv" ]]; then
    mode_gaming_canap
    save_monitor_config
elif [[ "$1" == "gaming_desk" ]]; then
    mode_gaming_pc
    save_monitor_config
else
    IS_LEFT_ON=$(xrandr --listmonitors | grep -w "$MONITOR_LEFT")
    IS_MIDDLE_ON=$(xrandr --listmonitors | grep -w "$MONITOR_MIDDLE")
    
    if [ -n "$IS_LEFT_ON" ] || [ -n "$IS_MIDDLE_ON" ]; then
        mode_gaming_canap
        save_monitor_config
    else
        mode_bureau
    fi
fi