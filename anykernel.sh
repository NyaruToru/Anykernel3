 # AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

#1 Sat Mar 2 11:38:26 +07 2024

## AnyKernel setup
# begin properties
properties() { '
kernel.string=Strawberry for Poco X3 (NFC) by Telegram@NyaruToru
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