#!/bin/sh
wally install
rm -rf generated
darklua process src generated -c .darklua.json
rojo build -o build/BAGHLibrary.rbxm