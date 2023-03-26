#!/bin/bash
#################################################
# get latest php version tags for each branch
#################################################
phpversions='/tmp/phpversions.txt'

if [ ! -f /usr/bin/jq ]; then
  yum -q -y install jq
fi

getversions() {
  phpver_tag=$1
  if [ -f "$phpversions" ]; then
    phpfile_age=$(echo $(( $(date +%s) - $(date +%s -r "$phpversions") )))
  else
    phpfile_age=7201
  fi
  if [[ "$phpfile_age" -gt '7200' || ! -f "$phpversions" ]]; then
    echo > "$phpversions"
    for page in {1..13}; do
      curl -s "https://api.github.com/repos/php/php-src/tags?page=${page}&per_page=500" | jq -r '.[].name' | grep 'php-' | egrep -iv 'alpha|beta|rc' >> "$phpversions"
    done
  fi

  if [[ "$phpver_tag" = 'all' ]]; then
    versions_list=('8.2.' '8.1.' '8.0.' '7.4.' '7.3.' '7.2.' '7.1.' '7.0.' '5.6.' '5.5.')
  else
    versions_list=("${phpver_tag:0:1}.${phpver_tag:1}.")
  fi

  for version in "${versions_list[@]}"; do
    cat "$phpversions" | grep -m1 "${version}" | sed -e 's|php-||'
  done
}

case "$1" in
  82|81|80|74|73|72|71|70|56|55 )
    getversions "$1"
    ;;
  * )
    getversions all
    ;;
esac