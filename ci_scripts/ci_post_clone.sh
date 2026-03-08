#!/bin/sh
set -e

echo "Installing Flutter dependencies"
flutter pub get

echo "Generating Flutter iOS build files"
flutter build ios --debug --no-codesign

echo "Installing CocoaPods"

sudo gem install cocoapods

cd ios
pod install --repo-update
cd ..

echo "Post clone setup complete"
