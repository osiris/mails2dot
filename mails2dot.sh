#!/bin/bash

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

NODE_SHAPE=plaintext
FONT_NAME=inconsolata
EDGE_STYLE=invis
CC_LICENSE=cba

COLOR_LIST=(aquamarine blue blueviolet brown cadetblue chartreuse chocolate coral cornflowerblue crimson cyan darkgoldenrod darkgreen darkolivegreen darkorange darkorchid darksalmon darkseagreen darkslateblue darkslategray darkturquoise darkviolet deeppink deepskyblue dodgerblue firebrick forestgreen gold goldenrod gray green greenyellow indianred indigo lawngreen lightblue lightsalmon lightseagreen lightskyblue lightslateblue lightslategray limegreen magenta maroon mediumaquamarine mediumblue mediumorchid mediumpurple mediumseagreen mediumslateblue mediumspringgreen mediumturquoise mediumvioletred midnightblue navy navyblue olivedrab orange orangered orchid palegreen palevioletred peru pink plum powderblue purple red rosybrown royalblue saddlebrown salmon sandybrown seagreen sienna skyblue slateblue slategray springgreen steelblue tomato turquoise violet violetred wheat yellow yellowgreen)
MAX=86

BG_COLOR=black
LIST='anillo-lst'
MONTH='July'
YEAR='2012'
SITE='http://listas.usla.org.ar'
URL=$SITE'/pipermail/'$LIST'/'$YEAR'-'$MONTH
REGEXP='(Voto|fraude)'

rm -f *.tmp
rm -f *.log

GET $(echo $URL'/thread.html') | egrep "$REGEXP" | egrep -o "HREF(.*)\"" | cut -c 7-12 >mails.tmp

echo 'graph mails2dot {'$'\n'
echo '  graph [bgcolor='$BG_COLOR',fontcolor=white,fontname="'$FONT_NAME'",fontsize=24,label="'$URL' | '$REGEXP'"]'$'\n'
echo '  node [shape='$NODE_SHAPE', fontname='$FONT_NAME', fontsize=10, fontcolor=gray];'
echo '  edge [style='$EDGE_STYLE'];'
echo '  thread [label=" ",fontcolor='$BG_COLOR',fontsize=10];'
echo '  ccbysa [label="'$CC_LICENSE'",fontname="CC Icons",fontcolor=gray,fontsize=24];'
echo '  thread -- ccbysa [len="1"];'


cat mails.tmp | while read i
do
    GET $URL'/'${i}.html >$i.html

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
    else
        echo $i >>error.log
    fi

    FROM=$(cat $i.txt | egrep -o "H1.*TITLE" | egrep -o "<B.*B>" | tr -d "/" | sed s/"<B>"//g | sed s/"&quot;"//g)
    echo $FROM >>from.tmp
    FF=$(echo $FROM | tr " " "-" | tr A-Z a-z)

    cat $i.txt | egrep -o "<PRE.*PRE>" | \
    html2text -utf8 | tr "\n" " " | egrep -o ".* [\-]{2,}" | \
    sed s/"&quot;"/"> "/g | tr -d "[:punct:]" | \
    tr "\n" " " | egrep -w "[[:alpha:]]+" | tr " " "\n" | egrep "[[:alpha:]]{4,}" | tr A-Z a-z | grep -v "[[:punct:]]" | grep -v "próxima" | sort | uniq -c | sort -nr | awk '{print $2}' >>$FF.words.tmp

done


echo "// FROM"
COLOR='white'
SIZE='50'
cat from.tmp | sort -u | while read FROM
do
    echo '"'$FROM'"' '[label="'$FROM'",fontcolor='$COLOR',fontsize='$SIZE'];'
done
echo ""


echo "// WORDS"
cat *.words.tmp | tr "á" "a" | tr "é" "e" | tr "í" "i" | tr "ó" "o" | tr "ú" "u" | sort | uniq -c | sort -nr | grep -v 1 >allwords.tmp
cat allwords.tmp | awk '{print $2}' >words.tmp
cat allwords.tmp | while read i
do
    INDEX=$((RANDOM%$MAX+1))
    COLOR=$(echo ${COLOR_LIST[$INDEX]})
    REPEAT=$(echo $i | awk '{print $1}')
    WORD=$(echo $i | awk '{print $2}')
    SIZE=$[10+$REPEAT+1]
    echo '"'$WORD'"' '[label="'$WORD'",fontcolor='$COLOR',fontsize='$SIZE'];'
done
echo ""
echo "// WORDS BY FROM"
cat from.tmp | sort -u | while read FROM
do
    echo 'thread -- "'$FROM'";'

    FF=$(echo $FROM | tr " " "-" | tr A-Z a-z)
    cat $FF.words.tmp | tr "á" "a" | tr "é" "e" | tr "í" "i" | tr "ó" "o" | tr "ú" "u" | grep -f words.tmp | while read WORD
    do
        REPEAT=$(grep -w "$WORD" allwords.tmp | head -1 | awk '{print $1}')
        MAXLEN=100
        LEN=$[$MAXLEN-$REPEAT+1]
        echo '"'$FROM'" -- "'$WORD'" [len="'$LEN'"];'
    done
done

    echo "}"

