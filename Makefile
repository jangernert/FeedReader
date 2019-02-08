default: build

builddir:
	meson builddir

build: builddir
	ninja -C builddir

install: build
	ninja -C builddir install

uninstall:
	ninja -C builddir uninstall

test: build
	ninja -C builddir test

.PHONY: build install uninstall test
