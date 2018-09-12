#!/bin/sh

counter=0

function processLine() {
  if [ "$1" ] && [[ ! ${1:0:1} == "#" ]]; then # blank lines & comments ignored
    ((counter++))
    echo "Download (feed_$counter.rss): $1"
    curl -s -o "Resources/feed_$counter.rss" "$1"
  fi
}

while read -r line; do
  processLine "$line";
done < "download_list.txt";
processLine "$line"
