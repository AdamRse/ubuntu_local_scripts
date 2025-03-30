#!/bin/bash
# Script de transfert de fichiers vers NAS
source .env
# Configuration
USER="$NAS_USER"
PASS="$NAS_PASSWORD"
NAS_ADDRESS="$NAS_FTP_ADDR"

# Dossiers locaux et destinations sur le NAS
LOCAL_MEMES_DIR="$HOME/Téléchargements/H/memes"
REMOTE_MEMES_DIR="/Images/ALL H/NEW H"
LOCAL_VIDEOS_DIR="$HOME/Téléchargements/yt-dlp"
REMOTE_VIDEOS_DIR="/Images/ALL H/videos/NEW VIDS"

# Configuration des timeouts (en secondes)
WAKE_TIMEOUT=120  # 2 minutes pour le réveil du NAS
TRANSFER_TIMEOUT=7200  # 2 heures pour les transferts
RETRY_INTERVAL=10  # Intervalle entre les tentatives de connexion

# Créer un répertoire temporaire pour les logs
LOG_DIR="$HOME/nas_transfer_logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/transfer_$(date +%Y%m%d_%H%M%S).log"

# Fonction pour les messages de log
log_message() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$LOG_FILE"
}

log_message "Début du processus de transfert vers le NAS..."

# Vérifier si lftp est installé
if ! command -v lftp &> /dev/null; then
    log_message "ERREUR: lftp n'est pas installé. Veuillez l'installer avec 'sudo apt install lftp'"
    exit 3
fi

# Fonction pour attendre que le NAS soit disponible
wait_for_nas() {
    log_message "Tentative de réveil du NAS. Cela peut prendre jusqu'à $(($WAKE_TIMEOUT/60)) minutes..."
    
    local start_time=$(date +%s)
    local end_time=$((start_time + WAKE_TIMEOUT))
    local attempt=1
    
    while [ $(date +%s) -lt $end_time ]; do
        log_message "Tentative de connexion #$attempt au NAS..."
        
        # Test de connexion avec timeout pour éviter de bloquer
        timeout 10 lftp -u "$USER","$PASS" sftp://"$NAS_ADDRESS" -e "ls; exit" &> /dev/null
        
        if [ $? -eq 0 ]; then
            local elapsed=$(($(date +%s) - start_time))
            log_message "NAS disponible après ${elapsed} secondes."
            return 0
        fi
        
        log_message "NAS pas encore disponible. Nouvelle tentative dans $RETRY_INTERVAL secondes..."
        sleep $RETRY_INTERVAL
        attempt=$((attempt+1))
    done
    
    log_message "ERREUR: Impossible de se connecter au NAS après $(($WAKE_TIMEOUT/60)) minutes."
    return 1
}

# Fonction pour transférer un dossier
transfer_directory() {
    local source_dir=$1
    local target_dir=$2
    local description=$3
    
    if [ ! -d "$source_dir" ]; then
        log_message "Le dossier source $source_dir n'existe pas. Ignoré."
        return 1
    fi
    
    # Vérifier s'il y a des fichiers à transférer
    if [ -z "$(ls -A "$source_dir" 2>/dev/null)" ]; then
        log_message "Le dossier $source_dir est vide. Rien à transférer."
        return 0
    fi
    
    log_message "Transfert de $description depuis $source_dir vers $target_dir..."
    
    # Utiliser timeout pour éviter que lftp ne reste bloqué indéfiniment
    timeout $TRANSFER_TIMEOUT lftp -u "$USER","$PASS" sftp://"$NAS_ADDRESS" << EOF
set ssl:verify-certificate no
set sftp:auto-confirm yes
set net:max-retries 5
set net:timeout 60
set net:reconnect-interval-base 15
set net:reconnect-interval-multiplier 1
set xfer:eta-period 10
mirror -R "$source_dir" "$target_dir"
quit
EOF
    
    local status=$?
    if [ $status -eq 0 ]; then
        log_message "Transfert de $description réussi."
    elif [ $status -eq 124 ]; then
        # Code 124 est retourné par timeout quand la commande est interrompue
        log_message "ERREUR: Timeout lors du transfert de $description après $TRANSFER_TIMEOUT secondes."
    else
        log_message "ERREUR: Échec du transfert de $description (code: $status)."
    fi
    
    return $status
}

# Fonction pour supprimer les fichiers avec confirmation de sécurité
safe_remove() {
    local dir=$1
    local description=$2
    local success=$3
    
    if [ $success -eq 0 ]; then
        log_message "Transfert des $description réussi. Préparation à la suppression des fichiers locaux..."
        
        # Créer un dossier de sauvegarde avant suppression (au cas où)
        local backup_dir="$LOG_DIR/backup_$(date +%Y%m%d_%H%M%S)_${description// /_}"
        mkdir -p "$backup_dir"
        
        # Copier les noms des fichiers dans un fichier de référence
        find "$dir" -type f -name "*" | sort > "$backup_dir/files_list.txt"
        log_message "Liste des fichiers sauvegardée dans $backup_dir/files_list.txt"
        
        # Suppression des fichiers
        rm -rf "$dir"/*
        log_message "Fichiers $description supprimés."
    else
        log_message "Erreur lors du transfert des $description. Les fichiers locaux sont conservés."
    fi
}

# Tenter de réveiller le NAS avant de commencer
wait_for_nas
if [ $? -ne 0 ]; then
    log_message "Impossible de se connecter au NAS. Abandon du transfert."
    exit 4
fi

# Transférer les memes
transfer_directory "$LOCAL_MEMES_DIR" "$REMOTE_MEMES_DIR" "memes"
MEMES_SUCCESS=$?

# Transférer les vidéos
transfer_directory "$LOCAL_VIDEOS_DIR" "$REMOTE_VIDEOS_DIR" "vidéos"
VIDEOS_SUCCESS=$?

# Supprimer les fichiers transférés
safe_remove "$LOCAL_MEMES_DIR" "memes" $MEMES_SUCCESS
safe_remove "$LOCAL_VIDEOS_DIR" "vidéos" $VIDEOS_SUCCESS

# Résumé final
if [ $MEMES_SUCCESS -eq 0 ] && [ $VIDEOS_SUCCESS -eq 0 ]; then
    log_message "Opération terminée avec succès pour les deux dossiers."
    exit 0
elif [ $MEMES_SUCCESS -eq 0 ] || [ $VIDEOS_SUCCESS -eq 0 ]; then
    log_message "Opération partiellement réussie. Consultez le log: $LOG_FILE"
    exit 1
else
    log_message "Échec complet du transfert. Consultez le log: $LOG_FILE"
    exit 2
fi