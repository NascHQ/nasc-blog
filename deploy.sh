#!/bin/sh
echo "[ Deleting old publication ]"
rm -rf public
mkdir public

echo "[ Generating Nasc blog ]"
hugo --theme=hugo-theme-casper-master

echo "[ Creating now alias config file ]"
echo "{
	\"name\": \"blog.nasc.io\",
	\"alias\": \"blog.nasc.io\"
}" > ./public/now.json

echo "[ Publishing to now ]"
cd ./public && now && now alias