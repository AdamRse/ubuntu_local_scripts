#!/bin/bash

# Installation de l'architecture perso
ARCHITECTURE_PERSO=true
while true; do
    read -n 1 -p "Appliquer l'architecture personnelle ? (o/n) " response
    # Vérification de la réponse
    if [[ $response == "o" ]]; then
        break
    elif [[ $response == "n" ]]; then
        ARCHITECTURE_PERSO=false
        break
    else
        echo "Réponse invalide. Veuillez entrer 'o' (Oui) ou 'n' (Non)."
    fi
done

if [ -d "chemin/vers/le/dossier" ]; then
  echo "Le dossier existe"
else
  echo "Le dossier n'existe pas"
fi

#Pour trouver le dossier home de l'utilisateur, même si le script est lancé en sudo
if [ "$(id -u)" -eq 0 ]; then #On est en sudo
    HOME_FOLDER="/home/$(whoami)"
    if ! [ -d "$HOME_FOLDER" ]; then # Le dossier perso n'a pas été trouvé
        echo "Erreur, impossible de trouver le dossier /home/<user>, le nom d'utilisateur ne correspond à aucun répertoire de /home.\nRelancez le programme sans droits d'administrateur (sans sudo)."
        exit 1
    fi
else
    HOME_FOLDER="~"
fi

#On créé l'architecture perso
if ! [ -d "$HOME_FOLDER/dev/local_scripts" ]; then
    #mkdir -p "$HOME_FOLDER/dev/local_scripts"
fi

#Installation des dépendance
echo "Mise a jour des dépendances"
#sudo apt update
#sudo apt install xrandr pactl xdotool wmctrl jq curl