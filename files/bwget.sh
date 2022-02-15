#!/usr/bin/env bash

item=$1
search=$2

id=$(bw list items --search "${search}" | jq ".[] | select(.name == \"$search\").id" -r)

bw get "${item}" "${id}"
