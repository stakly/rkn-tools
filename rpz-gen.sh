#!/bin/bash
# This script is used for gerenating bind RPZ zone based on https urls from rkn dump.xml
# dump.xml may be received with https://github.com/yegorov-p/python-zapret-info tools
#
# version 1.1
# requirements: xmlstarlet

[ -z "$2" ] && echo "$0 <dump.xml> <rpz-dns-zone>" && exit 1
xmlstarlet sel -R -t -m '//content' -s 'D:T:-' 'url' -c '.' "$1" | xmlstarlet sel \
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
			-o '			CNAME	lawfilter.magnitka.ru.' \
			-n \
			-o '*.' \
			-v '$DOMAIN' \
			-o '			CNAME	lawfilter.magnitka.ru.' \
			-n \
		--else --break \
	--else \
		--var 'DOMAIN=.' \
		-v '$DOMAIN' \
		-o '			CNAME	lawfilter.magnitka.ru.' \
		-n \
		-o '*.' \
		-v '$DOMAIN' \
		-o '			CNAME	lawfilter.magnitka.ru.' \
		-n \
	-t \
	-m 'set:distinct(//content/domain)' \
	-s 'A:T:-' '.' \
	--if '../@blockType="domain-mask"' \
	-v '.' \
	-o '                    CNAME   lawfilter.magnitka.ru.' \
	-n > "$2"
