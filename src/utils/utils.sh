#!/system/bin/sh

# Copyright (C) MIT License 2023 Nicholas Bissell (TheFreeman193)

#
# Persistent config
#
MODULEPATH="/data/adb/modules/pifpicker"
EXTERNALPATH="/data/adb/pifpicker"
CONFIGFILE="$EXTERNALPATH/config"

if [ -f "$CONFIGFILE" ]; then
    while read line; do
        key=$(echo "$line" | sed -E 's;^([^=]+)=.+;\1;g')
        val=$(echo "$line" | sed -E 's;^[^=]+=(.+);\1;g')
        case $key in
            "MODE")
                MODE="$val"
            ;;
            "ABI")
                ABI="$val"
            ;;
            "LASTUPDATE")
                LASTUPDATE="$val"
            ;;
            "OFFLINE")
                OFFLINE="$val"
            ;;
            *)
                echo "pifpicker: Invalid config key '$key'"
            ;;
        esac
    done < $CONFIGFILE
fi
# Modes: 0 = do nothing (but keep profiles collection updated), 1 = use Xiaomi.EU profile, 2 = use random PIFS profile
[ -z "$MODE" ] && MODE=1
# Use profiles from <ABI> folder - "default" uses abilist value from build.prop
[ -z "$ABI" ] && ABI="default"
# Last time Xiaomi.EU or PIFS collection was checked for updates
[ -z "$LASTUPDATE" ] && LASTUPDATE=0
# Disable all updates
[ -z "$OFFLINE" ] && OFFLINE=0

update_config() {
    [ ! -d "$EXTERNALPATH" ] && mkdir "$EXTERNALPATH"
    echo "MODE=$MODE
ABI=$ABI
LASTUPDATE=$LASTUPDATE
OFFLINE=$OFFLINE" > "$CONFIGFILE"
}

#
# VT100 colour handling
#
if [ $( echo "$TERM" | grep -E "term-(25|1)6color$|^xterm$" ) ]; then
    F_R='\e[1;31m';F_G='\e[1;32m';F_B='\e[1;34m';F_C='\e[1;36m';F_M='\e[1;35m';F_Y='\e[1;33m';F_K='\e[1;30m';F_W='\e[1;37m'
    F_DR='\e[0;31m';F_DG='\e[0;32m';F_DB='\e[0;34m';F_DC='\e[0;36m';F_DM='\e[0;35m';F_DY='\e[0;33m';F_DK='\e[0;30m';F_DW='\e[0;37m'
    F_='\e[0;37m'
    B_R='\e[1;41m';B_G='\e[1;42m';B_B='\e[1;44m';B_C='\e[1;46m';B_M='\e[1;45m';B_Y='\e[1;44m';B_K='\e[1;40m';B_W='\e[1;47m'
    B_DR='\e[0;41m';B_DG='\e[0;42m';B_DB='\e[0;44m';B_DC='\e[0;46m';B_DM='\e[0;45m';B_DY='\e[0;44m';B_DK='\e[0;40m';B_DW='\e[0;47m'
    B_='\e[0;40m'
else
    F_R='';F_G='';F_B='';F_C='';F_M='';F_Y='';F_K='';F_W=''
    F_DR='';F_DG='';F_DB='';F_DC='';F_DM='';F_DY='';F_DK='';F_DW=''
    F_=''
    B_R='';B_G='';B_B='';B_C='';B_M='';B_Y='';B_K='';B_W=''
    B_DR='';B_DG='';B_DB='';B_DC='';B_DM='';B_DY='';B_DK='';B_DW=''
    B_=''
fi

#
# Terminal utils
#
clear_term() {
    echo "$F_$B_"
    [ -z "$DEBUG_PIFS" ] && [ -z "$ANDROID_SOCKET_adbd" ] && clear
    return 0
}

BannerDiv="$F_W===================================$F_"
show_logo() {
    echo ""
    echo "$BannerDiv"
    echo "${F_C} Play Integrity Fix Profile Picker$F_"
    echo "$F_DW      Author: ${F_W}TheFreeman193$F_"
    echo "$F_DB      ko-fi.com/nickbissell"
    echo "$F_DW      DEX apktool: ${F_W}osm0sis"
    echo "$F_DB      www.paypal.me/osm0sis$F_"
    echo "$BannerDiv"
    echo ""
}

#
# Web utils
#
if [ "$OFFLINE" -eq 0 ]; then
    webbin=""
    webmode=""
    # Quick tests
    if [ $(command -v curl) ]; then
        webbin="curl"
        webmode="curl"
    elif [ $(command -v wget) ]; then
        webbin="wget"
        webmode="wget"
    elif [ -f "/system/bin/curl" ]; then
        webbin="/system/bin/curl"
        webmode="wget"
    elif [ -f "/system/bin/wget" ]; then
        webbin="/system/bin/wget"
        webmode="wget"
    elif [ -f "/data/data/com.termux/files/usr/bin/curl" ]; then
        webbin="/data/data/com.termux/files/usr/bin/curl"
        webmode="curl"
    elif [ -f "/data/data/com.termux/files/usr/include/curl" ]; then
        webbin="/data/data/com.termux/files/usr/include/curl"
        webmode="curl"
    elif [ -f "/data/adb/magisk/busybox" ]; then
        webbin="/data/adb/magisk/busybox"
        webmode="busybox"
    elif [ -f "/debug_ramdisk/.magisk/busybox/wget" ]; then
        webbin="/debug_ramdisk/.magisk/busybox/wget"
        webmode="wget"
    elif [ -f "/sbin/.magisk/busybox/wget" ]; then
        webbin="/sbin/.magisk/busybox/wget"
        webmode="wget"
    elif [ -f "/system/xbin/wget" ]; then
        webbin="/system/xbin/wget"
        webmode="wget"
    elif [ -f "/system/xbin/curl" ]; then
        webbin="/system/xbin/curl"
        webmode="curl"
    fi

    # Intensive search
    [ -z "$webbin" ] && [ -d "/system" ] && webbin="$(find /system -type f \( -name wget -o -name curl -o -name busybox \) -print 2>/dev/null | head -n 1)"
    [ -z "$webbin" ] && [ -d "/data" ] && webbin="$(find /data -type f \( -name wget -o -name curl -o -name busybox \) -print -quit 2>/dev/null | head -n 1)"
    [ -z "$webbin" ] && [ -d "/bin" ] && webbin="$(find /bin -type f \( -name wget -o -name curl -o -name busybox \) -print 2>/dev/null | head -n 1)"
    [ -z "$webbin" ] && [ -d "/sbin" ] && webbin="$(find /sbin -type f \( -name wget -o -name curl -o -name busybox \) -print -quit 2>/dev/null | head -n 1)"
    [ -z "$webbin" ] && [ -d "/usr" ] && webbin="$(find /usr -type f \( -name wget -o -name curl -o -name busybox \) -print -quit 2>/dev/null | head -n 1)"
    [ -z "$webbin" ] && [ -d "/etc" ] && webbin="$(find /etc -type f \( -name wget -o -name curl -o -name busybox \) -print -quit 2>/dev/null | head -n 1)"
    [ -z "$webbin" ] && [ -d "/vendor" ] && webbin="$(find /vendor -type f \( -name wget -o -name curl -o -name busybox \) -print -quit 2>/dev/null | head -n 1)"
    [ -z "$webbin" ] && [ -d "/debug_ramdisk" ] && webbin="$(find /debug_ramdisk \( -path "*/proc/*" -prune \) -o -type f \( -name wget -o -name curl -o -name busybox \) -print -quit 2>/dev/null | head -n 1)"

    if [ -n "$webbin" ]; then
        [ -z "$webmode" ] && [ $(echo "$webbin" | grep -Ee 'wget$' ) ] && webmode="wget"
        [ -z "$webmode" ] && [ $(echo "$webbin" | grep -Ee 'curl$' ) ] && webmode="curl"
        [ -z "$webmode" ] && [ $(echo "$webbin" | grep -Ee 'bbox$' ) ] && webmode="bbox"
    else
        echo "Couldn't find a suitable web get tool. Module will run in offline mode"
        OFFLINE=1
        update_config
    fi
fi

webgetfile() {
    [ "$OFFLINE" -eq 1 ] && return
    case "$webmode" in
        "curl")
            "$webbin" -o "$2" "$1"
        ;;
        "wget")
            "$webbin" -O "$2" "$1"
        ;;
        "bbox")
            "$webbin" wget -O "$2" "$1"
        ;;
        *)
            return 1
        ;;
    esac
}

webget() {
    [ "$OFFLINE" -eq 1 ] && return
    case "$webmode" in
        "curl")
            echo "$("$webbin" "$1")"
        ;;
        "wget")
            echo "$("$webbin" -O - "$1")"
        ;;
        "bbox")
            echo "$("$webbin" wget -O - "$1")"
        ;;
        *)
            return 1
        ;;
    esac
}

#
# Dalvik VM for running DEX apktool
#

# Quick tests
if [ $(command -v dalvikvm) ]; then
    dvkbin="dalvikvm"
elif [ $(command -v dalvikvm64) ]; then
    dvkbin="dalvikvm64"
elif [ $(command -v dalvikvm32) ]; then
    dvkbin="dalvikvm32"
elif [ -f "/apex/com.android.art/bin/dalvikvm" ]; then
    dvkbin="/apex/com.android.art/bin/dalvikvm"
elif [ -f "/apex/com.android.art/bin/dalvikvm64" ]; then
    dvkbin="/apex/com.android.art/bin/dalvikvm64"
elif [ -f "/apex/com.android.art/bin/dalvikvm32" ]; then
    dvkbin="/apex/com.android.art/bin/dalvikvm32"
elif [ -f "/data/data/com.termux/files/usr/bin/dalvikvm" ]; then
    dvkbin="/data/data/com.termux/files/usr/bin/dalvikvm"
elif [ -f "/data/user/0/com.termux/files/usr/bin/dalvikvm" ]; then
    dvkbin="/data/user/0/com.termux/files/usr/bin/dalvikvm"
fi

# Intensive search
[ -z "$dvkbin" ] && [ -d "/apex" ] && dvkbin="$(find /apex \( -type f -o -type l \) \( -name dalvikvm64 -o -name dalvikvm \) -print 2>/dev/null | head -n 1)"
[ -z "$dvkbin" ] && [ -d "/apex" ] && dvkbin="$(find /apex \( -type f -o -type l \) -name dalvikvm32 -print 2>/dev/null | head -n 1)"
[ -z "$dvkbin" ] && [ -d "/system" ] && dvkbin="$(find /system \( -type f -o -type l \) \( -name dalvikvm32 -o -name dalvikvm64 -o -name dalvikvm \) -print 2>/dev/null | head -n 1)"
[ -z "$dvkbin" ] && [ -d "/data" ] && dvkbin="$(find /data \( -type f -o -type l \) \( -name dalvikvm32 -o -name dalvikvm64 -o -name dalvikvm \) -print -quit 2>/dev/null | head -n 1)"

if [ -z "$dvkbin" ]; then
    echo "Couldn't find a suitable dalvik VM - Updating Xiaomi.EU profile won't be available"
fi
