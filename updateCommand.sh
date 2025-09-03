#!/bin/bash

# Sources
source ./.env
source ./utils/global/fct.sh

# Set
script_dir=$(dirname "$0")

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

#Vérifications du PATH
lout "Vérification du PATH"
if ! is_in_path "$LOCAL_BIN"; then
    if [ ! -d "$LOCAL_BIN" ]; then
        if ! ask_yn () "Le répertoire '$LOCAL_BIN' n'existe pas. Faut-il le créer et l'ajouter au PATH ?"; then
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
    lout "Ajout de l'alias $alias_name"
    
    # Supprimer l'alias existant s'il y en a un
    sed -i "/^[[:space:]]alias[[:space:]]\+$alias_name=/d" "$BASH_ALIASES"
    
    # Ajouter le nouvel alias
    echo "alias $alias_name='$command_name'" >> "$BASH_ALIASES"
done

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