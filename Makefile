.PHONY: catalog check test preview record docs docs-dev showcase-build showcase-build-mainactor showcase-test verify

PROJECT = Showcase/Showcase.xcodeproj
DESTINATION ?= platform=iOS Simulator,name=iPhone 18 Pro
XCBEAUTIFY := $(if $(shell which xcbeautify),| xcbeautify)
XCODEBUILD = xcodebuild -project $(PROJECT) -scheme Showcase -destination '$(DESTINATION)'

# Rewrites the files generated from the component metadata.
catalog:
	node scripts/catalog.mjs generate

# Fails if a component breaks a rule or a generated file is out of date.
check:
	node scripts/catalog.mjs check

test:
	node --test scripts/catalog.test.mjs scripts/swift-docs.test.mjs

# make preview INPUT=recording.mov COMPONENT=Buttons/PressableButtonStyle
preview:
	sh scripts/make-preview.sh '$(INPUT)' 'Components/$(COMPONENT)/$(notdir $(COMPONENT)).webp'

# make record COMPONENT=Buttons/PressableButtonStyle, or every component without it.
record: showcase-build
	node scripts/record-preview.mjs $(if $(COMPONENT),'$(COMPONENT)')

# Builds the documentation site into docs/dist.
docs:
	node scripts/catalog.mjs docs
	pnpm --dir docs install --frozen-lockfile
	pnpm --dir docs build

docs-dev:
	node scripts/catalog.mjs docs
	pnpm --dir docs install --frozen-lockfile
	pnpm --dir docs dev

# pipefail keeps xcodebuild's failure from being hidden by the pipe.
showcase-build:
	( set -o pipefail; $(XCODEBUILD) build $(XCBEAUTIFY) )

showcase-test:
	( set -o pipefail; $(XCODEBUILD) test $(XCBEAUTIFY) )

# Compiles every component the way a new Xcode project does, with the main actor
# as the default isolation. Its own build folder keeps both builds incremental,
# and the folder is named after the checkout so that two worktrees can build at
# the same time.
MAIN_ACTOR_BUILD = $(HOME)/Library/Developer/Xcode/DerivedData/Showcase-MainActor-$(notdir $(CURDIR))
showcase-build-mainactor:
	( set -o pipefail; $(XCODEBUILD) -derivedDataPath '$(MAIN_ACTOR_BUILD)' build \
		SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor SWIFT_APPROACHABLE_CONCURRENCY=YES $(XCBEAUTIFY) )

# Everything that has to pass before a pull request.
verify: check test showcase-build-mainactor showcase-test
