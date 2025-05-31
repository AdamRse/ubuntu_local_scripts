#!/bin/bash


cd "$HOME"
# Mise à jour des paquets
sudo apt update

# Installation des dépendances nécessaires (curl et jq pour parser JSON)
sudo apt install -y curl jq

# Récupération de la dernière version via l'API GitHub
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/Heroic-Games-Launcher/HeroicGamesLauncher/releases/latest")
VERSION=$(echo "$LATEST_RELEASE" | jq -r '.tag_name')
DEB_URL=$(echo "$LATEST_RELEASE" | jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url')

# Téléchargement du .deb
echo "Téléchargement de la version $VERSION..."
curl -LO "$DEB_URL"

# Installation du paquet
DEB_FILE=$(basename "$DEB_URL")
echo "sudo apt install -y './$DEB_FILE'"

# Nettoyage
# rm -f "$DEB_FILE"

echo "Heroic Games Launcher $VERSION a été installé avec succès !"