#!/bin/bash
shopt -s extglob
export LC_ALL=C.UTF-8

mkdir -p html_reports

echo '<!DOCTYPE HTML><html lang="en"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Performance Report</title></head><body style="font-family:sans-serif;"><h1>Performance Monitoring</h1>' >"html_reports/index.html"
echo "<h3><a href=\"summary.html\">summary</a></h3>" >>"html_reports/index.html"

for csv_filepath in csv_metrics/*.csv; do
  [ $(cat $csv_filepath | wc -l) -eq 1 ] && continue
  csv_filename=$(basename -s ".csv" "$csv_filepath")
  echo "$csv_filename"

  csv=$(cut -d "," -f "1-3" <"$csv_filepath" | tr "\n" "|" | sed -e 's|https://test.ld.admin.ch/query||' | sed -e 's|https://int.ld.admin.ch/query||' | sed -e 's|https://ld.admin.ch/query||' )
  endpoint=$(cut -d , -f 4 <$csv_filepath | tail -1)
  cube=$(cut -d , -f 5 <$csv_filepath | tail -1)
  dimensionIri=$(cut -d , -f 6 <$csv_filepath | tail -1)
  queryfileAAA=$(cut -d , -f 8 <$csv_filepath | tail -1)
  queryfileBBB=$(cut -d , -f 9 <$csv_filepath | tail -1)
  querycmd="yarn example ./examples/hierarchy.ts --endpoint ${endpoint} --cube  ${cube} --dimensionIri ${dimensionIri}"
  p20vAAA=$(cat "$csv_filepath" | awk -F , '{print ($2)}' | (percentile=20; grep -v https|(sort -n;echo)|nl -ba -v0|tac|(read count;cut=$(((count * percentile + 99) / 100)); tac|sed -n "${cut}s/.*\t//p"))| cut -c-5)
  p50vAAA=$(cat "$csv_filepath" | awk -F , '{print ($2)}' | (percentile=50; grep -v https|(sort -n;echo)|nl -ba -v0|tac|(read count;cut=$(((count * percentile + 99) / 100)); tac|sed -n "${cut}s/.*\t//p"))| cut -c-5)
  p80vAAA=$(cat "$csv_filepath" | awk -F , '{print ($2)}' | (percentile=80; grep -v https|(sort -n;echo)|nl -ba -v0|tac|(read count;cut=$(((count * percentile + 99) / 100)); tac|sed -n "${cut}s/.*\t//p"))| cut -c-5)
  p95vAAA=$(cat "$csv_filepath" | awk -F , '{print ($2)}' | (percentile=95; grep -v https|(sort -n;echo)|nl -ba -v0|tac|(read count;cut=$(((count * percentile + 99) / 100)); tac|sed -n "${cut}s/.*\t//p"))| cut -c-5)
  querycodevAAA=$(cat $queryfileAAA | tail -n+3 | head -n-4 | npx sparql-formatter | jq -Rr @html )
  versionAAA=$(jq -r .version < AAA/package.json)
  p20vBBB=$(cat "$csv_filepath" | awk -F , '{print ($3)}' | (percentile=20; grep -v https|(sort -n;echo)|nl -ba -v0|tac|(read count;cut=$(((count * percentile + 99) / 100)); tac|sed -n "${cut}s/.*\t//p"))| cut -c-5)
  p50vBBB=$(cat "$csv_filepath" | awk -F , '{print ($3)}' | (percentile=50; grep -v https|(sort -n;echo)|nl -ba -v0|tac|(read count;cut=$(((count * percentile + 99) / 100)); tac|sed -n "${cut}s/.*\t//p"))| cut -c-5)
  p80vBBB=$(cat "$csv_filepath" | awk -F , '{print ($3)}' | (percentile=80; grep -v https|(sort -n;echo)|nl -ba -v0|tac|(read count;cut=$(((count * percentile + 99) / 100)); tac|sed -n "${cut}s/.*\t//p"))| cut -c-5)
  p95vBBB=$(cat "$csv_filepath" | awk -F , '{print ($3)}' | (percentile=95; grep -v https|(sort -n;echo)|nl -ba -v0|tac|(read count;cut=$(((count * percentile + 99) / 100)); tac|sed -n "${cut}s/.*\t//p"))| cut -c-5)
  querycodevBBB=$(cat $queryfileBBB | tail -n+3 | head -n-4 | jq -Rr @html )
  versionBBB=$(jq -r .version < BBB/package.json)
  inversepath=$(curl ${endpoint} --data "query=PREFIX meta: <https://cube.link/meta/> PREFIX sh: <http://www.w3.org/ns/shacl#> PREFIX cube: <https://cube.link/> ASK WHERE { <${cube}> cube:observationConstraint/sh:property [ sh:path <${dimensionIri}>; meta:inHierarchy/meta:nextInHierarchy*/sh:path/sh:inversePath []; ] .}" -X POST -H "Accept: application/sparql-results+json" -s | jq .boolean)
  childtargetclass=$(curl ${endpoint} --data "query=PREFIX meta: <https://cube.link/meta/> PREFIX sh: <http://www.w3.org/ns/shacl#> PREFIX cube: <https://cube.link/> ASK WHERE { <${cube}> cube:observationConstraint/sh:property [ sh:path <${dimensionIri}>; meta:inHierarchy/meta:nextInHierarchy+/sh:targetClass []; ] .}" -X POST -H "Accept: application/sparql-results+json" -s | jq .boolean)

  template=$(cat report_template.html)
  reportname=$(echo "$csv_filename" | sed -E "s/[0-9a-f]{55}$//")
  template=$(echo "$template" | sed -e "s/reportname/${reportname}/g")
  template=${template/querycmd/${querycmd}}
  template=${template/querykind/${querykind}}
  template=${template/inversepath/${inversepath}}
  template=${template/childtargetclass/${childtargetclass}}
  template=$(echo "$template" | sed -e "s/p20vAAA/${p20vAAA}/")
  template=$(echo "$template" | sed -e "s/p50vAAA/${p50vAAA}/")
  template=$(echo "$template" | sed -e "s/p80vAAA/${p80vAAA}/")
  template=$(echo "$template" | sed -e "s/p95vAAA/${p95vAAA}/")
  template=${template/querycodevAAA/"${querycodevAAA}"}
  template=$(echo "$template" | sed -e "s/p20vBBB/${p20vBBB}/")
  template=$(echo "$template" | sed -e "s/p50vBBB/${p50vBBB}/")
  template=$(echo "$template" | sed -e "s/p80vBBB/${p80vBBB}/")
  template=$(echo "$template" | sed -e "s/p95vBBB/${p95vBBB}/")
  template=${template/querycodevBBB/"${querycodevBBB}"}
  template=${template/csv_file_contents/$csv}
  template=${template/versionAAA/v${versionAAA}}
  template=${template/versionBBB/v${versionBBB}}
  template=${template/querytimeAAA/v${versionAAA}}
  template=${template/querytimeBBB/v${versionBBB}}
  echo "${template}" >"html_reports/$csv_filename.html"

  echo "<h3><a href=\"$csv_filename.html\">$csv_filename</a></h3>" >>"html_reports/index.html"
done
cat html_reports/http*.html > html_reports/summary.html
