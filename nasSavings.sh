#!/bin/bash

script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")

source "$script_dir/.env"
source "$script_dir/utils/global/nas_fct.sh"
source "$script_dir/utils/global/fct.sh"

shopt -s globstar nullglob

if [ $1 == "--debug" ]; then
    debug=true
else
    debug=false
fi

# Programme
unmount_nas
mount_nas || fout "Impossible de monter le NAS, arrêt du programme."

lout "=== Début de la sauvegarde ==="

# normaliser le point de montage (supprimer un / final si présent)
nas_root="${NAS_MOUNT_POINT%/}"
$debug && echo "NAS mount point normalisé : $nas_root"

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
        wout "   ⚠️ Aucun fichier trouvé pour $src_glob"
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

        lout "   📥 Copie de $file → $dest_path"
        cp -a "$file" "$dest_path" || wout "   ❌ Échec copie $file"
    done
done

lout "=== Sauvegarde terminée ==="
lout "Démontage du NAS"
unmount_nas
