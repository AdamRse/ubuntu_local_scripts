#!/bin/bash

# Configuration
USER="bakaarion"
PASS="mdp"  # À remplacer ou mieux: utiliser une clé SSH
NAS_ADDRESS="home.adam.rousselle.me:5022"

# Dossiers locaux et destinations sur le NAS
LOCAL_MEMES_DIR="$HOME/Téléchargements/H/memes"
REMOTE_MEMES_DIR="/Images/ALL H/NEW H"

LOCAL_VIDEOS_DIR="$HOME/Téléchargements/yt-dlp"
REMOTE_VIDEOS_DIR="/Images/ALL H/videos/NEW VIDS"

# Créer un répertoire temporaire pour les logs
LOG_DIR="$HOME/nas_transfer_logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/transfer_$(date +%Y%m%d_%H%M%S).log"

echo "Début du transfert vers le NAS..." | tee -a "$LOG_FILE"

# Fonction pour transférer un dossier
transfer_directory() {
    local source_dir=$1
    local target_dir=$2
    
    if [ ! -d "$source_dir" ]; then
        echo "Le dossier source $source_dir n'existe pas. Ignoré." | tee -a "$LOG_FILE"
        return 1
    fi
    
    echo "Transfert de $source_dir vers $target_dir..." | tee -a "$LOG_FILE"
    
    lftp -u "$USER","$PASS" sftp://"$NAS_ADDRESS" << EOF
        set ssl:verify-certificate no
        mirror -R "$source_dir" "$target_dir"
        quit
EOF >> "$LOG_FILE" 2>&1

    return $?
}

# Transférer les memes
transfer_directory "$LOCAL_MEMES_DIR" "$REMOTE_MEMES_DIR"
MEMES_SUCCESS=$?

# Transférer les vidéos
transfer_directory "$LOCAL_VIDEOS_DIR" "$REMOTE_VIDEOS_DIR"
VIDEOS_SUCCESS=$?

# Vérifier les résultats et supprimer les fichiers transférés
if [ $MEMES_SUCCESS -eq 0 ]; then
    echo "Transfert des memes réussi. Suppression des fichiers locaux..." | tee -a "$LOG_FILE"
    rm -rf "$LOCAL_MEMES_DIR"/*
else
    echo "Erreur lors du transfert des memes." | tee -a "$LOG_FILE"
fi

if [ $VIDEOS_SUCCESS -eq 0 ]; then
    echo "Transfert des vidéos réussi. Suppression des fichiers locaux..." | tee -a "$LOG_FILE"
    rm -rf "$LOCAL_VIDEOS_DIR"/*
else
    echo "Erreur lors du transfert des vidéos." | tee -a "$LOG_FILE"
fi

# Résumé final
if [ $MEMES_SUCCESS -eq 0 ] && [ $VIDEOS_SUCCESS -eq 0 ]; then
    echo "Opération terminée avec succès pour les deux dossiers." | tee -a "$LOG_FILE"
elif [ $MEMES_SUCCESS -eq 0 ] || [ $VIDEOS_SUCCESS -eq 0 ]; then
    echo "Opération partiellement réussie. Consultez le log: $LOG_FILE" | tee -a "$LOG_FILE"
    exit 1
else
    echo "Échec complet du transfert. Consultez le log: $LOG_FILE" | tee -a "$LOG_FILE"
    exit 2
fi