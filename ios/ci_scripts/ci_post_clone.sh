#!/bin/sh
set -e

# Run from repository root regardless of invocation directory.
REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
cd "$REPO_ROOT"

echo "Installing Flutter SDK"
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
fi
export PATH="$HOME/flutter/bin:$PATH"

flutter --version
flutter precache --ios

echo "Installing Dart dependencies"
flutter pub get

echo "Generating Flutter iOS configuration files"
# This creates ios/Flutter/Generated.xcconfig required by Podfile and xcodebuild.
flutter build ios --config-only --release --no-codesign

echo "Installing CocoaPods"
if ! command -v pod >/dev/null 2>&1; then
  gem install --user-install cocoapods
  GEM_BIN_DIR="$(ruby -e 'print Gem.user_dir')/bin"
  export PATH="$GEM_BIN_DIR:$PATH"
fi

cd ios
pod install --repo-update

echo "Xcode Cloud setup complete"
