#!/bin/sh
wally install
rm -rf generated
darklua process src generated -c .darklua_build.json
rojo build -o build/BAGHLibrary.rbxm