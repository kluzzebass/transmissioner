#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "$ROOT_DIR/.env" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT_DIR/.env"
fi
PROJECT="${PROJECT:-Transmissioner.xcodeproj}"
SCHEME="${SCHEME:-Transmissioner}"
CONFIGURATION="${CONFIGURATION:-Release}"

SIGN_IDENTITY="${SIGN_IDENTITY:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
GITHUB_REPO="${GITHUB_REPO:-}"
SKIP_NOTARIZE="${SKIP_NOTARIZE:-0}"

if [[ -z "$SIGN_IDENTITY" ]]; then
  echo "SIGN_IDENTITY is required (e.g. 'Developer ID Application: Your Name (TEAMID)')." >&2
  exit 1
fi

if [[ -z "$GITHUB_REPO" ]]; then
  echo "GITHUB_REPO is required (e.g. 'kluzzebass/transmissioner')." >&2
  exit 1
fi

if [[ "$SKIP_NOTARIZE" != "1" && -z "$NOTARY_PROFILE" ]]; then
  echo "NOTARY_PROFILE is required unless SKIP_NOTARIZE=1." >&2
  exit 1
fi

echo "Building Release..."
xcodebuild -project "$ROOT_DIR/$PROJECT" -scheme "$SCHEME" -configuration "$CONFIGURATION" build

APP_PATH="$(
  xcodebuild -project "$ROOT_DIR/$PROJECT" -scheme "$SCHEME" -configuration "$CONFIGURATION" -showBuildSettings \
    | awk -F ' = ' '/TARGET_BUILD_DIR/ {build=$2} /WRAPPER_NAME/ {wrap=$2} END {print build "/" wrap}'
)"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Built app not found at $APP_PATH" >&2
  exit 1
fi

INFO_PLIST="$APP_PATH/Contents/Info.plist"
VERSION="$(
  /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST"
)"
BUILD="$(
  /usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST"
)"

DIST_DIR="$ROOT_DIR/dist"
mkdir -p "$DIST_DIR"

ZIP_NAME="Transmissioner-${VERSION}-${BUILD}.zip"
ZIP_PATH="$DIST_DIR/$ZIP_NAME"

echo "Signing app..."
codesign --deep --force --options runtime --sign "$SIGN_IDENTITY" "$APP_PATH"
codesign --verify --deep --strict "$APP_PATH"
spctl --assess --type execute --verbose "$APP_PATH" || true

echo "Packaging zip..."
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

if [[ "$SKIP_NOTARIZE" != "1" ]]; then
  echo "Notarizing..."
  xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  echo "Stapling..."
  xcrun stapler staple "$APP_PATH"
fi

SHA256="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"

echo ""
echo "Release artifacts:"
echo "  App: $APP_PATH"
echo "  Zip: $ZIP_PATH"
echo "  Version: $VERSION ($BUILD)"
echo "  SHA256: $SHA256"
echo ""

cat > "$DIST_DIR/cask.rb" <<EOF
cask "transmissioner" do
  version "$VERSION,$BUILD"
  sha256 "$SHA256"

  url "https://github.com/$GITHUB_REPO/releases/download/v#{version.before_comma}/$ZIP_NAME"
  name "Transmissioner"
  desc "Menu bar Transmission client for macOS"
  homepage "https://github.com/$GITHUB_REPO"

  app "Transmissioner.app"
end
EOF

echo "Cask snippet written to $DIST_DIR/cask.rb"
