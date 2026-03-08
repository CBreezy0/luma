#!/bin/sh
set -e

echo "Installing Flutter SDK"

if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
fi
export PATH="$HOME/flutter/bin:$PATH"

flutter doctor

echo "Pre-caching iOS artifacts"
flutter precache --ios

echo "Installing Dart dependencies"
flutter pub get

echo "Generating Flutter iOS configuration files"
# Generates ios/Flutter/Generated.xcconfig before CocoaPods runs.
flutter build ios --config-only --release --no-codesign

echo "Installing CocoaPods"
if ! command -v pod >/dev/null 2>&1; then
  sudo gem install cocoapods
fi

cd ios
pod install --repo-update
cd ..

echo "Validating Flutter iOS build setup"
flutter build ios --debug --no-codesign

echo "Xcode Cloud setup complete"
