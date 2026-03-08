#!/bin/sh
set -e

echo "Installing Flutter dependencies"

flutter pub get

echo "Generating Flutter iOS build files"

flutter build ios --debug --no-codesign

echo "Installing CocoaPods"

cd ios
pod install
cd ..

echo "Post-clone setup complete"
