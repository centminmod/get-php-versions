#!/bin/bash
#################################################
# get latest php version tags for each branch
#################################################
phpversions='/tmp/phpversions.txt'

getversions() {
echo > "$phpversions"
curl -s "https://api.github.com/repos/php/php-src/tags?per_page=500" | jq -r '.[].name' | grep 'php-' | egrep -iv 'alpha|beta|rc' >> "$phpversions"
curl -s "https://api.github.com/repos/php/php-src/tags?page=2&per_page=500" | jq -r '.[].name' | grep 'php-' | egrep -iv 'alpha|beta|rc' >> "$phpversions"
curl -s "https://api.github.com/repos/php/php-src/tags?page=3&per_page=500" | jq -r '.[].name' | grep 'php-' | egrep -iv 'alpha|beta|rc' >> "$phpversions"
curl -s "https://api.github.com/repos/php/php-src/tags?page=4&per_page=500" | jq -r '.[].name' | grep 'php-' | egrep -iv 'alpha|beta|rc' >> "$phpversions"
curl -s "https://api.github.com/repos/php/php-src/tags?page=5&per_page=500" | jq -r '.[].name' | grep 'php-' | egrep -iv 'alpha|beta|rc' >> "$phpversions"
curl -s "https://api.github.com/repos/php/php-src/tags?page=6&per_page=500" | jq -r '.[].name' | grep 'php-' | egrep -iv 'alpha|beta|rc' >> "$phpversions"
curl -s "https://api.github.com/repos/php/php-src/tags?page=7&per_page=500" | jq -r '.[].name' | grep 'php-' | egrep -iv 'alpha|beta|rc' >> "$phpversions"
curl -s "https://api.github.com/repos/php/php-src/tags?page=8&per_page=500" | jq -r '.[].name' | grep 'php-' | egrep -iv 'alpha|beta|rc' >> "$phpversions"
curl -s "https://api.github.com/repos/php/php-src/tags?page=9&per_page=500" | jq -r '.[].name' | grep 'php-' | egrep -iv 'alpha|beta|rc' >> "$phpversions"
curl -s "https://api.github.com/repos/php/php-src/tags?page=10&per_page=500" | jq -r '.[].name' | grep 'php-' | egrep -iv 'alpha|beta|rc' >> "$phpversions"
cat "$phpversions" | grep -m1 '7.3.' | sed -e 's|php-||'
cat "$phpversions" | grep -m1 '7.2.' | sed -e 's|php-||'
cat "$phpversions" | grep -m1 '7.1.' | sed -e 's|php-||'
cat "$phpversions" | grep -m1 '7.0.' | sed -e 's|php-||'
cat "$phpversions" | grep -m1 '5.6.' | sed -e 's|php-||'
cat "$phpversions" | grep -m1 '5.5.' | sed -e 's|php-||'
#cat "$phpversions" | grep -m1 '5.4.' | sed -e 's|php-||'
#cat "$phpversions" | grep -m1 '5.3.' | sed -e 's|php-||'
}

getversions