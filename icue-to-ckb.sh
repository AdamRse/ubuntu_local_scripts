#!/bin/bash

# Vérifier si xmlstarlet est installé
if ! command -v xmlstarlet &> /dev/null; then
    echo "Erreur: xmlstarlet n'est pas installé. Installez-le avec:"
    echo "sudo apt-get install xmlstarlet  # Pour Debian/Ubuntu"
    exit 1
fi

# Vérifier qu'un fichier a été fourni en argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 fichier.xml"
    exit 1
fi

xml_file="$1"

# Extraire les données et formater le tableau
echo "Extraction des mappages de touches:"
echo "------------------------------------------------------------"
echo "Nom de l'action | Bouton souris | Touche clavier | Événement"
echo "------------------------------------------------------------"

# Nouveau XPath plus robuste
xmlstarlet sel -t -m "//*[local-name()='actions']/*[starts-with(local-name(), 'value')]" \
    -v "concat(normalize-space(.//*[local-name()='name']), ' | ', 
               normalize-space(.//*[local-name()='key']), ' | ',
               normalize-space(.//*[local-name()='keyName']), ' | ',
               normalize-space(.//*[local-name()='event']))" \
    -n "$xml_file" | column -t -s "|"

echo "------------------------------------------------------------"