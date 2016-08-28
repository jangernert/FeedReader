/* rss-document.h
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

#ifndef __RSS_DOCUMENT_H__
#define __RSS_DOCUMENT_H__

#include <glib-object.h>

G_BEGIN_DECLS

#define RSS_TYPE_DOCUMENT rss_document_get_type()

#define RSS_DOCUMENT(obj)				\
	(G_TYPE_CHECK_INSTANCE_CAST ((obj),		\
	RSS_TYPE_DOCUMENT,				\
	RssDocument))

#define RSS_DOCUMENT_CLASS(klass)			\
	(G_TYPE_CHECK_CLASS_CAST ((klass),		\
	RSS_TYPE_DOCUMENT,				\
	RssDocumentClass))

#define RSS_IS_DOCUMENT(obj)				\
	(G_TYPE_CHECK_INSTANCE_TYPE ((obj),		\
	RSS_TYPE_DOCUMENT))

#define RSS_IS_DOCUMENT_CLASS(klass)			\
	(G_TYPE_CHECK_CLASS_TYPE ((klass),		\
	RSS_TYPE_DOCUMENT))

#define RSS_DOCUMENT_GET_CLASS(obj)			\
	(G_TYPE_INSTANCE_GET_CLASS ((obj),		\
	RSS_TYPE_DOCUMENT,				\
	RssDocumentClass))

typedef struct _RssDocument             RssDocument;
typedef struct _RssDocumentPrivate      RssDocumentPrivate;
typedef struct _RssDocumentClass        RssDocumentClass;

struct _RssDocument
{
        /*< private >*/
        GObject parent_instance;

        RssDocumentPrivate *priv;
};

struct _RssDocumentClass
{
        /*< private >*/
        GObjectClass parent_class;
};

GType                 rss_document_get_type       (void);
RssDocument*          rss_document_new            (void);

const gchar *rss_document_get_guid              (RssDocument *self);
const gchar *rss_document_get_about             (RssDocument *self);
const gchar *rss_document_get_title             (RssDocument *self);
const gchar *rss_document_get_description       (RssDocument *self);
const gchar *rss_document_get_link              (RssDocument *self);
const gchar *rss_document_get_encoding          (RssDocument *self);
const gchar *rss_document_get_language          (RssDocument *self);
const gchar *rss_document_get_rating            (RssDocument *self);
const gchar *rss_document_get_copyright         (RssDocument *self);
const gchar *rss_document_get_pub_date          (RssDocument *self);
const gchar *rss_document_get_editor_name       (RssDocument *self);
const gchar *rss_document_get_editor_email      (RssDocument *self);
const gchar *rss_document_get_editor_uri        (RssDocument *self);
const gchar *rss_document_get_contributor_name  (RssDocument *self);
const gchar *rss_document_get_contributor_email (RssDocument *self);
const gchar *rss_document_get_contributor_uri   (RssDocument *self);
const gchar *rss_document_get_generator_name    (RssDocument *self);
const gchar *rss_document_get_generator_uri     (RssDocument *self);
const gchar *rss_document_get_generator_version (RssDocument *self);
const gchar *rss_document_get_image_title       (RssDocument *self);
const gchar *rss_document_get_image_url         (RssDocument *self);
const gchar *rss_document_get_image_link        (RssDocument *self);
gint                  rss_document_get_ttl               (RssDocument *self);

GList *               rss_document_get_items             (RssDocument *self);
GList *               rss_document_get_categories        (RssDocument *self);

G_END_DECLS

#endif /* __RSS_DOCUMENT_H__ */
