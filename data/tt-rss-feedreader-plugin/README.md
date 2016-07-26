# TT-RSS FeedReader plugin

This is a plugin for [Tiny-Tiny-RSS](http://tt-rss.org) web based news feed reader and aggregator.

It adds a new API calls to allow better interaction of Tiny-Tiny-RSS and clients (in this case FeedReader).

The plugin requires (at least) version 1.12 of Tiny-Tiny-RSS.

## API Reference


**addLabel**

Returns a JSON-encoded ID of the added label.

Parameters:
 * caption (string) - the caption of the label


**removeLabel**

Parameters:
 * label_id (int) - the id of the label


**renameLabel**

Parameters:
 * label_id (int) - the id of the label
 * caption (string) - new name of the label


**addCategory**

Returns a JSON-encoded ID of the added category.

Parameters:
 * caption (string) - the caption of the category
 * parent_id (int, optional) - id of the category the new one should be placed into


**removeCategory**

Parameters:
 * cateogry_id (int) - the id of the category
 

**moveCategory**

Parameters:
 * cateogry_id (int) - the id of the category
 * parent_id (int) - cateogry id of the new parent


**renameCategory**

Parameters:
 * cateogry_id (int) - the id of the category
 * caption (string) - new name of the category


**renameFeed**

Parameters:
 * feed_id (int) - the id of the feed
 * caption (string)  - new name of the feed
 

**moveFeed**

Parameters:
 * feed_id (int) - the id of the feed
 * category_id (int)  - id of category the feed will be moved to


## Installation

To install this plugin download the zip file, then extract it in your own tt-rss/plugin/ directory.

You should have a new "api_feedreader" directory under plugins.
Edit your config.php and add "api_feedreader" to the list of system plugins. It will be automatically enabled for every user.

## License
This code is licensed under GPLv3.
