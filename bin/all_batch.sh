#!/bin/bash

cd $HOME/scraper/baidu/; $HOME/scraper/baidu/focus.pl &
cd $HOME/scraper/baidu/; $HOME/scraper/baidu/latest.pl &
cd $HOME/scraper/baidu/; $HOME/scraper/baidu/top.pl &
cd $HOME/scraper/chinafnews/; $HOME/scraper/chinafnews/batch.sh &
cd $HOME/scraper; $HOME/scraper/f1c.pl &
