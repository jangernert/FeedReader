PACKAGE   = FeedReader
VERSION	  = 2.0-dev
JSON	  = org.gnome.FeedReader.json
ARCH	  = x86_64
BRANCH	  = master
GIT	  = master
BUILD     = $(GIT)-` date +"%Y%m%d" `
BUNDLE 	  = $(PACKAGE)-$(BUILD)-$(VERSION).$(ARCH)

all:
	rm -rf $(PACKAGE)
	if [ x$(ARCH) != x`uname -p` -a ! -z "$(ARCH)" ]; then						\
		ARCH_OPT="--arch=$(ARCH)" ;								\
	fi ;												\
	JSON=$(JSON) ;											\
	if [ $(GIT) != "master" ]; then									\
		NEW_JSON=`basename $(JSON) .json`-$(GIT).json ;						\
		cat $(JSON) | sed -e 's!"branch": "master"!"branch": "$(BRANCH)"!' | sed -e 's!"url": "https://github.com/jangernert/FeedReader.git"!"url": "https://github.com/jangernert/FeedReader.git", "branch": "$(GIT)"!' > $$NEW_JSON ; \
		JSON=$$NEW_JSON ;									\
	fi ;												\
	flatpak-builder $$ARCH_OPT --ccache --force-clean --repo=repo $(PACKAGE) $$JSON

dist:
	if [ x$(ARCH) != x`uname -p` -a ! -z "$(ARCH)" ]; then						\
		ARCH_OPT="--arch=$(ARCH)" ;								\
	fi ;												\
	flatpak build-bundle $$ARCH_OPT repo/ $(BUNDLE).flatpak org.gnome.$(PACKAGE) $(BRANCH)		
