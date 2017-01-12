PACKAGE   = feedreader
JSON	  = org.gnome.feedreader.json
ARCH	  = x86_64
BRANCH	  = master
VERSION   = $(BRANCH)-` date +"%Y%m%d" `
BUNDLE 	  = $(PACKAGE)-$(VERSION).$(ARCH)

all:
	rm -rf $(PACKAGE)
	flatpak-builder --force-clean --repo=repo $(PACKAGE) $(JSON)
dist:
	flatpak build-bundle repo/ $(BUNDLE).flatpak org.gnome.$(PACKAGE) $(BRANCH)
