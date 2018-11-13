/* rss-document-private.h
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

#ifndef __RSS_DOCUMENT_PRIVATE_H__
#define __RSS_DOCUMENT_PRIVATE_H__

#include <mrss.h>

struct _RssDocumentPrivate
{
	gchar *encoding;
	gchar *guid;
	gchar *title;
	gchar *description;
	gchar *link;
	gchar *language;
	gchar *rating;
	gchar *copyright;
	gchar *pub_date;
	gchar *editor;
	gchar *editor_email;
	gchar *editor_uri;
	gint   ttl;
	gchar *about;
	gchar *contributor;
	gchar *contributor_email;
	gchar *contributor_uri;
	gchar *generator;
	gchar *generator_uri;
	gchar *generator_version;
	gchar *image_title;
	gchar *image_url;
	gchar *image_link;

	GList *items;
	GList *categories;
};

#endif /* __RSS_DOCUMENT_PRIVATE_H__ */
