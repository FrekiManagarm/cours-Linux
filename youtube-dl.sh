#!/bin/bash

path_tmp="/tmp/ytdl/" 
path_sav="${HOME}/Bureau" 
ytdl="/usr/local/bin/youtube-dl" 

name="%(title)s.%(ext)s"
exec="mv '{}' ${path_sav}; exit 0"  

[ -d "$path_sav" ] || exit 1
[ -x "$ytdl" ] || exit 2
mkdir -p "$path_tmp"
cd "$path_tmp"

url="$1"
[ -z "$url" ] && url="$(xclip -o 2>/dev/null)"

while true; do
  if [ ! -z "$url" ]; then
    wget --spider "$url" 2>/dev/null && break || zenity --warning --text "La page $url est introuvable" 2>/dev/null
  fi
  url=$(zenity --entry --title "Youtube-dl GUI" --text "Entrez un lien web contenant une/des vidéo(s)" --entry-text="$url" 2>/dev/null)
  [ $? -ne 0 ] && exit 10
done

a=""
while [ -z "$a" ]; do
  a=$(zenity --list --hide-column=1 --text "Choix d'extraction $url" --title "Youtube-dl GUI" \
  --column "ID" --column "Format" --column "Détails" \
  "hd" "Vidéo HD" "1080p ou inférieur" \
  "sd" "Vidéo SD" "480p ou inférieur" \
  "mp3+" "Audio HQ" "Meilleur qualité" \
  "mp3" "Audio LQ" "Plus léger" 2>"/dev/null")
  [ $? -ne 0 ] && exit 20

  case "$a" in
  "mp3") format="mp3/worstaudio"; audio="-x --audio-format mp3"
  ;;
  "mp3+") format="bestaudio"; audio="-x --audio-format mp3"
  ;;
  "hd") format="best"
  ;;
  "sd") format="best[height<480]/worst[height<=480]/best"
  ;;
  esac
  [ -z "$a" ] && zenity --warning --text "Vous n'avez pas selectionné de choix"
done

coproc zen { zenity --progress --auto-close --text "Recherche du flux vidéo" --title "Téléchargement de ${url:0:43}..." --width=300 2>"/dev/null"; }
pid_zen=$!

echo $ytdl \""$url"\" -f \""$format"\" --newline --restrict-filenames -o \""$name"\" --exec \""$exec"\" $audio
coproc ydl { $ytdl "$url" -f "$format" --newline --restrict-filenames -o "$name" --exec "$exec" $audio 2>"./err" \
|sed -ur "s/\[download\] +([^%]+)% of ([^ ]+) at ([^ ]+) ETA (.*)/#\2 téléchargé (débit \3, ETA \4) \n\1/" \
|sed -u "s/100.0/#Extraction.../">&${zen[1]}; exit ${PIPESTATUS[0]}; }
pid_ytdl=$!

wait -n $pid_ytdl $pid_zen
r_ytdl=$?
kill -0 $pid_ytdl 2>/dev/null && kill $pid_ytdl && echo "Extraction" && exit 1


if [ $r_ytdl -ne 0 ]; then
  a=$(cat "./err" | sed "s/\. .*//")
  echo "#Echec du téléchargement de $url\n\n$a" >&${zen[1]}
else
  echo "100" >&${zen[1]}
fi