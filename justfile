project := "Transmissioner.xcodeproj"
scheme := "Transmissioner"

# Show available recipes with brief descriptions.
_default:
  @just --list

# Build a Debug app bundle.
build:
	xcodebuild -project {{project}} -scheme {{scheme}} -configuration Debug build

# Build and launch the Debug app.
run: build
	APP_PATH=$(xcodebuild -project {{project}} -scheme {{scheme}} -configuration Debug -showBuildSettings | awk -F ' = ' '/TARGET_BUILD_DIR/ {build=$2} /WRAPPER_NAME/ {wrap=$2} END {print build "/" wrap}') && open "$APP_PATH"

# Clean Debug build artifacts.
clean:
	xcodebuild -project {{project}} -scheme {{scheme}} -configuration Debug clean

# Build a Release app bundle.
build-release:
	xcodebuild -project {{project}} -scheme {{scheme}} -configuration Release build

# Bump version, tag, and push (triggers GitHub Actions release). Usage: just release major|minor|patch
release bump:
    #!/usr/bin/env bash
    set -euo pipefail
    next=$(svu {{ bump }})
    echo "Releasing ${next}"
    
    # Update MARKETING_VERSION in project.pbxproj for both Debug and Release configurations
    # Remove the 'v' prefix if present for MARKETING_VERSION (Xcode expects just the version number)
    version_number="${next#v}"
    
    # Update MARKETING_VERSION in both Debug and Release configurations
    # Using a more specific pattern to avoid matching other version strings
    sed -i '' "s/MARKETING_VERSION = [0-9.]*;/MARKETING_VERSION = ${version_number};/g" {{project}}/project.pbxproj
    
    echo "Updated MARKETING_VERSION to ${version_number} in project.pbxproj"
    
    # Verify the change
    if ! grep -q "MARKETING_VERSION = ${version_number};" {{project}}/project.pbxproj; then
        echo "Error: Failed to update MARKETING_VERSION" >&2
        exit 1
    fi
    
    # Commit the version change
    git add {{project}}/project.pbxproj
    git commit -m "Bump version to ${next}"
    
    # Create and push tag
    git tag -a "${next}" -m "Release ${next}"
    git push origin main
    git push origin "${next}"

# Open the Xcode project.
open:
	open {{project}}

# Quit the running app (if any).
stop:
	osascript -e 'tell application "Transmissioner" to quit' >/dev/null 2>&1 || true
	killall Transmissioner >/dev/null 2>&1 || true

# Restart the app (quit if running, then build and launch).
restart: stop run

# Copy the Release build into /Applications.
install: build-release
	APP_PATH=$(xcodebuild -project {{project}} -scheme {{scheme}} -configuration Release -showBuildSettings | awk -F ' = ' '/TARGET_BUILD_DIR/ {build=$2} /WRAPPER_NAME/ {wrap=$2} END {print build "/" wrap}') && cp -R "$APP_PATH" /Applications/

# Build, sign, notarize, and package a Homebrew cask release.
cask-release:
	./scripts/release_cask.sh
