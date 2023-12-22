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
        backup_location="/external_sd/backup_boot.img"
        ui_print "[!] Backing up boot in external SDCard..."
    else
        backup_location="/sdcard/backup_boot.img"
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
    backup_location="/sdcard/backup_boot.img"
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


if [ -e "/tmp/recovery.log" ]; then
    ui_print "[+] Done!"
    mkdir -p /sdcard/logs
    ui_print " "
    ui_print "[!] Backing up recovery.log..."
    BASENAME=$(basename "$ZIPFILE" .zip)
    cp -a /tmp/recovery.log /sdcard/logs/$(date '+%H%M%y%m%d')-"$BASENAME".log
    sleep 2
    ui_print "[+] Saved in sdcard/logs/."
    sleep 0.5
    ui_print " "
    ui_print "[!] Rebooting in 3 seconds..."
    sleep 0.5
    ui_print "    -3s..."
    sleep 0.5
    ui_print "    -2s..."
    sleep 0.5
    ui_print "    -1s..."
    sleep 0.5
    ui_print " "
    ui_print "[!] Rebooting now..."
    reboot
    sleep 3
    ui_print " "
    ui_print "[!] Something failed. Reboot manually..."
fi