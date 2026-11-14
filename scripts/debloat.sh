#!/bin/bash
# TB330FU debloat. Does NOT touch the stylus (com.lenovo.penservice) or critical parts.
# Usage: ./debloat.sh
# Revert: pm install-existing --user 0 <pkg>  /  pm enable <pkg>
set -u

ADB="${ADB:-adb}"

# --- Google (remove only what you don't use) ---
GOOGLE="
com.google.android.youtube
com.google.android.apps.youtube.music
com.google.android.videos
com.google.android.apps.maps
com.google.android.apps.photos
com.google.android.apps.docs
com.google.android.apps.tachyon
com.google.android.apps.wellbeing
com.google.android.apps.kids.home
com.google.android.apps.mediahome.launcher
com.google.android.apps.googleassistant
com.google.android.googlequicksearchbox
com.android.hotwordenrollment.okgoogle
com.android.hotwordenrollment.xgoogle
com.google.android.apps.turbo
com.google.android.as
"

# --- Lenovo / ZUI ---
# IMPORTANT: com.lenovo.penservice is intentionally NOT here (stylus support)
LENOVO="
com.lenovo.lsf
com.lenovo.lsf.device
com.lenovo.ue.device
com.lenovo.ocpl
com.lenovo.rt
com.lenovo.dsa
com.lenovo.screensaver
com.lenovo.weathercenter
com.lenovo.tab_m11
com.lenovo.EngineeringCode
com.tblenovo.center
com.tblenovo.lenovowhatsnew
com.tblenovo.setup
com.tblenovo.tabpushout
com.tblenovo.ue.config
com.zui.ai.aiservice
com.zui.camera.assistant
com.zui.camera.qr
com.zui.keyboardupdate
com.zui.keyboardupdate.olympia
com.zui.pp
com.zui.wifip2p
com.zui.udevice
com.motorola.demo
com.motorola.mobiledesktop
com.motorola.mobiledesktop.core
com.motorola.readyforsignature.app
com.aura.oobe.lenovo
com.opera.preinstall
com.lmsa.app.lmsapad
com.debug.loggerui
com.mediatek.voicecommand
com.android.bookmarkprovider
com.android.providers.partnerbookmarks
com.android.providers.partnerbrowsercustomizations
com.android.dreams.basic
"

apply() {
  for p in $1; do
    if $ADB shell pm list packages | grep -qx "package:$p"; then
      $ADB shell pm uninstall --user 0 "$p" >/dev/null 2>&1
      if $ADB shell pm list packages | grep -qx "package:$p"; then
        $ADB shell pm disable-user --user 0 "$p" >/dev/null 2>&1 && echo "disabled   $p" || echo "unchanged  $p"
      else
        echo "uninstalled $p"
      fi
    fi
  done
}

echo "== Google =="
apply "$GOOGLE"
echo "== Lenovo/ZUI =="
apply "$LENOVO"

echo
echo "Stylus check (must still be present):"
$ADB shell pm list packages | grep -i penservice || echo "  !! WARNING: penservice not found"
