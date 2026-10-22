PROJECT := DuoLab.xcodeproj
SCHEME  := DuoLab
DEVICE  ?= iPhone Duo
BUNDLE  := com.klab.DuoLab
DERIVED := build

.PHONY: generate build run clean

# 소스 파일 추가/삭제 시 xcodeproj 재생성
generate:
	xcodegen generate

# DEVICE="iPhone 18 Pro Max" make build 처럼 시뮬레이터를 바꿀 수 있다
build: generate
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug \
		-destination 'platform=iOS Simulator,name=$(DEVICE)' \
		-derivedDataPath $(DERIVED) -quiet build

run: build
	xcrun simctl boot "$(DEVICE)" 2>/dev/null || true
	xcrun simctl install "$(DEVICE)" $(DERIVED)/Build/Products/Debug-iphonesimulator/DuoLab.app
	xcrun simctl launch "$(DEVICE)" $(BUNDLE)

clean:
	rm -rf $(DERIVED)
