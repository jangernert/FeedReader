---
distro: Flatpak
data-content: flatpak
---
FeedReader is now availble as Flatpak and should be installable on all major Linux distributions that support the Flatpak Application Framework eg. Fedora, Debian, Ubuntu, elementaryOS, Arch, openSuSE, Mageia and many more. 

For more information about Flatpak and how to use or install it for your distribution see the [Flatpak webpage](http://flatpak.org).

<h3><small>You will need the following packages installed:</small></h3>
<h4><small>(names can differ depending on the distribution)</small></h4>

<pre><ul><li>xdg-desktop-portal</li><li>xdg-desktop-portal-gtk</li></ul></pre>

<h3><small>Install FeedReader Flatpak via repository, this enables OTA updates and is the recommended way:</small></h3>

<pre>
flatpak install http://feedreader.xarbit.net/feedreader-repo/feedreader.flatpakref
</pre>

<h3><small>Install FeedReader Flatpak via standalone bundle:</small></h3>

- [FeedReader Flatpak](https://github.com/jangernert/FeedReader/releases)

GNOME-Software can handle flatpak bundles, just open the downloaded feedreader.flatpak file with GNOME-Software and click on install. Thats it..

You can also install the FeedReader flatpak from the commandline as so:

<pre>
$ flatpak install --bundle FeedReader-{BUILD VERSION}.flatpak
</pre>

NOTE: Update the bundle with the same command.
