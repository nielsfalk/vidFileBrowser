PROJECT := VidFileBrowser.xcodeproj
SCHEME := VidFileBrowser
DERIVED_DATA := build
HOOKS := commit-msg pre-push git-hooks-lib.sh

.PHONY: generate build test run clean installHooks

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
