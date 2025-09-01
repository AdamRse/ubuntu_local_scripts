#!/bin/bash
# Ficher de configuration pour les aliases de commande bash
# <nom_commande>="<execution_commande>"

# Attention, sensible à la case

yt-dlp-m="yt-dlp -P '$HOME/Musique' -f m4a"
yt-dlp-tv="yt-dlp -P '$HOME/Vidéos/Nas à transférer' -f 'bestvideo[vcodec^=vp9]+m4a'"