
test:
	zig build test

optimize = Debug

build:
	zig build -Doptimize=$(optimize)

build-release-linux: 
	zig build-exe -fstrip -target x86_64-linux-gnu -O ReleaseFast --name zentropy-linux ./src/main.zig

build-release-macos: 
	zig build-exe -fstrip -target x86_64-macos -O ReleaseFast --name zentropy-macos ./src/main.zig

build-release-linux: 
	zig build-exe -fstrip -target x86_64-windows-gnu -O ReleaseFast --name zentropy-windows ./src/main.zig

build-releases: build-release-linux build-release-macos build-release-windows 

release: build-releases 
	gh release create $$(git describe --abbrev=0) \
		--generate-notes \
    zentropy-linux \
    zentropy-macos \
    zentropy-windows.exe

.PHONY: build build-release-linux build-release-macos build-release-windows build-releases release test
