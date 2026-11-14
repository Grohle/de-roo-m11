#!/system/bin/sh
# Magisk ACTION button: cycle balanced -> fluid -> aggressive.
M=/data/adb/modules/tb330fu-perf
D=/data/adb/tb330fu-perf
CFG="$D/profile"
mkdir -p "$D"

CUR=$(cat "$CFG" 2>/dev/null | tr -d ' \r\n')
[ -z "$CUR" ] && CUR=fluid

case "$CUR" in
  balanced)   NEW=fluid ;;
  fluid)      NEW=aggressive ;;
  aggressive) NEW=balanced ;;
  *)          NEW=fluid ;;
esac

echo "$NEW" > "$CFG"

OUT=$(sh "$M/perf-apply.sh" late 2>&1)
RC=$?
if [ $RC -ne 0 ]; then
  OUT=$(su -t 0 0 -c "sh $M/perf-apply.sh late" 2>&1)
fi

echo "Profile: $CUR -> $NEW"
echo "$OUT"
