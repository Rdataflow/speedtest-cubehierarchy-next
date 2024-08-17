#!/bin/bash
vAAA="v2.2.2"
vBBB="v3.0.0"

# install sparql-formatter
npm install sparql-formatter

# clone & init AAA
[ -d AAA ] || git clone --branch ${vAAA} --depth 1 https://github.com/zazuko/cube-hierarchy-query.git AAA && pushd AAA && sed -i -e "s~\ *results.forEach(print(0))~~" -e "s~\ *process.exit(0)~~" -e "s~\[\$rdf.ns.schema.name, { language: 'de' }\],~\$rdf.ns.schema.name,\$rdf.ns.schema.description,\$rdf.ns.schema.position,\$rdf.ns.schema.alternateName,~" -e "s~.*log.*('perf')~console.log~" examples/hierarchy.ts && npm install && popd || exit 1

# clone & init BBB
[ -d BBB ] || git clone --branch ${vBBB} --depth 1 https://github.com/zazuko/cube-hierarchy-query.git BBB && pushd BBB && sed -i -e "s~\ *results.forEach(print(0))~~" -e "s~\ *process.exit(0)~~" -e "s~\[\$rdf.ns.schema.name, { language: 'de' }\],~\$rdf.ns.schema.name,\$rdf.ns.schema.description,\$rdf.ns.schema.position,\$rdf.ns.schema.alternateName,~" -e "s~.*log.*('perf')~console.log~" examples/hierarchy.ts && npm install && popd || exit 1

while true ; do ./check.sh ; ./generate_reports.sh ;  done
