#!/bin/bash
# m4_ignore(
echo "Ceci est un script généré par argbash."
echo "Pour tester"
# Ce qui suit est généré par argbash
#)

# ARG_OPTIONAL_SINGLE([editor], e, [Éditeur à utiliser], [code])
# ARG_POSITIONAL_SINGLE([project], [Nom du projet à ouvrir])
# ARG_HELP([Ouvre un environement de développement])
# ARGBASH_SET_INDENT([  ])
# ARGBASH_GO

source .env
source ./utils/global/fct.sh

# [ <-- needed because of Argbash
# Votre code ici

# Vérification que le projet existe et est un repo git
if [ ! -d "$DEV_DIR/$_arg_project" ]; then
  echo "Le projet '$_arg_project' n'existe pas dans $DEV_DIR" >&2
  exit 1
fi

if [ ! -d "$DEV_DIR/$_arg_project/.git" ]; then
  echo "Le projet '$_arg_project' n'est pas un repository Git" >&2
  exit 1
fi

# Ouverture dans l'éditeur
echo "Ouverture du projet $_arg_project dans $_arg_editor..."
# "$_arg_editor" "$DEV_DIR/$_arg_project"

# ] <-- needed because of Argbash