#!/bin/bash -x

# This script comes with ABSOLUTELY NO WARRANTY, use at own risk
# Copyright (C) 2012 Osiris Alejandro Gomez <osiux@osiux.com.ar>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.


echo "graph mails2dot {"
echo "  overlap=scalexy;"

GET http://listas.usla.org.ar/pipermail/anillo-lst/2012-July/thread.html | egrep "(Voto|fraude)" | egrep -o "HREF(.*)\"" | cut -c 7-12 | head -10 | while read i
do
    GET http://listas.usla.org.ar/pipermail/anillo-lst/2012-July/${i}.html >$i.html

    F=$(file $i.html)
    Z=$(echo $F | egrep -o "gzip")
    ZOK=$(echo $?)
    H=$(echo $F | egrep -o "HTML")
    HOK=$(echo $?)
    
    if [ $ZOK -eq 0 ]
    then
        cat $i.html | gunzip | tr "\n" " " | iconv -f ISO8859-1 -t UTF8 >$i.txt
    fi

    if [ $HOK -eq 0 ]
    then
        cat $i.html | tr "\n" " " | iconv -f ISO8859-1 -t UTF8 >$i.txt
    fi

    FROM=$(cat $i.txt | egrep -o "H1.*TITLE" | egrep -o "<B.*B>" | tr -d "/" | sed s/"<B>"//g)

    cat $i.txt | egrep -o "<PRE.*PRE>" | \
    html2text -utf8 | tr "\n" " " | egrep -o ".* [\-]{2,}" | \
    sed s/"&quot;"/"> "/g | tr -d "[:punct:]" | \
    tr "\n" " " | egrep -w "[[:alpha:]]+" | tr " " "\n" | egrep "[[:alpha:]]{4,}" | tr A-Z a-z | grep -v "[[:punct:]]" | grep -v "próxima" | sort | uniq -c | sort -nr | head -30 | awk '{print $2}' >$i.words.tmp

    cat $i.words.tmp | while read W
    do
        echo '"'$FROM'" -> "'$W'";'
    done
done

echo "}"

