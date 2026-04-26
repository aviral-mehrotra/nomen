.PHONY: help generate build run test release clean

help:
	@echo "Targets:"
	@echo "  make generate   Regenerate Nomen.xcodeproj from project.yml"
	@echo "  make build      Debug build into ./build"
	@echo "  make run        Debug build and launch"
	@echo "  make test       Run unit tests"
	@echo "  make release    Sign + notarize + DMG (needs .env, see .env.example)"
	@echo "  make clean      Remove build artifacts and the generated project"

generate:
	xcodegen generate

build: generate
	xcodebuild -project Nomen.xcodeproj -scheme Nomen -configuration Debug \
	           -derivedDataPath build build

run: build
	open build/Build/Products/Debug/Nomen.app

test: generate
	xcodebuild -project Nomen.xcodeproj -scheme Nomen -configuration Debug \
	           -derivedDataPath build -destination 'platform=macOS' test

release:
	./scripts/release.sh

clean:
	rm -rf build Nomen.xcodeproj
