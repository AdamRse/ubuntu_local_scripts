#!/bin/bash

# Set
script_path=$(readlink -f "$0")
script_dir=$(dirname "$script_path")

# Sources
source $script_dir/.env
source $script_dir/utils/global/fct.sh

# Fonctions
is_in_path() {
    local target_dir=$(realpath -q "$1" 2>/dev/null || echo "$1")
    local IFS=':'
    
    for path_dir in $PATH; do
        local abs_path_dir=$(realpath -q "$path_dir" 2>/dev/null || echo "$path_dir")
        if [ "$abs_path_dir" = "$target_dir" ]; then
            return 0
        fi
    done
    return 1
}
cleanup_old_commands() {
    lout "Nettoyage des anciens liens symboliques"
    
    # Créer un tableau des commandes actuelles
    local current_commands=()
    for entry in "${COMMAND_MAPPING[@]}"; do
        command_name="${entry%%:*}"
        current_commands+=("$command_name")
    done
    
    # Parcourir tous les fichiers dans LOCAL_BIN
    if [ -d "$LOCAL_BIN" ]; then
        for link_path in "$LOCAL_BIN"/*; do
            # Vérifier si c'est un lien symbolique
            if [ -L "$link_path" ]; then
                link_name=$(basename "$link_path")
                link_target=$(readlink -f "$link_path")
                
                # Vérifier si le lien pointe vers un script dans notre répertoire
                if [[ "$link_target" == "$script_dir"/* ]]; then
                    # Vérifier si le nom du lien n'est plus dans la configuration actuelle
                    if ! printf '%s\n' "${current_commands[@]}" | grep -qx "$link_name"; then
                        lout "Suppression de l'ancien lien symbolique: $link_name -> $link_target"
                        rm -f "$link_path"
                    fi
                fi
            fi
        done
    fi
}
cleanup_old_aliases() {
    lout "Nettoyage des alias"
    local tmp_file
    tmp_file=$(mktemp)

    # Construire un tableau associatif des alias du .env
    declare -A env_aliases
    declare -A env_commands

    for entry in "${ALIAS_MAPPING[@]}"; do
        local name="${entry%%:*}"
        local command="${entry#*:}"
        env_aliases["$name"]="$command"
        env_commands["$command"]="$name"
        echo "  -> Alias '$name' = '$command'"
    done

    while IFS= read -r line; do
        if [[ "$line" =~ ^alias[[:space:]]+([^=]+)=\"(.*)\"$ ]]; then
            local file_alias="${BASH_REMATCH[1]}"
            local file_command="${BASH_REMATCH[2]}"

            if [[ -n "${env_aliases[$file_alias]}" ]]; then
                # Vérifie si commande identique
                if [[ "${env_aliases[$file_alias]}" == "$file_command" ]]; then
                    echo "$line" >> "$tmp_file"
                fi
            else
                # Pas le même alias, mais commande identique ?
                if [[ -n "${env_commands[$file_command]}" ]]; then

                else
                    echo "$line" >> "$tmp_file"
                fi
            fi
        else
            # Ligne qui n'est pas un alias
            echo "$line" >> "$tmp_file"
        fi
    done < "$BASH_ALIASES"

    echo "Écrasement de $BASH_ALIASES avec contenu nettoyé..."
    mv "$tmp_file" "$BASH_ALIASES"
}



# ---------
# PROGRAMME
# ---------

#Vérifications du PATH
lout "Vérification du PATH"
if ! is_in_path "$LOCAL_BIN"; then
    if [ ! -d "$LOCAL_BIN" ]; then
        if ! ask_yn "Le répertoire '$LOCAL_BIN' n'existe pas. Faut-il le créer et l'ajouter au PATH ?"; then
            fout "Annulation de l'utilisateur, le répertoire '$LOCAL_BIN' n'existe pas."
        fi

        lout "Création du répertoire $LOCAL_BIN"
        mkdir -p "$LOCAL_BIN" || fout "Impossible de créer le répertoire '$LOCAL_BIN'"

        lout "Ajout du répertoire '$LOCAL_BIN' dans le PATH"
        echo 'PATH="$PATH:$LOCAL_BIN"' >> "$BASH_PROFILE" || fout "Impossible de modifier le PATH dans $BASH_PROFILE"

        lout "Rechargement du PATH ($BASH_PROFILE)"
        source "$BASH_PROFILE"
    fi
fi

# Ajout des commandes
lout "Ajout des commandes"
for entry in "${COMMAND_MAPPING[@]}"; do
    # Séparer au premier ":" seulement
    command_name="${entry%%:*}"
    script_name="${entry#*:}"

    lout "Ajout de la commande : $command_name -> $script_name"
    
    chmod +x "$script_dir/$script_name"
    ln -sf "$script_dir/$script_name" "$LOCAL_BIN/$command_name" || wout "Impossible d'écrire le lien symbolique pour $command_name -> $script_name"
done
# Nettoyage d'anciennes commandes
cleanup_old_commands

# Ajout des Alias
# Vérification de l'existance d'un fichier alias
lout "Ajout des aliases dans $BASH_ALIASES"
if [ ! -f "$BASH_ALIASES" ]; then
    mkdir -p "$(dirname "$BASH_ALIASES")" && > "$BASH_ALIASES"
fi

for entry in "${ALIAS_MAPPING[@]}"; do
    # Séparer au premier ":" seulement
    alias_name="${entry%%:*}"
    command_name="${entry#*:}"
    lout "Ajout de l'alias $alias_name=\"$command_name\""
    
    # Supprimer l'alias existant s'il y en a un
    sed -i "/^[[:space:]]*alias[[:space:]]\+$alias_name=/d" "$BASH_ALIASES"
    
    # Ajouter le nouvel alias
    echo "alias $alias_name=\"$command_name\"" >> "$BASH_ALIASES"
done
# Nettoyage des ancien aliases
cleanup_old_aliases

# Vérifier que le fichier aliases est appelé dans le .bashrc
lout "Vérification de l'appel du fichier aliases dans le ~/.bashrc"
test_alias_token=$(uuidgen)
lout "Ajout du token de vérification"
echo "TEST_ALIAS='$test_alias_token'" >> "$BASH_ALIASES"
source "$HOME/.bashrc"
if [ "$TEST_ALIAS" != "$test_alias_token" ]; then
    lout "Token non trouvé, ajout de $BASH_ALIASES au .bashrc"
    echo "source \"$BASH_ALIASES\"" >> "$HOME/.bashrc" || fout "Impossible d'ajouter $BASH_ALIASES au .bashrc. Ajoutez la ligne de code : 'source \"$BASH_ALIASES\"' à votre ~/.bashrc"
fi
lout "Aliases pris en compte par le .bashrc, supression du token"
sed -i "/TEST_ALIAS=/d" "$BASH_ALIASES"