#!/bin/bash
# Partition backup over BROM with mtkclient (Linux).
# Usage: ./dump-backup.sh /path/to/mtkclient [/path/to/dump]
set -u
MTK="${1:-$PWD/mtkclient}"
OUT="${2:-$PWD/dump}"

mkdir -p "$OUT"
cd "$MTK" || exit 1

echo "Power the tablet OFF, hold Vol+ and Vol- and plug the USB cable (BROM)."
echo "You should see 0e8d:0003 in lsusb."
read -r -p "Press ENTER when ready..."

# NOTE: ';' separators WITHOUT spaces (mtkclient splits by ';' then by ' ')
python3 mtk.py multi "r seccfg $OUT/seccfg.bin;\
r proinfo $OUT/proinfo.bin;\
r nvdata $OUT/nvdata.bin;\
r nvram $OUT/nvram.bin;\
r persist $OUT/persist.bin;\
r lk_a $OUT/lk_a.bin;\
r lk_b $OUT/lk_b.bin;\
r vbmeta_a $OUT/vbmeta_a.bin;\
r vbmeta_b $OUT/vbmeta_b.bin;\
r boot_a $OUT/boot_a.bin;\
r boot_b $OUT/boot_b.bin;\
r vendor_boot_a $OUT/vendor_boot_a.bin;\
r vendor_boot_b $OUT/vendor_boot_b.bin"

echo "Backup in: $OUT"
ls -l "$OUT"
