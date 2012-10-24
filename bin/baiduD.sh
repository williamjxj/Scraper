#!/bin/bash
# http://stackoverflow.com/questions/766397/how-can-i-run-a-perl-script-as-a-system-daemon-in-linux
# baiduD This starts and stops baiduD
#
# chkconfig: 2345 12 88
# description: baiduD is baidu scraper daemon.
# processname: baiduD
# pidfile: /var/run/baiduD.pid

# Source function library.
. /etc/init.d/functions

binary="/home/williamjxj/scraper/baidu/baiduD"

[ -x $binary ] || exit 0

RETVAL=0

start() {
    echo -n "Starting baiduD: "
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