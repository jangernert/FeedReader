/* rss-item.h
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

#ifndef __RSS_ITEM_H__
#define __RSS_ITEM_H__

#include <glib-object.h>

G_BEGIN_DECLS

#define RSS_TYPE_ITEM rss_item_get_type()

#define RSS_ITEM(obj)				\
	(G_TYPE_CHECK_INSTANCE_CAST ((obj),	\
	RSS_TYPE_ITEM,				\
	RssItem))

#define RSS_ITEM_CLASS(klass)			\
	(G_TYPE_CHECK_CLASS_CAST ((klass),	\
	RSS_TYPE_ITEM,				\
	RssItemClass))

#define RSS_IS_ITEM(obj)			\
	(G_TYPE_CHECK_INSTANCE_TYPE ((obj),	\
	RSS_TYPE_ITEM))

#define RSS_IS_ITEM_CLASS(klass)		\
	(G_TYPE_CHECK_CLASS_TYPE ((klass),	\
	RSS_TYPE_ITEM))

#define RSS_ITEM_GET_CLASS(obj)			\
	(G_TYPE_INSTANCE_GET_CLASS ((obj),	\
	RSS_TYPE_ITEM,				\
	RssItemClass))

typedef struct _RssItem         RssItem;
typedef struct _RssItemPrivate  RssItemPrivate;
typedef struct _RssItemClass    RssItemClass;

struct _RssItem
{
        /*< private >*/
	GObject parent_instance;

        RssItemPrivate *priv;
};

struct _RssItemClass
{
        /*< private >*/
	GObjectClass parent_class;
};

GType    rss_item_get_type       (void);
RssItem* rss_item_new            (void);

const gchar *rss_item_get_guid              (RssItem *self);
const gchar *rss_item_get_title             (RssItem *self);
const gchar *rss_item_get_link              (RssItem *self);
const gchar *rss_item_get_description       (RssItem *self);
const gchar *rss_item_get_copyright         (RssItem *self);
const gchar *rss_item_get_author_name       (RssItem *self);
const gchar *rss_item_get_author_uri        (RssItem *self);
const gchar *rss_item_get_author_email      (RssItem *self);
const gchar *rss_item_get_contributor_name  (RssItem *self);
const gchar *rss_item_get_contributor_uri   (RssItem *self);
const gchar *rss_item_get_contributor_email (RssItem *self);
const gchar *rss_item_get_comments          (RssItem *self);
const gchar *rss_item_get_pub_date          (RssItem *self);
const gchar *rss_item_get_source            (RssItem *self);
const gchar *rss_item_get_source_url        (RssItem *self);
const gchar *rss_item_get_enclosure         (RssItem *self);
const gchar *rss_item_get_enclosure_url     (RssItem *self);
GList*                rss_item_get_categories        (RssItem *self);

G_END_DECLS

#endif /* __RSS_ITEM_H__ */
