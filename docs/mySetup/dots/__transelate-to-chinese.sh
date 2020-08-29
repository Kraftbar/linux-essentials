#!/usr/bin/env bash
# ---------------------------------------------------------
# Script for translating words/sentense by Google Translate
# Version 0.1 made by 
# ---------------------------------------------------------

set -ue

#
# Settings
#
LANG1="en"
LANG2="zh"
BASE_URL="https://translate.google.com/"
USER_AGENT='Mozilla/5.0 (X11; Linux i686) AppleWebKit/534.34 (KHTML, like Gecko) QupZilla/1.3.1 Safari/534.34'




#
# Usage
#
if [ $# -eq 0 ] || [ $# -eq 2 ] || [ $# -gt 3 ]; then
    echo -e "\nAvailable languages:"
    echo -e "---------------------"
    curl -s --user-agent "${USER_AGENT}" "${BASE_URL}m?&mui=sl"|grep -Eo 'sl=[a-zA-Z-]{2,}">[^>]*<'|sed -e 's/sl=//g' -e 's/">/ -> /g' -e 's/<$//g'|tr "\n" ","|awk -F, '{ for ( i=1; i<=NF;i=i+3) printf "%-24s %-24s %-24s\n", $i, $(i+1), $(i+2) }'
    echo -e "\nUsage: `basename $0` Sentence [From] [To]"
    echo -e "------------------------------------"
    echo -e "Example:\n`basename $0` how"
    echo -e "`basename $0` \"How are you\" en zh"

    exit 1
fi

#
# Main
#
if [ $# -eq 1 ]; then
    SENTENCE=`echo "$1" | tr " " "+"`

    # Default languages settings
    if [[ "$SENTENCE" =~ ^[a-zA-Z] ]]; then
        FROM=${LANG1}
        TO=${LANG2}
    else
        FROM=${LANG2}
        TO=${LANG1}
    fi
else
    SENTENCE=`echo "$1" | tr " " "+"`
    FROM="$2"
    TO="$3"
fi

#
# Translate
#
RESULT=$(curl -s --user-agent "${USER_AGENT}" "${BASE_URL}m?hl=en&sl=${FROM}&tl=${TO}&ie=UTF-8&prev=_m&q=${SENTENCE}" 2>/dev/null | sed -n 's/.*class="t0">//;s/<.*$//p')
echo -n  $RESULT 
echo -n -e '\t'



if [ ${TO} == "zh" ]; then
    RESULTpinyin=$(curl -s --user-agent "${USER_AGENT}" "${BASE_URL}m?hl=en&sl=${FROM}&tl=${TO}&ie=UTF-8&prev=_m&q=${SENTENCE}" 2>/dev/null | sed -n 's/.*class="o1">//;s/<.*$//p')
    echo -n  $RESULTpinyin
    echo -n -e '\t'
    echo  "$1"
fi




#
# Voice
#
CHECKED=1
if [ -s $CHECKED ] && [ -n "$RESULT" ] && [ "X$RESULT" != "X$SENTENCE" ]; then
    MP3FILE=$(mktemp --suffix .mp3)
    [ -f ${MP3FILE} ] && curl -s --user-agent "${USER_AGENT}" "${BASE_URL}translate_tts?ie=UTF-8&tl=${FROM}&q=${SENTENCE}" -o ${MP3FILE}
    [ -s ${MP3FILE} ] && mpg123 -q ${MP3FILE}

    if [ -n "$RESULT" ]; then
        [ -f ${MP3FILE} ] && curl -s --user-agent "${USER_AGENT}" "${BASE_URL}translate_tts?ie=UTF-8&tl=${TO}&q=${RESULT}" -o ${MP3FILE}
        [ -s ${MP3FILE} ] && mpg123 -q ${MP3FILE}
    fi

    [ -f ${MP3FILE} ] && rm -f ${MP3FILE}
fi

set +ue

# Exit
exit 0
