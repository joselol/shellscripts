#!/bin/sh
#
# by Sairon Istyar, 2012
# distributed under the GPLv3 license
# http://www.opensource.org/licenses/gpl-3.0.html
#

# program to use for torrent download
program='/opt/usr/bin/transmission-remote'
progopts='-a'
# show N first matches by default
limit=15
# colors
numbcolor='\x1b[1;35m'
namecolor='\x1b[1;33m'
sizecolor='\x1b[1;36m'
seedcolor='\x1b[1;31m'
peercolor='\x1b[1;32m'
nonecolor='\x1b[0m'

printhelp() {
	echo -e "Usage:\n\t$0 [options] search query\n\nAvailable options:\n\t-h\t\tShow help\n\t-n [num]\tShow only first N results (default 15; max 50)\n\t-C\t\tDo not use colors"
}

while getopts :hCn: opt ; do
	case "$opt" in
		h) printhelp; exit 0;;
		n) limit="$OPTARG";;
		C) unset numbcolor; unset namecolor; unset sizecolor; unset seedcolor; unset peercolor; unset nonecolor;;
		*) echo -e "Unknown option(s)."; printhelp; exit 1;;
	esac
done

shift `expr $OPTIND - 1`

q=`echo "$*" | tr -d '\n' | od -t x1 -A n | tr ' ' '%'`

r=`curl -s "http://torrentz.eu/search?f=$q" \
	| grep -Eo '<dl><dt><a href=\"\/[[:alnum:]]*\">.*</a>|<span class=\"[speud]*\">[^<]*</span>' \
	| sed 's!<dl><dt><a href=\"/!!; \
		s!\">!|!; \
		s!<[/]*b>!!g; \
		N;N;N;s!\n<span class=\"[pesud]*\">!|!g; \
		s!</span>!!g; \
		s!</a>!!'`

n=`echo "$r" | wc -l`

IFS=$'\n'

echo "$r" \
	| head -n "$limit" \
	| awk -v N=1 \
		-v NU="$numbcolor" \
		-v NA="$namecolor" \
		-v SI="$sizecolor" \
		-v SE="$seedcolor" \
		-v PE="$peercolor" \
		-v NO="$nonecolor" \
		-F '|' \
		'{print NU N ") " NA $2 " " SI $3 " " SE $4 " " PE $5 NO; N++}'

read -p ">> Enter torrent No. to download: " down

down=`echo "$down" | sed 's/[^[:digit:]]*//g' | head -n 1`

if [ -z "$down" ] ; then
	echo "Not a number!"
	unset IFS
	exit 1
elif [ $down -ge 1 ] ; then
	if [ $down -le $limit ] ; then
		echo "Downloading..."
		$program $progopts "`echo "$r" | awk -F '|' 'NR=='$down'{print "magnet:?xt=urn:btih:" $1; exit}'`"
	else
		echo "Number too high! ($down)"
		unset IFS
		exit 3
	fi
else
	echo "Number too low! ($down)"
	unset IFS
	exit 2
fi

unset IFS
