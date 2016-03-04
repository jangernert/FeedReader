# TT-RSS FeedReader plugin

This is a plugin for [Tiny-Tiny-RSS](http://tt-rss.org) web based news feed reader and aggregator.

It adds a new API (addLabel and removeLabel) to allow better interaction of Tiny-Tiny-RSS and clients.

The plugin requires (at least) version 1.12 of Tiny-Tiny-RSS.

## API Reference


**addLabel**

Returns a JSON-encoded ID of the added tag.

Parameters:
 * caption (string) - the caption of the tag


**removeLabel**

Parameters:
 * label_id (int) - the id of the tag


**addCategory**

Returns a JSON-encoded ID of the added tag.

Parameters:
 * caption (string) - the caption of the category


**removeCategory**

Parameters:
 * cateogry_id (int) - the id of the category


**renameCategory**

Parameters:
 * cateogry_id (int) - the id of the category
 * caption (string) - new name of the category


**renameFeed**

Parameters:
 * feed_id (int) - the id of the feed
 * caption (string)  - new name of the feed


## Installation

To install this plugin download the zip file, then extract it in your own tt-rss/plugin/ directory.

You should have a new "api_labels" directory under plugins.
Edit your config.php and add "api_labels" to the list of system plugins. It will be automatically enabled for every user.

## License
This code is licensed under GPLv3. Although I am not a personal fan of the v3, since this code was built upon the existing source of TT-RSS, it inherits the same license.
