#!/usr/bin/env bash

defaults write org.p0deje.Maccy ignoreEvents true
pass "$1" -c
sleep 0.5
defaults write org.p0deje.Maccy ignoreEvents false
