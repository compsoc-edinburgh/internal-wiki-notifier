#!/bin/sh
set -euo pipefail

# Check if the "cache" directory exists, and if not, create it

if [ ! -d cache ]
then
  mkdir cache
fi

# Check if the "recent_updates.txt" file exists, and if not, create it
if [ ! -f cache/updates_cache.txt ]
then
	touch cache/updates_cache.txt
fi

# Get the recent updates from the WikiJS API
output=$(curl -s --header "Authorization: Bearer ${WIKIJS_API_KEY}" --header "Content-Type: application/json" -X POST -d '{"query": "{pages{list(orderBy: UPDATED, orderByDirection: DESC, limit: 10) {id, path, title, updatedAt, createdAt}}}"}' https://wiki.internal.comp-soc.com/graphql)
wait $! # Makes sure the command in the last $() was successful, exit if not

# Output is structured as:
# {
#   "data": {
#     "pages": {
#       "list": [{
#         "id":6,
#         "path":"sigs/HTB/info",
#         "title":"Hack the Burgh",
#         "updatedAt":"2022-11-20T18:35:31.059Z",
#         "createdAt":"2022-11-20T17:58:27.308Z"}
#       },{
#         "id":7,
#         "path":"..."
#       }]
#     }
#   }
# }

# Now try to find only the objects within the update list that do not exist in
# the cache - which is done through comparing updatedAt fields

# zsh expands \n within the json into actual newlines if we just do echo "$output", so use printf:
# https://stackoverflow.com/questions/30171582/do-not-interpolate-newline-characters-in-curl-response-in-strings
new_updates=$(printf '%s\n' "$output" | jq --slurpfile old cache/updates_cache.txt '[$old.[].data.pages.list[].updatedAt] as $old_timestamps | [.data.pages.list[].updatedAt] as $new_timestamps | ($new_timestamps - $old_timestamps) as $new_updates | [.data.pages.list[] | select([.updatedAt]|inside($new_updates))]')
wait $! # Makes sure the command in the last $() was successful, exit if not
printf '%s\n' "$output" > cache/updates_cache.txt

# new_updates is structured as:
# [
#   {
#     "id": 6,
#     "path": "sigs/HTB/info",
#     "title": "Hack the Burgh",
#     "updatedAt": "2022-11-20T18:35:31.059Z",
#     "createdAt": "2022-11-20T17:58:27.308Z"
#   }, ...
# ]

number_new_updates=$(printf '%s\n' "$new_updates" | jq -r length)
wait $! # Makes sure the command in the last $() was successful

if [ "$number_new_updates" -gt 0 ]; then
	echo "$(date '+%Y-%m-%d %H:%M:%S UTC') | $number_new_updates new updates, posting"
  	# Create a webhook title that says "X new updates"
	headline=$(printf '%s\n' "$new_updates" |
		jq -r '
		"\(length) wiki page\(if length > 1 then "s were" else " was" end) updated"'
	)

  	# Create a webhook body that lists the new updates as links to the wiki.
	# Wiki.Js returns an ISO8601 timestamp with milliseconds, but we want to show
	# user-friendly relative times on the notification. For this, we first remove
	# the milliseconds with regex so that it becomes true ISO8601, then convert
	# it to a unix timestamp using jq's internal function, and finally wrap it in
	# Discord's syntax for relative times.
	body=$(printf '%s\n' "$new_updates" |
		jq -r '
		[reverse | .[] | .updatedAt |= sub("(?<time>.*)\\..*Z"; "\(.time)Z") | .updatedAt |= fromdateiso8601 | "**\(.title)** [`\(.path)`](https://wiki.internal.comp-soc.com/en/\(.path)) - <t:\(.updatedAt):R>"] as $list | $list | .[0:5] | join("\\n") as $string | $list | if length > 5 then "\($string)\\n   ...and \(length - 5) more" else $string end
		'
	)
 	wait $!

  	# Escape double quotes in the body so JSON doesn't break when using with curl
  	body=$(printf '%s\n' "$body" | sed 's/"/\\\"/g')
   	wait $!

	curl \
		-X POST \
		-H "Content-Type: application/json" \
		-d "{ \"username\": \"CompSoc Internal Wiki Updates\", \"avatar_url\": \"https://d7umqicpi7263.cloudfront.net/img/product/270b2d4d-7902-4fbf-b245-b6ea862ceea8/d2fde27f-c059-4140-8f13-ce17827af33c.PNG\", \"embeds\": [{ \"title\": \"$headline\", \"type\": \"rich\", \"description\": \"$body\", \"color\": 2697569 }] }" \
    "https://discord.com/api/webhooks/${WEBHOOK_ID}/${WEBHOOK_TOKEN}"
    	wait $!
	echo "$(date '+%Y-%m-%d %H:%M:%S UTC') | $number_new_updates new updates, posted"
fi
