#!/bin/sh
# Ensure every catalog tool has an update record and vice versa.
set -eu
top=$(cd "$(dirname "$0")/../.." && pwd)
cat="$top/zetik-core/data/catalog.json"
src="$top/zetik-infra/conf/tool-sources.yaml"
rc=0
names=$(python3 -c "import json;print('\n'.join(t['name'] for t in json.load(open('$cat'))['tools']))")
for n in $names; do
  grep -q "^  $n:" "$src" || { echo "FAIL: $n missing from tool-sources.yaml"; rc=1; }
done
# reverse: every tool-sources entry (under tools:) exists in catalog
entries=$(awk '/^tools:/{t=1;next} /^[a-z]/{t=0} t && /^  [a-z0-9-]+:/{sub(/:.*/,"");sub(/^  /,"");print}' "$src")
for n in $entries; do
  echo "$names" | grep -qx "$n" || { echo "FAIL: $n in tool-sources.yaml not in catalog"; rc=1; }
done
[ $rc -eq 0 ] && echo "catalog/tool-sources: consistent ($(echo "$names" | wc -l) tools)"
exit $rc
