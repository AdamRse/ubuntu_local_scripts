#!/bin/bash

CONFIG_DIR="$HOME/.config/local_scripts" # Répertoire de configuration du script
CONFIG_DESKTOP="$CONFIG_DIR/screen_desk.conf" # Fichier indiquant la configuration du mode desktop (travail, ou bureau)
CONFIG_PREVIOUS="$CONFIG_DIR/screen_prev.conf" # Fichier indiquant l'état de configuration précédent des écrans, avant un changement lié au script.
POS_ECRAN_TV=3 # Seul écran à garder allumé en mode TV. On compte les écrans à partir de 1 et de la gauche. Ecran 1 | Ecran 2 | Ecran 3 | Ecran 4 ...

# Vérifier si le dossier existe avec les bons droits
check_config_dir() {
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR" 2>/dev/null
        if [ ! -d "$CONFIG_DIR" ]; then
            notify-send -u critical "$0 : Erreur Configuration Écrans" "Impossible de créer le dossier $CONFIG_DIR. Veuillez le créer manuellement avec : mkdir -p $CONFIG_DIR"
            exit 1
        fi
    fi

    if [ ! -w "$CONFIG_DIR" ]; then
        chmod 755 "$CONFIG_DIR" 2>/dev/null
        if [ ! -w "$CONFIG_DIR" ]; then
            notify-send -u critical "$0 : Erreur Configuration Écrans" "Impossible de modifier les droits sur $CONFIG_DIR. Veuillez exécuter : chmod 755 $CONFIG_DIR"
            exit 1
        fi
    fi

    if [ ! -f "$CONFIG_DESKTOP" ]; then
        save_desktop_config
        if [ ! -f "$CONFIG_DESKTOP" ]; then
            notify-send -u critical "$0 : Erreur Configuration Écrans" "La création d'un fichier de configuration a échouée ($CONFIG_DESKTOP)"
            exit 1
        fi
    fi
}

# Fonction pour sauvegarder la configuration actuelle des écrans
save_previous_config() {
    xrandr --listmonitors > "$CONFIG_PREVIOUS"
}
save_desktop_config() {
    xrandr --listmonitors > "$CONFIG_DESKTOP"
}

# Fonction pour obtenir la résolution d'un moniteur
get_monitor_resolution() {
    local monitor=$1
    grep -w "$monitor" "$CONFIG_DESKTOP" | grep -o '[0-9]\+x[0-9]\+' | head -1
}

# Fonction pour extraire la position X d'un moniteur
get_x_position() {
    local monitor_line="$1"
    # Extrait la partie contenant les coordonnées (ex: 1920x1080/334+1920+0)
    # et récupère le premier nombre après le '+'
    echo "$monitor_line" | grep -o '[0-9]\+/[0-9]\+x[0-9]\+/[0-9]\++[0-9]\++[0-9]\+' | cut -d'+' -f2
}

# Fonction pour obtenir le nom du moniteur
get_monitor_name() {
    local monitor_line="$1"
    echo "$monitor_line" | awk '{print $NF}'
}

# Fonction pour trier les moniteurs par position
sort_monitors_by_position() {
    # Lit la sortie de xrandr --listmonitors ligne par ligne
    # Ignore la première ligne qui contient "Monitors: X"
    xrandr --listmonitors | grep -v "Monitors:" | while read -r line; do
        # Extrait la position X et le nom du moniteur
        x_pos=$(get_x_position "$line")
        name=$(get_monitor_name "$line")
        # Affiche position et nom séparés par un espace
        echo "$x_pos $name"
    done | sort -n | cut -d' ' -f2  # Trie par position X et ne garde que les noms
}

# Fonction pour le mode gaming canapé
mode_gaming_canap() {
    # Sauvegarder la configuration actuelle
    save_previous_config
    
    # Obtenir la liste des moniteurs triés par position
    readarray -t SORTED_MONITORS < <(sort_monitors_by_position)
    
    # Vérifier que nous avons assez de moniteurs
    if [ ${#SORTED_MONITORS[@]} -lt $POS_ECRAN_TV ]; then
        notify-send -u critical "$0 : Erreur Configuration Écrans" "Position TV ($POS_ECRAN_TV) supérieure au nombre d'écrans (${#SORTED_MONITORS[@]})"
        exit 1
    fi
    
    # Index pour le moniteur TV (conversion position 1-based vers 0-based)
    TV_INDEX=$((POS_ECRAN_TV - 1))
    
    # Éteindre tous les écrans sauf celui de la TV
    for i in "${!SORTED_MONITORS[@]}"; do
        if [ $i -eq $TV_INDEX ]; then
            # Activer l'écran TV en tant qu'écran principal
            xrandr --output "${SORTED_MONITORS[$i]}" --primary --auto
        else
            # Éteindre les autres écrans
            xrandr --output "${SORTED_MONITORS[$i]}" --off
        fi
    done

    # Configuration audio
    AUDIO_SINK_TV=$(pactl list short sinks | grep hdmi | awk '{print $1}')

    timeout=60
    elapsed=0
    
    while true ; do
        AUDIO_SINK_TV=$(pactl list short sinks | grep hdmi | awk '{print $1}')
        
        if [ -z "$AUDIO_SINK_TV" ]; then
            notify-send "Configuration Audio" "Recherche de la sortie HDMI..."
            sleep 1
            ((elapsed+=1))
        else
            pactl set-default-sink $AUDIO_SINK_TV
            pactl set-sink-volume $AUDIO_SINK_TV 100%
            notify-send "Configuration Audio" "Sortie HDMI configurée"
            break
        fi

        if [ $elapsed -ge $timeout ]; then
            break
        fi
    done

    if [ $elapsed -ge $timeout ]; then
        notify-send -u critical "Erreur Audio" "Impossible de trouver la sortie HDMI"
    fi

    #Enlève l'arrêt de l'écran inactif (parfois à cause de cinématiques l'écran s'éteinds)
    gsettings set org.cinnamon.settings-daemon.plugins.power sleep-display-ac 0

    # Lancer Steam en mode Big Picture
    steam steam://open/bigpicture

    notify-send "Configuration Écrans" "Mode gaming TV activé"
}

# Fonction pour le mode bureau
mode_bureau() {
    save_previous_config

    xrandr --output "DP-1" --mode "1920x1080" --auto --left-of "HDMI-0"
    xrandr --output "HDMI-0" --primary --mode "2560x1080" --auto --right-of "DP-1"
    xrandr --output "DP-5" --mode "1920x1080" --auto --right-of "HDMI-0"
    
    # # Configurer les écrans selon la disposition sauvegardée
    # xrandr --output $MONITOR_LEFT --mode $left_res --auto --left-of $MONITOR_MIDDLE
    # xrandr --output $MONITOR_MIDDLE --primary --mode $middle_res --auto --right-of $MONITOR_LEFT
    # xrandr --output $MONITOR_RIGHT --mode $right_res --auto --right-of $MONITOR_MIDDLE

    # IA -----------------------------

    # # Lire le fichier de configuration desktop
    # if [ ! -f "$CONFIG_DESKTOP" ]; then
    #     notify-send -u critical "$0 : Erreur Configuration Écrans" "Fichier de configuration desktop introuvable ($CONFIG_DESKTOP)"
    #     exit 1
    # fi

    # # Variables pour construire la commande xrandr
    # PRIMARY_MONITOR=""
    # XRANDR_CMD="xrandr"
    # PREV_MONITOR=""
    # PREV_POS=""

    # # Traiter chaque ligne de la configuration desktop (en ignorant la première ligne "Monitors: X")
    # grep -v "Monitors:" "$CONFIG_DESKTOP" | while read -r line; do
    #     # Extraire le nom du moniteur
    #     monitor=$(echo "$line" | awk '{print $NF}')
        
    #     # Vérifier si c'est le moniteur principal (contient *)
    #     if echo "$line" | grep -q '\*'; then
    #         PRIMARY_MONITOR=$monitor
    #     fi
        
    #     # Extraire la résolution
    #     resolution=$(get_monitor_resolution "$monitor")
        
    #     # Extraire la position X
    #     x_pos=$(get_x_position "$line")
        
    #     # Construire la commande xrandr
    #     if [ -z "$PREV_MONITOR" ]; then
    #         # Premier moniteur
    #         XRANDR_CMD+=" --output $monitor --mode $resolution --pos ${x_pos}x0"
    #         if [ -n "$PRIMARY_MONITOR" ] && [ "$monitor" = "$PRIMARY_MONITOR" ]; then
    #             XRANDR_CMD+=" --primary"
    #         fi
    #     else
    #         # Moniteurs suivants
    #         XRANDR_CMD+=" --output $monitor --mode $resolution --pos ${x_pos}x0"
    #         if [ -n "$PRIMARY_MONITOR" ] && [ "$monitor" = "$PRIMARY_MONITOR" ]; then
    #             XRANDR_CMD+=" --primary"
    #         fi
    #     fi
        
    #     PREV_MONITOR=$monitor
    #     PREV_POS=$x_pos
    # done

    # # Activer tous les moniteurs et éteindre ceux qui ne sont pas dans la config
    # ALL_MONITORS=$(xrandr --query | grep " connected" | awk '{print $1}')
    # for mon in $ALL_MONITORS; do
    #     if ! grep -q "$mon" "$CONFIG_DESKTOP"; then
    #         XRANDR_CMD+=" --output $mon --off"
    #     fi
    # done

    # # Exécuter la commande xrandr
    # eval "$XRANDR_CMD"

    # FIN IA -----------------------------
    
    # Configuration audio
    AUDIO_SINK_DESK=$(pactl list short sinks | grep analog | awk '{print $1}')
    pactl set-default-sink $AUDIO_SINK_DESK

    # Fermer Steam Big Picture si nécessaire
    if pgrep -x "steam" > /dev/null; then
        steam steam://close/bigpicture
    fi

    # On remet l'arrêt des écrans innactif à 5 min
    gsettings set org.cinnamon.settings-daemon.plugins.power sleep-display-ac 300

    notify-send "Configuration Écrans" "Mode bureau activé"
}

mode_gaming_pc() {
    save_previous_config

    # A coder, éteindre les écrans de gauche et de droite, harder le principal, au milieu
}

# Vérifier le dossier de configuration au démarrage
check_config_dir

# Programme principal
if [[ "$1" == "desk" ]]; then
    mode_bureau
elif [[ "$1" == "tv" ]]; then
    mode_gaming_canap
elif [[ "$1" == "gaming_desk" ]]; then
    mode_gaming_pc
elif [[ "$1" == "save_monitors" ]]; then
    save_desktop_config
elif [[ "$1" == "test" ]]; then
    echo -e "mode test\n--------------------"
    get_monitor_resolution HDMI-0
else # togle
    IS_LEFT_ON=$(xrandr --listmonitors | grep -w "$MONITOR_LEFT")
    IS_MIDDLE_ON=$(xrandr --listmonitors | grep -w "$MONITOR_MIDDLE")
    
    if [ -n "$IS_LEFT_ON" ] || [ -n "$IS_MIDDLE_ON" ]; then
        mode_gaming_canap
    else
        mode_bureau
    fi
fi