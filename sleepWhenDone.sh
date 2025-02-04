#!/bin/bash

# Nom du fichier à vérifier
nomFichier="Silo.S02E06.MULTi.HDR.DV.2160p.WEB.H265-FW-Wawacity.tools.mkv"

# Récupérer la taille du fichier
taille=$(ls -l "$nomFichier" | awk '{print $5}')

# Valeur de comparaison (par exemple 1000 octets)
valeurComparaison=7800000000

if [ ! -f "$nomFichier" ]; then
    echo "Erreur : Le fichier $nomFichier n'existe pas"
    exit 1
fi

# Boucle infinie jusqu'à ce que la taille du fichier dépasse la valeur de comparaison
while true; do
    if [ ! -f "$nomFichier" ]; then
        echo "Erreur : Le fichier n'existe plus"
        systemctl suspend
    fi
    # Récupérer la taille du fichier
    taille=$(ls -l "$nomFichier" | awk '{print $5}')

    # Vérifier si la taille du fichier est supérieure à la valeur de comparaison
    if [ "$taille" -gt "$valeurComparaison" ]; then
        break  # Sortir de la boucle
    fi

    echo "Le fichier n'a pas la taille requise, bouclage..."

    # Attendre un certain temps avant de réessayer (par exemple, 1 seconde)
    sleep 100
done
sleep 120
systemctl suspend