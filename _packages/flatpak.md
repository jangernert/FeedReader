---
distro: Flatpak
data-content: flatpak
---
FeedReader is now availble as a standalone Flatpak file and should be installable on all Linux distributions that support the Flatpak Application Framework. This is still a WIP and might not work as expected, please report any Flatpak related issues [HERE](https://github.com/jscurtu/feedreader-flatpak/issues). 

For more information about Flatpak and how to use or install it for your distribution see the [Flatpak webpage](http://flatpak.org).

For FeedReader to properly work, you will also need to install the following portal packages, look in your distributions packagemanager:

<pre><ul><li>xdg-desktop-portal</li><li>xdg-desktop-portal-gtk</li></ul></pre>
When all set, download the flatpak'd standalone bundle here:

- [FeedReader 1.6.2 Flatpak](https://github.com/jscurtu/feedreader-flatpak/releases)

GNOME-Software can handle flatpak bundles, just open the downloaded feedreader.flatpak file with GNOME-Software and click on install. Thats it..

You can also install the feedreader.flatpak from the commandline as so:

<pre>
	$ flatpak install --bundle feedreader.flatpak
</pre>
