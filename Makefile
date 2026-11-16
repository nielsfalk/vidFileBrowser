PROJECT := VidFileBrowser.xcodeproj
SCHEME := VidFileBrowser
DERIVED_DATA := build
HOOKS := commit-msg pre-push git-hooks-lib.sh

ARCHIVE := build/VidFileBrowser.xcarchive
RELEASE_APP := $(ARCHIVE)/Products/Applications/VidFileBrowser.app
DIST := dist
DMG := $(DIST)/VidFileBrowser.dmg
ENTITLEMENTS := VidFileBrowser/VidFileBrowser.entitlements

.PHONY: generate build test run clean installHooks release sign notarize dmg dist

generate:
	xcodegen generate

build: generate
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug \
		-derivedDataPath $(DERIVED_DATA) build

test: generate
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug \
		-destination 'platform=macOS' -derivedDataPath $(DERIVED_DATA) test

run: build
	open $(DERIVED_DATA)/Build/Products/Debug/VidFileBrowser.app

clean:
	rm -rf $(DERIVED_DATA) $(PROJECT)

installHooks:
	@mkdir -p .git/hooks
	@for hook in $(HOOKS); do \
		install -m 755 scripts/git-hooks/$$hook .git/hooks/$$hook; \
		echo "installed .git/hooks/$$hook"; \
	done

# Distribution. Signing needs a Developer ID certificate and a notarytool
# keychain profile created with:
#   xcrun notarytool store-credentials "$NOTARY_PROFILE" --apple-id ... --team-id ... --password ...
release: generate
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release \
		-destination 'platform=macOS' -archivePath $(ARCHIVE) archive

sign:
	@test -n "$(DEVELOPER_ID)" || (echo "set DEVELOPER_ID=\"Developer ID Application: ...\"" >&2; exit 1)
	codesign --force --deep --options runtime --timestamp \
		--entitlements $(ENTITLEMENTS) --sign "$(DEVELOPER_ID)" "$(RELEASE_APP)"
	codesign --verify --deep --strict --verbose=2 "$(RELEASE_APP)"

notarize:
	@test -n "$(NOTARY_PROFILE)" || (echo "set NOTARY_PROFILE to a notarytool keychain profile" >&2; exit 1)
	@test -d "$(RELEASE_APP)" || (echo "run make release sign first" >&2; exit 1)
	zip -qry build/VidFileBrowser.zip "$(RELEASE_APP)"
	xcrun notarytool submit build/VidFileBrowser.zip --keychain-profile "$(NOTARY_PROFILE)" --wait
	xcrun stapler staple "$(RELEASE_APP)"

dmg:
	@test -d "$(RELEASE_APP)" || (echo "run make release first" >&2; exit 1)
	mkdir -p $(DIST)
	rm -f $(DMG)
	hdiutil create -volname VidFileBrowser -srcfolder "$(RELEASE_APP)" -ov -format UDZO $(DMG)

dist: release sign notarize dmg
