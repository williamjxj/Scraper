#!/bin/bash
# http://stackoverflow.com/questions/766397/how-can-i-run-a-perl-script-as-a-system-daemon-in-linux
#
# Source function library.
. /etc/init.d/functions

binary="/home/williamjxj/scraper/baiduD.pl"

[ -x $binary ] || exit 0

RETVAL=0

start() {
    echo -n "Starting baidu Daemon: "
    daemon $binary
    RETVAL=$?
    PID=$!
    echo
    [ $RETVAL -eq 0 ] && touch /var/lock/fmxw/baiduD

    echo $PID > /var/run/baiduD.pid
}

stop() {
    echo -n "Shutting down baiduD: "
    killproc baiduD
    RETVAL=$?
    echo
    if [ $RETVAL -eq 0 ]; then
        rm -f /var/lock/fmxw/baiduD
        rm -f /var/run/baiduD.pid
    fi
}

restart() {
    echo -n "Restarting baiduD: "
    stop
    sleep 2
    start
}

case "$1" in
    start)
        start
    ;;
    stop)
        stop
    ;;
    status)
        status baiduD
    ;;
    restart)
        restart
    ;;
    *)
        echo "Usage: $0 {start|stop|status|restart}"
    ;;
esac

exit 0
