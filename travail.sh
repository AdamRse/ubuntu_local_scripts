#!/bin/bash

# Définition des variables
PROJECT_DIR="/home/adam/dev/vestiaire-back"
FIREFOX_TABS=(
    "https://www.youtube.com/watch?v=5yx6BWlEVcY"
    "https://app.slack.com/client/T05AXRNBC7L/C05BMHDKW56"
    "https://trello.com/b/pp2FJVV5/vestiaire-officiel-ecommerce"
    "https://github.com/AdamRse/vestiaire-officiel-back"
    "https://claude.ai/new"
)

# Fonction pour attendre qu'une fenêtre soit créée
wait_for_window() {
    while [ -z "$(xdotool search --name "$1")" ]; do
        sleep 1
    done
}

# Lancement de Firefox sur l'écran de droite (DP-3)
firefox "${FIREFOX_TABS[@]}" &
wait_for_window "Mozilla Firefox"
firefox_window=$(xdotool search --name "Mozilla Firefox" | tail -n 1)
xdotool windowmove $firefox_window 4480 0
xdotool windowsize $firefox_window 100% 100%

# Lancement de VS Code sur l'écran du milieu (HDMI-0)
code "$PROJECT_DIR" &
wait_for_window "Visual Studio Code"
#sleep 2  # Attendre un peu plus pour s'assurer que VS Code est complètement chargé
vscode_window=$(xdotool search --name "Visual Studio Code" | tail -n 1)
xdotool windowmove $vscode_window 1920 0
xdotool windowsize $vscode_window 2560 1080  # Ajuster à la résolution exacte de l'écran HDMI-0
xdotool windowmove $vscode_window 1920 0  # Déplacer à nouveau pour s'assurer qu'il reste sur le bon écran

# Lancement du premier terminal (projet Laravel)
gnome-terminal --working-directory="$PROJECT_DIR" -- bash -c "php artisan serve; exec bash" &
#sleep 2
#wait_for_window "adam@adam-Z690-UD-AX:"
wait_for_window "Terminal"
terminal1_window=$(xdotool search --name "Terminal" | tail -n 1)
xdotool windowsize $terminal1_window 990 400
xdotool windowmove $terminal1_window 960 770
firefox "http://127.0.0.1:8000"

# Lancement du deuxième terminal (répertoire du projet)
gnome-terminal --working-directory="$PROJECT_DIR" &
wait_for_window "adam@adam-Z690-UD-AX:"
#sleep 2
terminal2_window=$(xdotool search --name "adam@adam-Z690-UD-AX:" | tail -n 1)
xdotool windowsize $terminal2_window 990 800
xdotool windowmove $terminal2_window 960 -30

# Lancement de Discord sur la partie gauche de l'écran de gauche (DP-1)
# discord &
# wait_for_window "Discord"
# sleep 2
# discord_window=$(xdotool search --name "Discord" | tail -n 1)
# xdotool windowmove $discord_window 0 0
# xdotool windowsize $discord_window 960 1080

echo "Environnement de travail lancé avec succès !"