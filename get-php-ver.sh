#!/bin/bash
#################################################
# get latest php version tags for each branch
#################################################
phpversions='/tmp/phpversions.txt'

if [ ! -f /usr/bin/jq ]; then
  yum -q -y install jq
fi

refresh_versions() {
  # Build the tag list in a temp file and only replace the cache when it holds
  # release tags, so a failed or rate-limited fetch never leaves an empty cache
  local tmp
  tmp=$(mktemp "${phpversions}.XXXXXX") || return 1
  # one git request, not subject to the GitHub API's 60 requests/hour limit
  if command -v git >/dev/null 2>&1; then
    timeout 30 git ls-remote --tags --refs https://github.com/php/php-src.git 'php-*' 2>/dev/null | awk -F'refs/tags/' '{print $2}' | grep -E '^php-[0-9]+\.[0-9]+\.[0-9]+$' | sort -t- -k2 -V -r > "$tmp"
  fi
  # fallback: GitHub tags API
  if ! grep -q '^php-[0-9]' "$tmp" && command -v jq >/dev/null 2>&1; then
    for page in {1..13}; do
      curl -s "https://api.github.com/repos/php/php-src/tags?page=${page}&per_page=500" | jq -r '.[].name' 2>/dev/null | grep -E '^php-[0-9]+\.[0-9]+\.[0-9]+$' >> "$tmp"
    done
    sort -t- -k2 -V -r -o "$tmp" "$tmp"
  fi
  if grep -q '^php-[0-9]' "$tmp"; then
    chmod 0644 "$tmp"
    mv -f "$tmp" "$phpversions"
  else
    rm -f "$tmp"
    # keep the last good list and mark it fresh, so an outage is not retried on every call
    [ -s "$phpversions" ] && touch "$phpversions"
  fi
}

getversions() {
  phpver_tag=$1
  if [ -f "$phpversions" ]; then
    phpfile_age=$(( $(date +%s) - $(date +%s -r "$phpversions") ))
  else
    phpfile_age=7201
  fi
  # refresh when older than 2 hours, or when the cache holds no release tags
  if [[ "$phpfile_age" -gt '7200' ]] || ! grep -q '^php-[0-9]' "$phpversions" 2>/dev/null; then
    refresh_versions
  fi

  if [[ "$phpver_tag" = 'all' ]]; then
    versions_list=('8.6.' '8.5.' '8.4.' '8.3.' '8.2.' '8.1.' '8.0.' '7.4.' '7.3.' '7.2.' '7.1.' '7.0.' '5.6.' '5.5.')
  elif [[ "$phpver_tag" = '8' ]]; then
    versions_list=('8.6.' '8.5.' '8.4.' '8.3.' '8.2.' '8.1.' '8.0.')
  elif [[ "$phpver_tag" = '7' ]]; then
    versions_list=('7.4.' '7.3.' '7.2.' '7.1.' '7.0.')
  elif [[ "$phpver_tag" = '5' ]]; then
    versions_list=('5.6.' '5.5.')
  else
    versions_list=("${phpver_tag:0:1}.${phpver_tag:1}.")
  fi

  for version in "${versions_list[@]}"; do
    grep -m1 "^php-${version//./\\.}" "$phpversions" 2>/dev/null | sed -e 's|php-||'
  done
}

case "$1" in
  86|85|84|83|82|81|80|74|73|72|71|70|56|55 )
    getversions "$1"
    ;;
  8)
    getversions "$1"
    ;;
  7)
    getversions "$1"
    ;;
  5)
    getversions "$1"
    ;;
  * )
    getversions all
    ;;
esac