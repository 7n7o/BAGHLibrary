#!/bin/bash
branch="${1:-all}"
path="build/bundle"
filename=$(basename $path)

if [[ "${branch}" == "all" ]]; then
  "$0" dev
  "$0" prod
  wait
  echo "Complete"
  exit 0
fi

out_dir="build/${filename}.${branch}.lua"
in_dir="src/init.lua"

echo "Bundling script"
darklua process $in_dir $out_dir -c ".darklua_bundle.json"
sed -i '1s/^local //' $out_dir

echo "Processing bundle"
darklua process $out_dir $out_dir -c ".darklua_${branch}.json"

echo "Done"
ls -lh $out_dir | awk '{print $5, $9}'