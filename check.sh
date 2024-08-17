#!/bin/bash
export LC_ALL=C.UTF-8
INTERVAL=${1:-20}
counter=0

check_query() {
  counter=$((counter+1))
  prefix=$(printf "%03d" $counter)
  # input args: (human_name, url, ...curl args)
  query=$*
  echo "$query"
  endpoint=${5}
  cube=${7}
  dimensionIri=${9}
  queryid="${5}"_"${7}"_"${9}"
  [[ "$queryid" = "__" ]] && return
  filename_base="${prefix}_${queryid//[^A-Za-z0-9 ]/_}"
  csv_filepath="csv_metrics/${filename_base}.csv"

  if [ ! -f "$csv_filepath" ]; then
    csv_headers="timestamp,querytimeAAA,querytimeBBB,endpoint,cube,dimensionIri,logfile,queryfileAAA,queryfileBBB"
    echo "$csv_headers" >"$csv_filepath"
  fi

  timestamp=$(($(date +%s%N) / 1000000))
  logfile="logs/${filename_base}.log"
  tmpfileAAA="logs/"$filename_base"_"$timestamp".AAA.query"
  tmpfileBBB="logs/"$filename_base"_"$timestamp".BBB.query"
  queryfileAAA="logs/${filename_base}.AAA.query"
  queryfileBBB="logs/${filename_base}.BBB.query"
  $(cd "./AAA" ; eval "$* --print-query" > "../$tmpfileAAA" 2> "../$logfile" )
  queryAAA_retval=$?
  $(cd "./BBB" ; eval "$* --print-query" > "../$tmpfileBBB" 2>> "../$logfile" )
  queryBBB_retval=$?

  querytimeAAA=$(grep "getHierarchy" "$tmpfileAAA" | awk '{print $2}' | sed -e 's/s.$//' | xargs printf "%.0f" )
  querytimeBBB=$(grep "getHierarchy" "$tmpfileBBB" | awk '{print $2}' | sed -e 's/s.$//' | xargs printf "%.0f" )
  [ $queryAAA_retval -ne 0 ] && return $queryAAA_retval
  [ $queryBBB_retval -ne 0 ] && return $queryBBB_retval
  grep 'INTERNAL_SERVER_ERROR' $tmpfileBBB && rm $tmpfileBBB && return 50
  grep 'GRAPHQL_VALIDATION_FAILED' $tmpfileBBB && rm $tmpfileBBB && return 90
  grep 'Error: Request-URI Too Large (414)' $tmpfileBBB && rm $tmpfileBBB && return 90
  mv ${tmpfileAAA} ${queryfileAAA}
  mv ${tmpfileBBB} ${queryfileBBB}
  echo -e "$timestamp,$querytimeAAA,$querytimeBBB,$endpoint,$cube,$dimensionIri,$logfile,$queryfileAAA,$queryfileBBB" >>"$csv_filepath"
}

mkdir -p csv_metrics logs

#while IFS=\' read -r url ; do eval curl $url ; done < urls.txt
while IFS="" read -r query || [ -n "$query" ]; do
  [[ "$query" =~ ^#.* ]] && continue
  check_query $query
  sleep $INTERVAL
done <hierarchies.txt
