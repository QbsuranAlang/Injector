#!/bin/bash

REPOROOT=$(pwd)

vAPP=2.5.2
vDaemon=1.0-1
vPreferenceLoader=1.0-1
vForeground=1.0-1
vUploader=1.0-1

APP=tw.edu.mcu.cce.nrl.Injector_${vAPP}_iphoneos-arm.deb
DAEMON=tw.edu.mcu.cce.nrl.InjectorDaemon_${vDaemon}_iphoneos-arm.deb
PREFERENCELOADER=tw.edu.mcu.cce.nrl.InjectorPreferenceLoader_${vPreferenceLoader}_iphoneos-arm.deb
FOREGROUND=tw.edu.mcu.cce.nrl.InjectorForeground_${vForeground}_iphoneos-arm.deb
UPLOADER=tw.edu.mcu.cce.nrl.InjectorUploader_${vUploader}_iphoneos-arm.deb

rm -rf Release/
mkdir Release

echo -e "Extracting...\n"
# extract daemon
dpkg-deb -x InjectorDaemon/Packages/${DAEMON} ${REPOROOT}/Release/daemon
dpkg-deb -e InjectorDaemon/Packages/${DAEMON} ${REPOROOT}/Release/daemon/DEBIAN

# extract PreferenceLoader
dpkg-deb -x InjectorPreferenceLoader/Packages/${PREFERENCELOADER} ${REPOROOT}/Release/preference
dpkg-deb -e InjectorPreferenceLoader/Packages/${PREFERENCELOADER} ${REPOROOT}/Release/preference/DEBIAN

# extract foreground
dpkg-deb -x InjectorForeground/Packages/${FOREGROUND} ${REPOROOT}/Release/foreground
dpkg-deb -e InjectorForeground/Packages/${FOREGROUND} ${REPOROOT}/Release/foreground/DEBIAN

# extract uploader
dpkg-deb -x InjectorUploader/Packages/${UPLOADER} ${REPOROOT}/Release/uploader
dpkg-deb -e InjectorUploader/Packages/${UPLOADER} ${REPOROOT}/Release/uploader/DEBIAN

# extract app
dpkg-deb -x InjectorApp/Packages/${APP} ${REPOROOT}/Release/app
dpkg-deb -e InjectorApp/Packages/${APP} ${REPOROOT}/Release/app/DEBIAN


# move files
echo -e "Moving files...\n"
cd Release

#make dir
mkdir -p app/Library/PreferenceBundles
mkdir -p app/Library/PreferenceLoader/Preferences
mkdir -p app/Library/LaunchDaemons
mkdir -p app/var/mobile/Library/Preferences


#move preference
mv preference/Library/PreferenceBundles/InjectorPreferenceLoader.bundle app/Library/PreferenceBundles/InjectorPreferenceLoader.bundle
mv preference/Library/PreferenceLoader/Preferences/InjectorPreferenceLoader.plist app/Library/PreferenceLoader/Preferences/InjectorPreferenceLoader.plist
mv preference/var/mobile/Library/Preferences/tw.edu.mcu.cce.nrl.InjectorPreferenceLoader.plist app/var/mobile/Library/Preferences/tw.edu.mcu.cce.nrl.InjectorPreferenceLoader.plist
#move foreground
mv foreground/usr/sbin/InjectorForeground app/Applications/Injector.app/InjectorForeground
#move daemon
mv daemon/Library/LaunchDaemons/tw.edu.mcu.cce.nrl.InjectorDaemon.plist app/Library/LaunchDaemons/tw.edu.mcu.cce.nrl.InjectorDaemon.plist
mv daemon/Library/LaunchDaemons/tw.edu.mcu.cce.nrl.InjectorKillDaemon.plist app/Library/LaunchDaemons/tw.edu.mcu.cce.nrl.InjectorKillDaemon.plist
mv daemon/usr/sbin/InjectorDaemon app/Applications/Injector.app/InjectorDaemon
#move uploader
mv uploader/Library/LaunchDaemons/tw.edu.mcu.cce.nrl.InjectorUploader.plist app/Library/LaunchDaemons/tw.edu.mcu.cce.nrl.InjectorUploader.plist
mv uploader/usr/sbin/InjectorUploader app/Applications/Injector.app/InjectorUploader

#copy the icon on cydia
cp ../App\ Icon\ \[Rounded\]/Icon-Small-50@2x.png app/Applications/Injector.app/CydiaIcon.png

echo "Re-codesigning..."
# create a entitlements.plist
cont=`cat <<"EOF"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>com.apple.locationd.effective_bundle</key>
<true/>
<key>com.apple.locationd.authorizeapplications</key>
<true/>
<key>com.apple.locationd.preauthorized</key>
<true/>
<key>com.apple.wifi.manager-access</key>
<true/>
<key>keychain-access-groups</key>
<array>
<string>apple</string>
<string>com.apple.preferences</string>
</array>
</dict>
</plist>
EOF
`
echo -e "$cont" > entitlements.plist

#re-codesign
codesign -f -s "iPhone Developer" -i tw.edu.mcu.cce.nrl.Injector --entitlements entitlements.plist -vv ./app/Applications/Injector.app/

echo -e "\nPackaging..."
# create deb, daemon and preferenceloadr
dpkg-deb -b -Zgzip 'app' ${APP}

echo -e "\nDeleting files...\n"
#rm -rf agent/
rm -rf daemon/
rm -rf preference/
rm -rf foreground/
rm -rf app/
rm -rf uploader/
rm -f entitlements.plist

echo "Done!"

