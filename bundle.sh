#!/bin/sh
wally install
rm -rf generated
darklua process Packages Packages -c .darklua_bundle.json
darklua process src/init.lua build/bundle.lua -c .darklua_bundle.json