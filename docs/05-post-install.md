# 05 · Post-install: Zygisk, debloat and stores

## Zygisk and DenyList

From the app: **Settings → Zygisk** and **DenyList**. Or from a terminal:

```bash
adb shell su -c 'magisk --sqlite "REPLACE INTO settings (key,value) VALUES(\"zygisk\",1)"'
adb shell su -c 'magisk --sqlite "REPLACE INTO settings (key,value) VALUES(\"denylist\",1)"'
```

Reboot so Zygisk starts.

## Debloat

> ⚠️ **Do NOT uninstall `com.lenovo.penservice`**: it is the **stylus (pen)** service. Do not touch the launcher, main camera, GMS, Play Store, keyboard or telephony either.

### Safe to remove

Google (optional, only if you do not use them):

```
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
```

Lenovo/ZUI:

```
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
```

### Commands

```bash
# uninstall for user 0 (reversible)
adb shell pm uninstall --user 0 <package>

# protected ones refuse to uninstall: disable them
adb shell pm disable-user --user 0 <package>

# check
adb shell pm list packages | grep <package>

# revert
adb shell pm install-existing --user 0 <package>
adb shell pm enable <package>
```

Full list: [`scripts/debloat.sh`](../scripts/debloat.sh).

> Some Lenovo packages **restore themselves** on reboot (`com.lenovo.lsf`, `com.zui.ai.aiservice`). If you want them gone for good, re-apply the `disable-user` on every boot (e.g. from a Magisk module).

## Alternative stores (optional)

- **Aurora Store** (Play Store client): official APK on F-Droid → `https://f-droid.org/repo/com.aurora.store_<versionCode>.apk`. Note that `auroraoss.com` and GitLab return 403/404 for direct downloads from scripts.
- **Orion Store**: <https://github.com/RookieEnough/Orion-Store/releases> (`app-release.apk`).

```bash
adb install -r AuroraStore.apk
adb install -r OrionStore.apk
```

## Important notes

- **Do not update the Magisk app** to a version different from the daemon: the "reinstall Magisk" warning comes back. If you update, re-patch `vendor_boot` with that same version.
- **An OTA overwrites `vendor_boot`** → you lose root (and with an unlocked bootloader the OTA may fail). After an update, repeat step 03.
- The **panel only has one real mode at 90 Hz**: 60/75/30 do not exist as hardware modes (`dumpsys display` shows a single `DisplayMode` at 90.0). Any "60 Hz" you set resolves to 45 (a divisor of the panel).
