/* rss-parser.h
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

#ifndef __RSS_PARSER_H__
#define __RSS_PARSER_H__

#include <glib-object.h>
#include "rss-document.h"

G_BEGIN_DECLS

#define RSS_TYPE_PARSER rss_parser_get_type()

#define RSS_PARSER(obj)					\
	(G_TYPE_CHECK_INSTANCE_CAST ((obj),		\
	RSS_TYPE_PARSER,				\
	RssParser))

#define RSS_PARSER_CLASS(klass)				\
	(G_TYPE_CHECK_CLASS_CAST ((klass),		\
	RSS_TYPE_PARSER,				\
	RssParserClass))

#define RSS_IS_PARSER(obj)				\
	(G_TYPE_CHECK_INSTANCE_TYPE ((obj),		\
	RSS_TYPE_PARSER))

#define RSS_IS_PARSER_CLASS(klass)			\
	(G_TYPE_CHECK_CLASS_TYPE ((klass),		\
	RSS_TYPE_PARSER))

#define RSS_PARSER_GET_CLASS(obj)			\
	(G_TYPE_INSTANCE_GET_CLASS ((obj),		\
	RSS_TYPE_PARSER,				\
	RssParserClass))

typedef struct _RssParser               RssParser;
typedef struct _RssParserPrivate        RssParserPrivate;
typedef struct _RssParserClass          RssParserClass;

struct _RssParser
{
        /*< private >*/
        GObject parent_instance;

        RssParserPrivate *priv;
};

struct _RssParserClass
{
	/*< private >*/
	GObjectClass parent_class;

	/*< public >*/
	void (* parse_start) (RssParser *parser);
	void (* parse_end)   (RssParser *parser);

	/*< private >*/
	/* padding for future expansion */
	void (* _rss_reserved1) (void);
	void (* _rss_reserved2) (void);
	void (* _rss_reserved3) (void);
	void (* _rss_reserved4) (void);
	void (* _rss_reserved5) (void);
	void (* _rss_reserved6) (void);
	void (* _rss_reserved7) (void);
	void (* _rss_reserved8) (void);
};

GType        rss_parser_get_type       (void);
RssParser*   rss_parser_new            (void);
gboolean     rss_parser_load_from_data (RssParser   * self,
                                        const gchar *data,
                                        gsize         length,
				        GError      **error);
gboolean     rss_parser_load_from_file (RssParser   *self,
                                        gchar       *filename,
				        GError     **error);
RssDocument* rss_parser_get_document   (RssParser   *self);

G_END_DECLS

#endif /* __RSS_PARSER_H__ */
