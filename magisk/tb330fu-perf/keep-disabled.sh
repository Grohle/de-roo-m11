#!/system/bin/sh
# Packages that Lenovo/ZUI restores on boot. Re-applied on every start.
# NOTE: com.lenovo.penservice (stylus) is deliberately NOT here.
PKGS="
com.lenovo.lsf
com.lenovo.lsf.device
com.lenovo.ue.device
com.lenovo.ocpl
com.lenovo.rt
com.lenovo.dsa
com.lenovo.weathercenter
com.tblenovo.center
com.tblenovo.tabpushout
com.tblenovo.ue.config
com.zui.ai.aiservice
com.zui.camera.assistant
com.zui.camera.qr
com.zui.pp
com.zui.wifip2p
com.zui.udevice
com.motorola.demo
com.google.android.as
com.google.android.apps.turbo
"

for p in $PKGS; do
  if pm list packages | grep -qx "package:$p"; then
    pm disable-user --user 0 "$p" >/dev/null 2>&1 && echo "disabled $p" || echo "failed $p"
  fi
done
