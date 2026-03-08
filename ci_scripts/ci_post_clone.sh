#!/bin/sh
set -e

echo "Setting up Flutter"

# Ensure Flutter dependencies are ready
flutter --version
flutter precache --ios

echo "Installing Dart dependencies"
flutter pub get

echo "Installing CocoaPods"

sudo gem install cocoapods

cd ios
pod repo update
pod install
cd ..

echo "Generating Flutter iOS configuration files"

flutter build ios --debug --no-codesign

echo "Post clone setup complete"
