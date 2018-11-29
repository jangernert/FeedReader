/* rss-item-private.h
 * 
 * This file is part of RSS-GLib.
 * Copyright (C) 2008  Christian Hergert <chris@dronelabs.com>
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *   Christian Hergert  <chris@dronelabs.com>
 */

#ifndef __RSS_ITEM_PRIVATE_H__
#define __RSS_ITEM_PRIVATE_H__

struct _RssItemPrivate {
	gchar *guid;
	gchar *title;
	gchar *link;
	gchar *description;
	gchar *copyright;
	gchar *author;
	gchar *author_uri;
	gchar *author_email;
	gchar *contributor;
	gchar *contributor_uri;
	gchar *contributor_email;
	gchar *comments;
	gchar *pub_date;
	gchar *source;
	gchar *source_url;
	gchar *enclosure;
	gchar *enclosure_url;

	GList *categories;
};

#endif /* __RSS_ITEM_PRIVATE_H__ */
