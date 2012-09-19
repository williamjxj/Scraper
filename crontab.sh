#!/bin/bash

cd $HOME/scraper/baidu/;
ps -ef | grep focus.pl | grep -v grep >/dev/null
if [ X"$?" != X"0" ]; then
	$HOME/scraper/baidu/focus.pl 2>/dev/null &
fi

ps -ef | grep latest.pl | grep -v grep
if [ $? != 0  ]; then
	$HOME/scraper/baidu/latest.pl 2>/dev/null &
fi

ps -ef | grep top.pl | grep -v grep
if [ $? != 0  ]; then
	$HOME/scraper/baidu/top.pl 2>/dev/null &
fi

ps -ef | grep chinafnews.pl | grep -v grep
if [ $? != 0  ]; then
	cd $HOME/scraper/chinafnews/; $HOME/scraper/chinafnews/batch.sh 2>/dev/null  &
fi

ps -ef | grep f1c.pl | grep -v grep
if [ $? != 0  ]; then
	cd $HOME/scraper; $HOME/scraper/f1c.pl 2>/dev/null &
fi
