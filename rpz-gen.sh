#!/bin/bash
# This script is used for generating bind RPZ zone based on https urls from rkn dump.xml
# dump.xml may be received with https://github.com/yegorov-p/python-zapret-info tools
#
# version 1.2
# requirements: xmlstarlet

[ ! -x "`which xmlstarlet`" ] && echo "Unsatisfied requirements: xmlstarlet\n Please install it and try again." && exit 2

usage() {
	echo "$0 [-w] [-d <redirect domain>] <dump.xml> <rpz.zone>"
}

[ $# -lt 2 ] && usage && exit 1

RDOMAIN='lawfilter.local'

while getopts "hwd:" opt; do
	case $opt in
		h)
			usage && exit 1
			;;
		w)
			WILDCARD=1
			;;
		d)
			RDOMAIN=$OPTARG
			;;
		*)
			echo "Invalid options found!" && usage && exit 1
			;;
	esac
done
shift $((OPTIND -1))

DUMP=$1
ZONE=$2

if [ ! -z $WILDCARD ] ; then
	printf -v WILDCARD "%s" "-o *. -v \$DOMAIN -o "
	printf -v WILDCARD2 "\t\t\t%s\t%s" "CNAME" "$RDOMAIN."
	printf -v WILDCARD3 "%s" " -n"
else
	WILDCARD="-o "
	WILDCARD2=""
fi

xmlstarlet sel -R -t -m '//content' -s 'D:T:-' 'url' -c '.' "$DUMP" | xmlstarlet sel \
	-t \
	-o '$TTL 1H	' \
	-n \
	-o '@				SOA LOCALHOST. root.localhost. (1 1h 15m 30d 2h)' \
	-n \
	-o '				NS  LOCALHOST.' \
	-n \
	-m 'set:distinct(//content/domain)' \
	-s 'A:T:-' '.' \
	--if '../@blockType="domain" or (not(../@blockType) and not(starts-with(../url,"http:"))) and string(number(translate(.,".","")))="NaN"' \
	--if 'substring(.,string-length(.),1)="."' \
		--var 'DOMAIN=substring(.,1,string-length(.)-1)' \
		--if 'not(string(//content[domain=$DOMAIN and not(starts-with(url,"http:"))]))' \
			-v '$DOMAIN' \
			-o "			CNAME	$RDOMAIN." \
			-n \
			${WILDCARD} "${WILDCARD2}" ${WILDCARD3} \
		--else --break \
	--else \
		--var 'DOMAIN=.' \
		-v '$DOMAIN' \
		-o "			CNAME	$RDOMAIN." \
		-n \
		${WILDCARD} "${WILDCARD2}" ${WILDCARD3} \
	-t \
	-m 'set:distinct(//content/domain)' \
	-s 'A:T:-' '.' \
	--if '../@blockType="domain-mask"' \
	-v '.' \
	-o "                    CNAME   $RDOMAIN." \
	-n > "$ZONE"

if [ $? -gt 0 ] ; then
	echo "errors occured" && exit 2
else
	echo "done, filename: $ZONE"
fi
