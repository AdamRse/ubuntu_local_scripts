#!/bin/bash

script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")

source "$script_dir/.env"
source "$script_dir/utils/global/nas_fct.sh"
source "$script_dir/utils/global/fct.sh"

shopt -s globstar nullglob

# Options
if [ "$1" == "--debug" ]; then
    debug=true
else
    debug=false
fi
checksum=false
delete_after=false

# Programme
unmount_nas
mount_nas || fout "Impossible de monter le NAS, arrêt du programme."
disable_sleep

lout "=== Début de la sauvegarde ==="

# normaliser le point de montage (supprimer un / final si présent)
nas_root="${NAS_MOUNT_POINT%/}"
$debug && echo "NAS mount point normalisé : $nas_root"

# Statistiques avant copie
lout "⏳ Récupération des statistiques..."
# Variables de stats
stats_total_files=0
stats_total_size=0
for pair in "${BACKUP_PAIRS[@]}"; do
    src="${pair%%:*}"   # partie gauche
    dst="${pair#*:}"    # partie droite

    # Expansion des fichiers (globbing)
    files=( $src )

    if [[ ${#files[@]} -eq 0 ]]; then
        wout "   ⚠️ Aucun fichier trouvé pour $src_glob"
        continue
    fi

    for f in "${files[@]}"; do
        if [[ -f "$f" ]]; then
            (( stats_total_files++ ))
            (( stats_total_size += $(stat -c%s "$f") ))
        fi
    done
done
# Affichage des stats
echo "Nombre total de fichiers : $stats_total_files"
echo "Taille totale : $stats_total_size octets"

# Confirmation du globbing
if ! ask_yn "Copier ces fichiers sur le nas ?"; then
    lout "Arrêt du script par l'utilisateur."
    echo -e "-----------------------\n"
    lout "Pour modification des fichiers à copier, se référer à BACKUP_PAIRS dans $script_dir/.env"
    exit 0
fi

# Copie de fichiers
lout "Lancement de la copie"

# Calcul des options rsync
rsync_opts="-a"
$debug && rsync_opts="-av"
if $checksum; then
    rsync_opts+="c"
else
    rsync_opts+=" --size-only"
fi
$delete_after && rsync_opts+=" --remove-source-files"

$debug && echo "OPTIONS RSYNC : $rsync_opts"

copy_total_files=0
copy_total_size=0
for pair in "${BACKUP_PAIRS[@]}"; do
    # séparation source:destination
    src_glob="${pair%%:*}"
    dest_rel="${pair#*:}"

    $debug && echo ""
    $debug && echo "➡️  Pattern source : $src_glob"
    $debug && echo "   Destination relative brute : $dest_rel"

    # nettoyer la destination relative (enlever / initial/final)
    dest_rel_trimmed=$(trim_slashes "$dest_rel")

    # expansion des fichiers correspondant au glob
    files=( $src_glob )
    if [[ ${#files[@]} -eq 0 ]]; then
        continue
    fi

    # partie fixe avant le glob (pour calculer le chemin relatif)
    base_dir="${src_glob%%[*?]*}"
    $debug && echo "   base_dir calculé : $base_dir"

    for file in "${files[@]}"; do
        if [[ -d "$file" ]]; then
            $debug && echo "   (skip) répertoire trouvé : $file"
            continue
        fi

        # chemin relatif à partir de la base
        rel_path="${file#$base_dir}"
        # nettoyer rel_path (enlever / initial/final s'il y en a)
        rel_path=$(trim_slashes "$rel_path")
        $debug && echo "   rel_path trimé : $rel_path"

        # construire le chemin final sur le NAS en évitant les doublons de slash
        if [[ -n "$dest_rel_trimmed" ]]; then
            dest_path="$nas_root/$dest_rel_trimmed/$rel_path"
        else
            dest_path="$nas_root/$rel_path"
        fi

        dest_dir=$(dirname "$dest_path")
        if [ ! -d "$dest_dir" ]; then
            lout "   📂 Création du dossier : $dest_dir"
            mkdir -p "$dest_dir" || { wout "   ❌ Impossible de créer $dest_dir"; continue; }
        fi

        lout "   📥 Copie de $file → $dest_dir"
        if ! rsync $rsync_opts "$file" "$dest_path"; then
            wout "   ❌ Échec copie $file"
        else
            (( copy_total_files++ ))
            (( copy_total_size += $(stat -c%s "$dest_path") ))
        fi
    done
done


lout "=== Sauvegarde terminée ==="
lout "Démontage du NAS"
enable_sleep
unmount_nas

lout "Fichiers copiés : $copy_total_files/$stats_total_files"
lout "Taille totale : $stats_total_size/$stats_total_size octets"

files_diff=$((stats_total_files - copy_total_files))
size_diff=$((stats_total_size - stats_total_size))

if [ $files_diff -eq 0 ] && [ $size_diff -eq 0 ]; then
    lout "✅ Copie terminée avec succès."
else
    fout "❌ ÉCHEC PARTIEL. Fichiers manquants : $files_diff. Taille manquante : $size_diff octets"
fi