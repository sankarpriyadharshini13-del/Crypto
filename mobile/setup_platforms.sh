#!/usr/bin/env bash
# Generates android/ios folders (this repo ships only lib/ + pubspec) and allows plain-HTTP to a dev backend.
set -e
flutter create --org com.cryptopulse --platforms=android,ios --project-name crypto_pulse .
MANIFEST=android/app/src/main/AndroidManifest.xml
if ! grep -q usesCleartextTraffic "$MANIFEST"; then
  sed -i 's#<application#<application android:usesCleartextTraffic="true"#' "$MANIFEST"
fi
if ! grep -q "android.permission.INTERNET" "$MANIFEST"; then
  sed -i 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <application#' "$MANIFEST"
fi
flutter pub get
echo "Done. For iOS dev over HTTP add an NSAppTransportSecurity exception in ios/Runner/Info.plist (or use HTTPS)."
