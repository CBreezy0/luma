#!/bin/sh
set -e

echo "Installing Flutter SDK"

git clone https://github.com/flutter/flutter.git -b stable --depth 1 $HOME/flutter
export PATH="$HOME/flutter/bin:$PATH"

flutter doctor

echo "Pre-caching iOS artifacts"
flutter precache --ios

echo "Installing Dart dependencies"
flutter pub get

echo "Installing CocoaPods"

sudo gem install cocoapods

cd ios
pod install --repo-update
cd ..

echo "Generating Flutter iOS build configuration"
flutter build ios --debug --no-codesign

echo "Xcode Cloud setup complete"
