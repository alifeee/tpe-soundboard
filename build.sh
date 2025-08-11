#!/bin/bash
# build HTML files

set -eou pipefail

# takes many () seconds to build all sounds so if just testing, just add argument
#   showing which sounds to process
quick="${1:-}"
if [[ -n "${quick}" ]]; then
    echo "run quick (only "${quick}" sounds)"
    TITLES=( "${quick}" )
else
    echo "run full"
    TITLES=( Coach Doors General Misc Reasons Safety Stations Times Toilet )
fi

# mustache template parser
source ./mo

# arrays for all the sounds
export TITLES
readarray -d '' Coach < <(find audio/Coach -type f -print0 | sort -z)
readarray -d '' Doors < <(find audio/Doors -type f -print0 | sort -z)
readarray -d '' General < <(find audio/General -type f -print0 | sort -z)
readarray -d '' Misc < <(find audio/Misc -type f -print0 | sort -z)
readarray -d '' Reasons < <(find audio/Reasons -type f -print0 | sort -z)
readarray -d '' Safety < <(find audio/Safety -type f -print0 | sort -z)
readarray -d '' Stations < <(find audio/Stations -type f -print0 | sort -z)
readarray -d '' Times < <(find audio/Times -type f -print0 | sort -z)
readarray -d '' Toilet < <(find audio/Toilet -type f -print0 | sort -z)
export Coach
export Doors
export General
export Misc
export Reasons
export Safety
export Stations
export Times
export Toilet

# turn e.g., "audio/Coach/1054.wav" into "1054"
soundname () {
    bn="${MO_FUNCTION_ARGS[0]##*/}"
    echo "${bn%.*}"
}

# rebuild TEMPLATE first
INDEX_FILE="index.html.mustache"
TEMP_FILE="/tmp/index295gyrfwiijt2.html.mustache"
START_CONTENT="<!-- !!start templating!! -->"
END_CONTENT="<!-- !!end templating!! -->"

original_html=$(cat $INDEX_FILE)
# get line numbers of START_CONTENT and END_CONTENT
start=$(echo "${original_html}" | grep -n "${START_CONTENT}" | cut -d : -f1)
end=$(echo "${original_html}" | grep -n "${END_CONTENT}" | cut -d : -f1)

if [ -z $start ] || [ -z $end ]; then
  echo "could not find start/end content tags" >> /dev/stderr
  echo "start: <$start>, end: <$end>" >> /dev/stderr
  exit 1
fi

rm -f $TEMP_FILE
echo "${original_html}" | awk 'NR <= '"${start}"'' >> $TEMP_FILE
for title in "${TITLES[@]}"; do
    cat << EOHTML >> $TEMP_FILE
      <h2>
        $title
        <a class="toplink" href="#top">top</a>
      </h2>
      <section class="board">
        {{#$title}}
        <div class="sound" id="{{ . }}">
          <button class="play" onclick='play("{{ . }}")'>
            {{ soundname . }}
          </button>
          <button class="favourite" onclick='favourite("{{ . }}")'>
            &hearts;
          </button>
        </div>
        {{/$title}}
      </section>
EOHTML
done
echo "${original_html}" | awk 'NR >= '"${end}"'' >> $TEMP_FILE

cat $TEMP_FILE | sponge $INDEX_FILE

# build html
echo "building…"
cat index.html.mustache \
  | mo \
  | sponge index.html &
pid=$! # Process Id of the previous running command
spin='-\|/'
i=0
startdate=$(date '+%s')
while kill -0 $pid 2>/dev/null
do
  i=$(( (i+1) %4 ))
  nowdate=$(date '+%s')
  difftime=$(($nowdate - $startdate))
  printf "\r${spin:$i:1} $difftime s"
  sleep .1
done
echo ""

echo "built to index.html! 🚀️"
