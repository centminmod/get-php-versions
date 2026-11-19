#!/bin/bash
#################################################
# get latest php version tags for each branch
#################################################
phpversions='/tmp/phpversions.txt'

refresh_versions() {
  # Build the tag list in a temp file and only replace the cache with a
  # complete list: the fetch must finish, and the list must not shrink
  # (php-src only adds tags). A failed, cut-off or rate-limited fetch keeps
  # the last good list.
  local tmp ok=n page tags names old_count new_count
  tmp=$(mktemp "${phpversions}.XXXXXX") || return 1
  # expand the path now: $tmp is local and gone once this function returns
  trap "rm -f '$tmp'" EXIT
  # one git request, not subject to the GitHub API's 60 requests/hour limit
  if command -v git >/dev/null 2>&1; then
    if tags=$(timeout 30 git ls-remote --tags --refs https://github.com/php/php-src.git 'php-*' 2>/dev/null); then
      printf '%s\n' "$tags" | awk -F'refs/tags/' '{print $2}' | grep -E '^php-[0-9]+\.[0-9]+\.[0-9]+$' > "$tmp" && ok=y
    fi
  fi
  # fallback: GitHub tags API (100 tags a page), only if every page downloads
  if [ "$ok" != y ] && command -v jq >/dev/null 2>&1; then
    : > "$tmp"
    for page in $(seq 1 50); do
      if ! tags=$(curl -fsS --connect-timeout 5 --max-time 15 "https://api.github.com/repos/php/php-src/tags?page=${page}&per_page=100" 2>/dev/null) ||
         ! names=$(printf '%s' "$tags" | jq -r '.[].name' 2>/dev/null); then
        break
      fi
      # an empty page is the end of the list
      if [ -z "$names" ]; then
        ok=y
        break
      fi
      printf '%s\n' "$names" | grep -E '^php-[0-9]+\.[0-9]+\.[0-9]+$' >> "$tmp"
    done
  fi
  new_count=0
  if [ "$ok" = y ]; then
    sort -t- -k2 -V -r -u -o "$tmp" "$tmp"
    new_count=$(grep -c '^php-[0-9]' "$tmp")
  fi
  # unique tags: lists from older versions of this script can hold duplicates
  old_count=$(grep '^php-[0-9]' "$phpversions" 2>/dev/null | sort -u | wc -l)
  if [ "$new_count" -gt 0 ] && [ "$new_count" -ge "${old_count:-0}" ]; then
    chmod 0644 "$tmp"
    mv -f "$tmp" "$phpversions"
  else
    rm -f "$tmp"
    # keep the last good list and mark it fresh, so an outage is not retried
    # on every call (getversions retries a list without tags after 5 minutes)
    touch "$phpversions"
  fi
}

getversions() {
  phpver_tag=$1
  if [ -f "$phpversions" ]; then
    phpfile_age=$(( $(date +%s) - $(date +%s -r "$phpversions") ))
  else
    phpfile_age=7201
  fi
  # refresh when older than 2 hours, or after 5 minutes when the cache holds
  # no release tags
  if [[ "$phpfile_age" -gt '7200' ]] || { [[ "$phpfile_age" -gt '300' ]] && ! grep -q '^php-[0-9]' "$phpversions" 2>/dev/null; }; then
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