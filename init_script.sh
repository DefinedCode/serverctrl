#!/bin/bash
PROG_PATH="/Users/will3942/projects/serverctrl"

start() {
    if [ -e "$PROG_PATH/tmp/pids/server.pid" ]; then
        echo -e "[ERROR] ServerCtrl is currently running." 1>&2
        exit 1
    else
        cd $PROG_PATH
        echo -e "[INFO] Installing required ruby gems (bundler)."
        bundle install > /var/log/serverctrl.log 2>&1
        rake assets:precompile > /var/log/serverctrl.log 2>&1
        rails s -e production -d > /var/log/serverctrl.log 2>&1
        echo -e "[OK] ServrCtrl started."
    fi
}

stop() {
    if [ -e "$PROG_PATH/tmp/pids/server.pid" ]; then
        kill -9 $(<"$PROG_PATH/tmp/pids/server.pid")  
        rm $PROG_PATH/tmp/pids/server.pid  
        echo -e "[OK] ServerCtrl stopped."
    else
        echo -e "[ERROR] ServerCtrl is not running." 1>&2
        exit 1
    fi
}

if [ "$(id -u)" != "0" ]; then
    echo -e "[ERROR] ServerCtrl must be run as root." 1>&2
    exit 1
fi

case "$1" in
    start)
        start
        exit 0
    ;;
    stop)
        stop
        exit 0
    ;;
    reload|restart|force-reload)
        stop
        start
        exit 0
    ;;
    **)
        echo "Usage: $0 {start|stop|restart}" 1>&2
        exit 1
    ;;
esac