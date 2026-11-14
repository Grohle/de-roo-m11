#!/system/bin/sh
# Patch vendor_boot.img with Magisk (tested with 31.1+).
# Runs ON THE TABLET, as root:
#   adb push Magisk-v31.1.apk /data/local/tmp/
#   adb push vendor_boot.img /data/local/tmp/
#   adb push patch-vendor-boot.sh /data/local/tmp/
#   adb shell su -c "sh /data/local/tmp/patch-vendor-boot.sh"
set -e

APK="${1:-/data/local/tmp/Magisk-v31.1.apk}"
IMG="${2:-/data/local/tmp/vendor_boot.img}"
WORK=/data/local/tmp/magisk31

[ -f "$APK" ] || { echo "Missing APK: $APK"; exit 1; }
[ -f "$IMG" ] || { echo "Missing image: $IMG"; exit 1; }

rm -rf "$WORK"
mkdir -p "$WORK"
cd "$WORK"

echo "== extracting Magisk =="
unzip -o "$APK" 'lib/arm64-v8a/*' 'assets/boot_patch.sh' 'assets/util_functions.sh' >/dev/null

cp lib/arm64-v8a/libmagiskboot.so magiskboot
cp lib/arm64-v8a/libmagiskinit.so magiskinit
cp lib/arm64-v8a/libmagisk.so     magisk
cp lib/arm64-v8a/libinit-ld.so    init-ld
[ -f lib/arm64-v8a/libbusybox.so ] && cp lib/arm64-v8a/libbusybox.so busybox
cp assets/boot_patch.sh boot_patch.sh
cp assets/util_functions.sh util_functions.sh

cp "$IMG" vendor_boot.img
chmod 755 *

echo "== patching =="
KEEPVERITY=true sh boot_patch.sh vendor_boot.img

echo
echo "== result =="
ls -l new-boot.img
echo "Pull it with: adb pull $WORK/new-boot.img"
