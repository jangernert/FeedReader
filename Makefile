BUILDDIR := builddir

default: build

$(BUILDDIR):
	meson $(BUILDDIR)

build: $(BUILDDIR)
	ninja -C $(BUILDDIR)

test: $(BUILDDIR)
	ninja -C $(BUILDDIR) test

install: build
	ninja -C $(BUILDDIR) install

.PHONY: build test install default
