include Makefile.config

all: test

test: repo ${JSON}
	flatpak-builder --force-clean --repo=repo --ccache --require-changes ${PACKAGE} ${JSON}
	flatpak build-update-repo repo

release: release-repo ${JSON} feedreader.flatpakref feedreader.flatpakrepo
	if [ "x${RELEASE_GPG_KEY}" == "x" ]; then echo Must set RELEASE_GPG_KEY in Makefile.config, try \'make gpg-key\'; exit 1; fi
	flatpak-builder --force-clean --repo=release-repo  --ccache --gpg-homedir=gpg --gpg-sign=${RELEASE_GPG_KEY} ${PACKAGE} ${JSON}
	flatpak build-update-repo --generate-static-deltas --gpg-homedir=gpg --gpg-sign=${RELEASE_GPG_KEY} release-repo

rsync-release:
	cp feedreader.flatpakrepo release-repo/
	cp feedreader.flatpakref release-repo/
	rsync -avh --update release-repo/ ${SSH_USER}:${RSYNC_PATH}

repo:
	ostree init --mode=archive-z2 --repo=repo

release-repo:
	ostree init --mode=archive-z2 --repo=release-repo

gpg-key:
	if [ "x${KEY_USER}" == "x" ]; then echo Must set KEY_USER in Makefile.config; exit 1; fi
	mkdir -p gpg
	gpg2 --homedir gpg --quick-gen-key ${KEY_USER}
	echo Enter the above gpg key id as RELEASE_GPG_KEY in Makefile.config

${JSON}: ${JSON}.in
	sed -e 's|@BRANCH@|${BRANCH}|g' -e 's|@RUNTIME_VERSION@|${RUNTIME_VERSION}|g' -e 's|@GIT@|${GIT}|' $< > $@

feedreader.flatpakref: feedreader.flatpakref.in
	sed -e 's|@URL@|${URL}|g' -e 's|@BRANCH@|${BRANCH}|g' -e 's|@GPG@|$(shell gpg2 --homedir=gpg --export ${RELEASE_GPG_KEY} | base64 | tr -d '\n')|' $< > $@

feedreader.flatpakrepo: feedreader.flatpakrepo.in
	sed -e 's|@URL@|${URL}|g' -e 's|@GPG@|$(shell gpg2 --homedir=gpg --export ${RELEASE_GPG_KEY} | base64 | tr -d '\n')|' $< > $@

bundle: test
	flatpak build-bundle repo/ ${BUNDLE}.flatpak org.gnome.${PACKAGE} ${BRANCH}


	
