#!/system/bin/sh
MODDIR=${0%/*}
LOGFILE=$MODDIR/dontkillapp.log
PACKAGES="com.idormy.sms.forwarder"

log_magisk() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOGFILE"
    log -p i -t dontkillapp "$1"
}

init_log() {
    mkdir -p "$MODDIR"
    rm -f "$LOGFILE"
    touch "$LOGFILE"
    chmod 0666 "$LOGFILE"
    
    log_magisk "=== New Session Started ==="
    log_magisk "Module directory: $MODDIR"
    log_magisk "Log file: $LOGFILE"
}

wait_for_boot() {
    log_magisk "Waiting for system boot completion..."
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        sleep 1
    done
    log_magisk "System boot completed"
}

# 设置 oom_score_adj 和 oom_adj 
set_oom_score() {
    for pkg in $PACKAGES; do
        pids=$(pidof $pkg)
        if [ -z "$pids" ]; then
            log_magisk "No process found for package: $pkg"
            continue
        fi
        
        log_magisk "Found PIDs for $pkg: $pids"
        for pid in $pids; do
            # 设置 oom_score_adj
            if [ -f "/proc/$pid/oom_score_adj" ]; then
                current_score=$(cat /proc/$pid/oom_score_adj 2>/dev/null)
                log_magisk "Current oom_score_adj for $pkg (PID: $pid): $current_score"
                
                if echo -1000 > /proc/$pid/oom_score_adj 2>/dev/null; then
                    new_score=$(cat /proc/$pid/oom_score_adj 2>/dev/null)
                    log_magisk "Set oom_score_adj for $pkg (PID: $pid) to: $new_score"
                else
                    log_magisk "Failed to set oom_score_adj for $pkg (PID: $pid)"
                fi
            else
                log_magisk "oom_score_adj file not found for PID: $pid"
            fi
            
            # 设置 oom_adj
            if [ -f "/proc/$pid/oom_adj" ]; then
                current_adj=$(cat /proc/$pid/oom_adj 2>/dev/null)
                log_magisk "Current oom_adj for $pkg (PID: $pid): $current_adj"
                
                if echo -17 > /proc/$pid/oom_adj 2>/dev/null; then
                    new_adj=$(cat /proc/$pid/oom_adj 2>/dev/null)
                    log_magisk "Set oom_adj for $pkg (PID: $pid) to: $new_adj"
                else
                    log_magisk "Failed to set oom_adj for $pkg (PID: $pid)"
                fi
            else
                log_magisk "oom_adj file not found for PID: $pid"
            fi
        done
    done
}

# 初始化日志
init_log

# 等待系统启动完成
wait_for_boot

# 尝试设置 wake_lock（如果设备支持）
if [ -f /sys/power/wake_lock ]; then
    echo "PowerManagerService.noSuspend" > /sys/power/wake_lock 2>/dev/null
    log_magisk "Wake lock set"
else
    log_magisk "Wake lock not supported on this device"
fi

targetTime="4"
targetTime2="16"
executedToday=false
appPackage="com.idormy.sms.forwarder"
appActivity="com.idormy.sms.forwarder/com.idormy.sms.forwarder.MainActivity"

log_magisk "Starting main loop"

# 主循环
while true; do
    # 每30分钟执行一次唤醒
    log_magisk "定时唤醒"
    am start -n "$appActivity" >/dev/null 2>&1
    
    # OOM 保护
    set_oom_score
    
    # 检查是否需要重启应用
    ctime=$(date +"%H")
    currentDate=$(date +"%Y-%m-%d")
    
    if [ "$ctime" = "$targetTime" ] || [ "$ctime" = "$targetTime2" ]; then
        if [ "$executedToday" = false ]; then
            log_magisk "每天4点或16点杀死app重新启动"
            am force-stop "$appPackage"
            sleep 2
            am start -n "$appActivity" >/dev/null 2>&1
            executedToday=true
            log_magisk "Executed restart at $currentDate $ctime:00"
        fi
    else
        # 重置标志变量，每天0点之后允许再次执行
        if [ "$ctime" = "00" ]; then
            executedToday=false
            log_magisk "Reset executedToday flag"
        fi
    fi
    
    # 等待30分钟
    sleep 180
done