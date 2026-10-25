#!/bin/bash
LOGFILE="/tmp/mirror_debug.log"
> "$LOGFILE"

refresh_mirrors() {
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup || true
    LOCATION=$(curl -s --max-time 5 https://ipinfo.io/country | tr -d '[:space:]')

    REFLECTOR_OK=true
    if [ -n "$LOCATION" ]; then
        reflector --country "$LOCATION" --latest 10 --protocol https --sort rate --download-timeout 5 --save /etc/pacman.d/mirrorlist >> "$LOGFILE" 2>&1 || REFLECTOR_OK=false
    else
        REFLECTOR_OK=false
    fi

    if [ "$REFLECTOR_OK" = false ] || [ ! -s /etc/pacman.d/mirrorlist ]; then
        reflector --latest 10 --protocol https --sort rate --download-timeout 5 --save /etc/pacman.d/mirrorlist >> "$LOGFILE" 2>&1 || true
    fi

    if [ ! -s /etc/pacman.d/mirrorlist ]; then
        [ -f /etc/pacman.d/mirrorlist.backup ] && cp /etc/pacman.d/mirrorlist.backup /etc/pacman.d/mirrorlist
    fi

    pacman -Syy --noconfirm archlinux-keyring artix-keyring >> "$LOGFILE" 2>&1 || true
}

refresh_mirrors
echo "--- Done. LOCATION=$LOCATION REFLECTOR_OK=$REFLECTOR_OK ---"
echo "--- mirrorlist contents: ---"
cat /etc/pacman.d/mirrorlist
echo "--- log: ---"
cat "$LOGFILE"
