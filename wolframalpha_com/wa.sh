#!/bin/sh
#
# by Sairon Istyar, 2012
# distributed under the GPLv3 license
# http://www.opensource.org/licenses/gpl-3.0.html
#

### CONFIGURATION ###
# Your API key for WolframAlpha
# Get one at https://developer.wolframalpha.com/portal/apisignup.html
API_KEY="HERE-GOES-YOUR-API-KEY"
### END OF CONFIGURATION ###

# properly encode query
q=`echo "$*" | od -t x1 -A n | tr ' ' '%' | tr -d '\n'`

# fetch and parse result
result=`wget -qO - "http://api.wolframalpha.com/v2/query?input=$q&appid=$API_KEY&format=plaintext"`
if [ -n "`echo $result | grep 'Invalid appid'`" ] ; then
	echo "Invalid API key! (Have you edited this script's config?)"
	exit 1
fi
result=`echo "$result" \
	| tr '\n' '\x11' \
	| sed 's!<plaintext>!\n<plaintext>!g' \
	| grep -oE "<plaintext>.*</plaintext>|<pod title=.[^\']*" \
	| sed  's!<plaintext>!!g; \
		s!</plaintext>!!g; \
		s!<pod title=.*!\\\x1b[1;36m&\\\x1b[0m!g; \
		s!<pod title=.!!g; \
		s!\&amp;!\&!' \
	| tr '\x11' '\n' \
	| sed  '/^$/d; \
		s/\ \ */\ /g'`

# print result
echo -e "$result"
