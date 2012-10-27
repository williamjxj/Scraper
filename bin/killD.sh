#!/bin/bash

cd $HOME/scraper/logs

ps -ef | grep perl |grep -v grep | awk '{print $2}' | while read pid 
do 
	kill -9 $pid
done

cd -
