PACKAGE   = FeedReader
JSON	  = org.gnome.FeedReader.json
ARCH	  = x86_64
BRANCH	  = master
VERSION   = $(BRANCH)-` date +"%Y%m%d" `
BUNDLE 	  = $(PACKAGE)-$(VERSION).$(ARCH)

all:
	rm -rf $(PACKAGE)
	if [ x$(ARCH) != x`uname -p` -a ! -z "$(ARCH)" ]; then			\
		ARCH_OPT="--arch=$(ARCH)" ;					\
	fi ;									\
	JSON=$(JSON) ;								\
	if [ $(BRANCH) != "master" ]; then					\
		NEW_JSON=`basename $(JSON) .json`-$(BRANCH).json ;		\
		cat $(JSON) | sed -e 's!"url": "https://github.com/jangernert/FeedReader.git"!"url": "https://github.com/jangernert/FeedReader.git", "branch": "$(BRANCH)"!' > $$NEW_JSON ;	\
		JSON=$$NEW_JSON ;						\
	fi ;									\
	flatpak-builder $$ARCH_OPT --ccache --force-clean --repo=repo $(PACKAGE) $$JSON

dist:
	if [ x$(ARCH) != x`uname -p` -a ! -z "$(ARCH)" ]; then			\
		ARCH_OPT="--arch=$(ARCH)" ;					\
	fi ;									\
	flatpak build-bundle $$ARCH_OPT repo/ $(BUNDLE).flatpak org.gnome.$(PACKAGE) $(BRANCH)
