#!/bin/bash

cd $HOME/scraper

git add .
git commit -a -m"update at `date`"
git push origin master

cd -
