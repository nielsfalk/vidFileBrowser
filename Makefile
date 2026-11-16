PROJECT := VidFileBrowser.xcodeproj
SCHEME := VidFileBrowser
DERIVED_DATA := build

.PHONY: generate build run clean

generate:
	xcodegen generate

build: generate
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug \
		-derivedDataPath $(DERIVED_DATA) build

run: build
	open $(DERIVED_DATA)/Build/Products/Debug/VidFileBrowser.app

clean:
	rm -rf $(DERIVED_DATA) $(PROJECT)
