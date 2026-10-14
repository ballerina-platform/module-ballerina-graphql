#!/bin/sh
# TEMPORARY CI diagnostic: runs the given command; if it is still running after DUMP_AFTER seconds,
# prints thread dumps (including virtual threads) of every JVM, repeats once, then kills the run.
DUMP_AFTER=${DUMP_AFTER:-360}
SECOND_DUMP_AFTER=${SECOND_DUMP_AFTER:-120}

sh -c "$*" &
CMD_PID=$!

dump_all() {
    JCMD="${JAVA_HOME:+$JAVA_HOME/bin/}jcmd"
    echo "===== HANG WATCHDOG: dumping threads at $(date -u) ====="
    for pid in $(pgrep java); do
        echo "----- PID $pid: $(tr '\0' ' ' < /proc/$pid/cmdline 2>/dev/null | cut -c1-400)"
        out="/tmp/threads-$pid-$(date +%s).txt"
        "$JCMD" "$pid" Thread.dump_to_file -format=text "$out" >/dev/null 2>&1 && cat "$out" \
            || "$JCMD" "$pid" Thread.print 2>&1
    done
    echo "----- netstat"
    (ss -tanp 2>/dev/null || netstat -tanp 2>/dev/null) | grep -E ':(909[0-9]|90[0-9][0-9])' | head -100
    echo "===== HANG WATCHDOG: end ====="
}

(
    sleep "$DUMP_AFTER"
    kill -0 "$CMD_PID" 2>/dev/null || exit 0
    dump_all
    sleep "$SECOND_DUMP_AFTER"
    kill -0 "$CMD_PID" 2>/dev/null || exit 0
    dump_all
    echo "===== HANG WATCHDOG: killing the hung test run ====="
    pkill -P "$CMD_PID"
    for pid in $(pgrep -f 'BTestMain|ballerina.home'); do kill -9 "$pid" 2>/dev/null; done
    kill -9 "$CMD_PID" 2>/dev/null
) &
WATCHDOG_PID=$!

wait "$CMD_PID"
STATUS=$?
# Kill the watchdog's pending sleep too, or it keeps stdout open and Gradle waits on it.
pkill -P "$WATCHDOG_PID" 2>/dev/null
kill "$WATCHDOG_PID" 2>/dev/null
exit $STATUS
