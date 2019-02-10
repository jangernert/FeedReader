FROM docker.io/fedora:29

RUN dnf -y install \
        gcc \
        gettext \
        git \
        gnome-online-accounts-devel \
        gstreamer1-devel \
        gstreamer1-plugins-base-devel \
        gtk3-devel \
        gumbo-parser-devel \
        json-glib-devel \
        libappstream-glib \
        libcurl-devel \
        libgee-devel \
        libnotify-devel \
        libpeas-devel \
        libsecret-devel \
        libsoup-devel \
        libxml2-devel \
        meson \
        rest-devel \
        sqlite-devel \
        vala \
        webkitgtk4-devel \
        appstream \
        desktop-file-utils \
        libunity-devel

# Install Feedbin
# Note: Some dependencies are duplicates of above, but it's easier to maintain if
# we use the exact list here: https://github.com/feedbin/feedbin/blob/master/doc/INSTALL-fedora.md
# TODO: Run Feedbin in its own container
RUN dnf -y install \
		gcc \
		gcc-c++ \
		git \
		libcurl-devel \
		libidn-devel \
		libxml2-devel \
		libxslt-devel \
		make \
		nodejs \
		postgresql \
		postgresql-devel \
		redhat-rpm-config \
		rubygems \
		ruby-devel \
		rubygem-bundler \
		ImageMagick-devel \
		opencv-devel \
		which
# Install the latest stable version of meson
RUN pip3 install --user --upgrade meson

RUN gem install bundler
# Using this fork of Feedbin since we don't setup Stripe:
#
RUN git clone --single-branch -b stripe_optional https://github.com/brendanlong/feedbin.git
RUN bundle config build.nokogiri --use-system-libraries
RUN cd feedbin && bundle
