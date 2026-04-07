#!/bin/sh
rm -rf generated/packages
wally install
darklua process Packages generated/packages -c .darklua_bundle.json 2>/dev/null
exit 0