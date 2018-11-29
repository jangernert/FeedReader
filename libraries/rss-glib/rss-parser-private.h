/* rss-parser-private.h
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

#ifndef __RSS_PARSER_PRIVATE_H__
#define __RSS_PARSER_PRIVATE_H__

#include <glib-object.h>

G_BEGIN_DECLS

struct _RssParserPrivate
{
	RssDocument *document;
};

typedef enum
{
	RSS_PARSER_ERROR_INVALID_DATA,
} RssParserError;

#define RSS_PARSER_ERROR rss_parser_error_quark()
GQuark rss_parser_error_quark (void);

G_END_DECLS

#endif /* __RSS_PARSER_PRIVATE_H__ */
