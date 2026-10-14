#!/usr/bin/env bash
# Configure le projet iOS généré par "npx cap add ios" (exécuté sur le Mac de Codemagic).
set -euo pipefail

APP_DIR="ios/App/App"
PLIST="$APP_DIR/Info.plist"
PB=/usr/libexec/PlistBuddy

set_plist () { # clé, type, valeur
  $PB -c "Delete :$1" "$PLIST" 2>/dev/null || true
  $PB -c "Add :$1 $2 $3" "$PLIST"
}

echo "▶ Info.plist"
set_plist CFBundleDisplayName string "EnfinToi"
set_plist CFBundleDevelopmentRegion string "fr"
set_plist ITSAppUsesNonExemptEncryption bool false
set_plist NSCameraUsageDescription string "EnfinToi utilise l'appareil photo pour prendre vos photos de profil et le selfie de certification."
set_plist NSPhotoLibraryUsageDescription string "EnfinToi accède à vos photos pour que vous puissiez choisir les photos de votre profil."
set_plist NSPhotoLibraryAddUsageDescription string "EnfinToi peut enregistrer des images dans vos photos à votre demande."
set_plist NSLocationWhenInUseUsageDescription string "EnfinToi utilise votre position (arrondie) pour vous proposer des profils proches de chez vous."
$PB -c "Delete :UIBackgroundModes" "$PLIST" 2>/dev/null || true
$PB -c "Add :UIBackgroundModes array" "$PLIST"
$PB -c "Add :UIBackgroundModes:0 string remote-notification" "$PLIST"
$PB -c "Delete :UIRequiresFullScreen" "$PLIST" 2>/dev/null || true
$PB -c "Add :UIRequiresFullScreen bool true" "$PLIST"
$PB -c "Delete :UISupportedInterfaceOrientations" "$PLIST" 2>/dev/null || true
$PB -c "Add :UISupportedInterfaceOrientations array" "$PLIST"
$PB -c "Add :UISupportedInterfaceOrientations:0 string UIInterfaceOrientationPortrait" "$PLIST"

echo "▶ Entitlements (notifications push)"
cat > "$APP_DIR/App.entitlements" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>aps-environment</key>
	<string>production</string>
</dict>
</plist>
XML

echo "▶ AppDelegate (transmission du jeton push à Capacitor)"
python3 - <<'PY'
import pathlib
p = pathlib.Path("ios/App/App/AppDelegate.swift")
s = p.read_text()
if "capacitorDidRegisterForRemoteNotifications" not in s:
    add = '''
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationCenter.default.post(name: .capacitorDidRegisterForRemoteNotifications, object: deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NotificationCenter.default.post(name: .capacitorDidFailToRegisterForRemoteNotifications, object: error)
    }
'''
    i = s.rstrip().rfind("}")
    s = s[:i] + add + "}\n"
    p.write_text(s)
PY

echo "▶ Projet Xcode : entitlements, iPhone seul, iOS 15+"
gem list -i xcodeproj >/dev/null 2>&1 || gem install xcodeproj --no-document
ruby - <<'RB'
require 'xcodeproj'
proj = Xcodeproj::Project.open('ios/App/App.xcodeproj')
group = proj.main_group.find_subpath('App', true)
group.new_reference('App.entitlements') unless group.files.any? { |f| f.path == 'App.entitlements' }
proj.targets.each do |t|
  next unless t.name == 'App'
  t.build_configurations.each do |c|
    c.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'App/App.entitlements'
    c.build_settings['TARGETED_DEVICE_FAMILY'] = '1'
    c.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    c.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.enfintoi.app'
    c.build_settings['INFOPLIST_KEY_CFBundleDisplayName'] = 'EnfinToi'
  end
end
proj.save
RB

echo "✔ Projet iOS configuré"
