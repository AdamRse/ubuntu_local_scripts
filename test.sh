#!/bin/bash

source ./utils/fct.sh

if ask_yn "oui ou non ?"; then
    echo -e "OUI ! true"
else
    echo -e "Nope, false, menteur"
fi