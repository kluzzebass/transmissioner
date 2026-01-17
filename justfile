project := "Transmissioner.xcodeproj"
scheme := "Transmissioner"
destination := "platform=macOS"

default: build

build:
	xcodebuild -project {{project}} -scheme {{scheme}} -configuration Debug -destination '{{destination}}' build

run: build
	APP_PATH=$$(xcodebuild -project {{project}} -scheme {{scheme}} -configuration Debug -showBuildSettings | awk -F' = ' '/TARGET_BUILD_DIR/ {build=$$2} /WRAPPER_NAME/ {wrap=$$2} END {print build "/" wrap}') && open "$$APP_PATH"

clean:
	xcodebuild -project {{project}} -scheme {{scheme}} -configuration Debug -destination '{{destination}}' clean

release:
	xcodebuild -project {{project}} -scheme {{scheme}} -configuration Release -destination '{{destination}}' build

open:
	open {{project}}

install: release
	APP_PATH=$$(xcodebuild -project {{project}} -scheme {{scheme}} -configuration Release -showBuildSettings | awk -F' = ' '/TARGET_BUILD_DIR/ {build=$$2} /WRAPPER_NAME/ {wrap=$$2} END {print build "/" wrap}') && cp -R "$$APP_PATH" /Applications/
