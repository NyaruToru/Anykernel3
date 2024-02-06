 # AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=NekoKernel for Poco X3 (NFC) by Telegram@NyaruToru
do.devicecheck=1
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=0
device.name1=surya
device.name2=karna
device.name3=surya_in
device.name4=karna_in
device.name5=
supported.versions=11.0-14.1
supported.patchlevels=
'; } # end properties

boot_attributes() {
set_perm_recursive 0 0 755 644 $ramdisk/*;
set_perm_recursive 0 0 750 750 $ramdisk/init* $ramdisk/sbin;
} # end attributes


# shell variables
block=/dev/block/bootdevice/by-name/boot
is_slot_device=0;
ramdisk_compression=none;
patch_vbmeta_flag=auto;
no_block_display=1;

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;

if [ -e "/tmp/recovery.log" ]; then
    if mountpoint -q /external_sd; then
        backup_location="/external_sd/backup_boot-$(date '+%H%M%y%m%d').img"
        ui_print "[!] Backing up boot in external SDCard..."
    else
        backup_location="/external_sd/backup_boot-$(date '+%H%M%y%m%d').img"
        ui_print "[!] Backing up boot in internal storage..."
    fi
    dd if=/dev/block/by-name/boot of="$backup_location"
    if [ $? != 0 ]; then
        ui_print "[!] Backup failed; proceeding anyway . . ."
    else
        ui_print "[+] Done!"
    fi
elif [ "$(id -u)" == "0" ]; then
    ui_print "[!] Backing up boot in internal storage..."
    backup_location="/external_sd/backup_boot-$(date '+%H%M%y%m%d').img"
    dd if=/dev/block/by-name/boot of="$backup_location"
    if [ $? != 0 ]; then
        ui_print "[!] Backup failed; proceeding anyway . . ."
    else
        ui_print "[+] Done!"
    fi
else
    ui_print " "
    ui_print "[!] Cannot perform backup."
fi


ksu_dir="kernel/ksu"
stock_dir="kernel/stock"


case "$(basename "$ZIPFILE" .zip | tr '[:upper:]' '[:lower:]')" in
*ksu*)
    sleep 1
    ui_print " "
    ui_print "[!] Installing with KSU support..."
    cd "$ksu_dir" || exit 1
    if mv Image_ksu ../../Image && mv dtbo_ksu.img ../../dtbo.img; then
        sleep 1
    else
        sleep 0.5
        ui_print "[!] Error while copying files!"
    fi
    ;;
*stock*)
    sleep 1
    ui_print " "
    ui_print "[!] Installing w/o KSU support..."
    cd "$stock_dir" || exit 1
    if mv Image_stock ../../Image && mv dtbo_stock.img ../../dtbo.img; then
        sleep 1
    else
        sleep 0.5
        ui_print "[!] Error while copying files!"
    fi
    ;;
*)

    INSTALLER=$(pwd)
    KEYCHECK="$INSTALLER/tools/keycheck"
    chmod 755 "$KEYCHECK"

    choosenew() {
        local delay=25
        local error=false
        sleep 1
        ui_print " "
        ui_print "[!] Press any volume key first!"
        while true; do
            timeout "$delay" "$KEYCHECK"
            local sel=$?
            if [ $sel -eq 42 ] || [ $sel -eq 21 ]; then
                ui_print "[+] Done!"
                sleep 0.5
                return 0
            elif $error; then
                ui_print "[!] Try re-flash zip again!"
                sleep 0.5
                exit 1
            else
                error=true
                ui_print "[!] Vol key not detected. Try again!"
                sleep 0.5
            fi
        done
    }

    choose() {
        local delay=25
        local error=false
        while true; do
            timeout "$delay" "$KEYCHECK"
            local sel=$?
            if [ $sel -eq 42 ]; then
                return 0
            elif [ $sel -eq 21 ]; then
                return 1
            elif $error; then
                ui_print "[!] Try re-flash zip again!"
                exit 1
            else
                error=true
                ui_print "[!] Vol key not detected. Try again!"
            fi
        done
    }

    chooseold() {
        local delay=25
        local error=false
        while true; do
            local count=0
            while true; do
                timeout "$delay" /system/bin/getevent -lqc 1 2>&1 >"$INSTALLER/events" &
                sleep 0.5
                count=$((count + 1))
                if grep -q 'KEY_VOLUMEUP *DOWN' "$INSTALLER/events"; then
                    return 0
                elif grep -q 'KEY_VOLUMEDOWN *DOWN' "$INSTALLER/events"; then
                    return 1
                fi
                [ $count -gt 25 ] && break
            done
            if $error; then
                ui_print "[!] Try re-flash zip again!"
                "$KEYCHECK"
                exit 1
            else
                error=true
                ui_print "[!] Vol key not detected. Try again!"
            fi
        done
    }

    if [ -z "$NEW" ]; then
        if choosenew; then
            FUNCTION=choose
        else
            FUNCTION=chooseold
            ui_print " "
            ui_print "[!] Vol Key Programming"
            ui_print "[!] Press the volume key + : "
            "$FUNCTION" "UP"
            ui_print "[!] Press the volume key - : "
            "$FUNCTION" "DOWN"
        fi

        sleep 1
        ui_print " "
        ui_print "[!] Select kernel variant:"
        ui_print "    + Volume + = KSU support"
        ui_print "    - Volume - = Non-KSU support"

        if "$FUNCTION"; then
            ui_print "[+] KSU support selected"
            sleep 0.5
            NEW=true
        else
            ui_print "[+] Non-KSU support selected"
            sleep 0.5
            NEW=false
        fi
    else
        ui_print "[!] Try re-flash zip again!"
    fi

    if [ "$NEW" == "true" ]; then
        sleep 1
        ui_print " "
        ui_print "[!] Installing with KSU support..."
        cd "$ksu_dir" || exit 1
        if mv Image_ksu ../../Image && mv dtbo_ksu.img ../../dtbo.img; then
            sleep 1
        else
            sleep 0.5
            ui_print "[!] Error while copying files!"
        fi
    else
        sleep 1
        ui_print " "
        ui_print "[!] Installing w/o KSU support..."
        cd "$stock_dir" || exit 1
        if mv Image_stock ../../Image && mv dtbo_stock.img ../../dtbo.img; then
            sleep 1
        else
            sleep 0.5
            ui_print "[!] Error while copying files!"
        fi
    fi
    ;;
esac

dump_boot;
mount -o rw /data;

if [ ! -d /data/adb/service.d ]; then
mkdir /data/adb;
mkdir /data/adb/service.d;
fi;
replace_file /data/adb/service.d/init.qcom.post_boot.sh 0777 init.qcom.post_boot.sh;
if [ -d $ramdisk/.backup ]; then
  ui_print " "; ui_print "Reinstall Magisk.zip!!!!!...";
  patch_cmdline "skip_override" "skip_override";
else
  patch_cmdline "skip_override" "";
fi;
remove_section init.rc "service flash_recovery" "";
write_boot;

ui_print "[+] Done!"
sleep 1
ui_print " "
ui_print "[!] Wiping dalvik & cache"
rm -rf /data/dalvik-cache/*
ui_print "[+] Done!"
sleep 2

if [ -e "/tmp/recovery.log" ]; then
    if mountpoint -q /external_sd; then
	    mkdir -p /external_sd/logs || exit 1
        logs_location="/external_sd/logs"
    else
    	mkdir -p /sdcard/logs || exit 1
        logs_location="/sdcard/logs"
    fi
    ui_print " "
    ui_print "[!] Backing up recovery.log..."
    BASENAME=$(basename "$ZIPFILE" .zip)
    cp -a /tmp/recovery.log $logs_location/$(date '+%H%M%y%m%d')-"$BASENAME".log || exit 1
    sleep 1
    ui_print "[+] Saved in $logs_location"
    sleep 1
fi

ui_print " "
ui_print "[!] Rebooting in 3 seconds..."
sleep 1
ui_print "[+] -3s..."
sleep 1
ui_print "[+] -2s..."
sleep 1
ui_print "[+] -1s..."
sleep 1
ui_print " "
ui_print "[!] Rebooting now..."
reboot
sleep 3
ui_print " "
ui_print "[!] Something failed. Reboot manually!"