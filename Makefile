.PHONY: catalog check test preview showcase-build showcase-test verify

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
	node --test scripts/catalog.test.mjs

# make preview INPUT=recording.mov COMPONENT=Buttons/PressableButtonStyle
preview:
	sh scripts/make-preview.sh '$(INPUT)' 'Components/$(COMPONENT)/$(notdir $(COMPONENT)).webp'

# pipefail keeps xcodebuild's failure from being hidden by the pipe.
showcase-build:
	( set -o pipefail; $(XCODEBUILD) build $(XCBEAUTIFY) )

showcase-test:
	( set -o pipefail; $(XCODEBUILD) test $(XCBEAUTIFY) )

# Everything that has to pass before a pull request.
verify: check test showcase-test
