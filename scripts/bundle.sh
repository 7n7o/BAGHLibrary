#!/bin/bash
branch="${2:-all}"
path="scripts/lua/$1"
filename=$(basename $1)

if [[ "${branch}" == "all" ]]; then
  "$0" $1 dev &
  "$0" $1 prod &
  wait
  echo "Complete"
  exit 0
fi

if [[ -d $path && -f $path/init.lua ]]; then
    path="$path/init"
fi

out_dir="scripts/bundles/${filename}.${branch}.lua"
in_dir="$path.lua"

echo "Bundling script"
darklua process $in_dir $out_dir -c "scripts/.darklua_bundle.json"
sed -i '1s/^local //' $out_dir

echo "Processing bundle"
darklua process $out_dir $out_dir -c ".darklua_${branch}.json"

echo "Done"
ls -lh $out_dir | awk '{print $5, $9}'