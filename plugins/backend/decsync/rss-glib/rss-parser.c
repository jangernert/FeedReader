/* rss-generator.c
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

/**
 * SECTION:rss-parser
 * @short_description: Parse RSS data streams
 *
 * #RssParser provides an object for parsing a RSS data stream, either
 * inside a file or inside a static buffer.
 */

#include "rss-parser.h"
#include "rss-parser-private.h"

#include "rss-item.h"
#include "rss-item-private.h"

#include "rss-document.h"
#include "rss-document-private.h"

#include "rss-marshal.h"

GQuark
rss_parser_error_quark (void)
{
	return g_quark_from_static_string ("rss_parser_error");
}

enum
{
	PARSE_START,
	PARSE_END,

	LAST_SIGNAL
};

static guint parser_signals[LAST_SIGNAL] = { 0, };

G_DEFINE_TYPE (RssParser, rss_parser, G_TYPE_OBJECT);

static void
rss_parser_dispose (GObject *object)
{
	RssParserPrivate *priv = RSS_PARSER (object)->priv;

	if (priv->document) {
		g_object_unref (priv->document);
		priv->document = NULL;
	}

	G_OBJECT_CLASS (rss_parser_parent_class)->dispose (object);
}

static void
rss_parser_class_init (RssParserClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	g_type_class_add_private (klass, sizeof (RssParserPrivate));
	object_class->dispose = rss_parser_dispose;

	/**
	 * RssParser::parse-start:
	 * @parser: the #RssParser that received the signal
	 *
	 * The ::parse-signal is emitted when the parser began parsing
	 * a RSS data stream.
	 */
	parser_signals[PARSE_START] =
		g_signal_new ("parse-start",
		              G_OBJECT_CLASS_TYPE (object_class),
		              G_SIGNAL_RUN_LAST,
		              G_STRUCT_OFFSET (RssParserClass, parse_start),
		              NULL, NULL,
		              _rss_marshal_VOID__VOID,
		              G_TYPE_NONE, 0);

	/**
	 * RssParser::parse-end:
	 * @parser: the #RssParser that received the signal
	 *
	 * The ::parse-end signal is emitted when the parser successfully
	 * finished parsing a RSS data stream.
	 */
	parser_signals[PARSE_END] =
		g_signal_new ("parse-end",
		              G_OBJECT_CLASS_TYPE (object_class),
		              G_SIGNAL_RUN_LAST,
		              G_STRUCT_OFFSET (RssParserClass, parse_end),
		              NULL, NULL,
		              _rss_marshal_VOID__VOID,
		              G_TYPE_NONE, 0);
}

static void
rss_parser_init (RssParser *self)
{
        self->priv =
                G_TYPE_INSTANCE_GET_PRIVATE (self, RSS_TYPE_PARSER,
                                             RssParserPrivate);
}

/**
 * rss_parser_new:
 *
 * Creates a new #RssParser instance.  You can use the #RssParser to
 * load a RSS stream from either a file or a buffer and then walk the
 * items discovered through the resulting RssDocument.
 *
 * Return value: the new created #RssParser. Use g_object_unref() to
 *   release all the memory it allocates.
 */
RssParser*
rss_parser_new (void)
{
	return g_object_new (RSS_TYPE_PARSER, NULL);
}

static RssDocument*
rss_parser_parse (RssParser *self, mrss_t *mrss)
{
	RssDocument     *document;
	RssItem         *rss_item;
	GList           *list, *list2;
	mrss_category_t *cat;
	mrss_item_t     *item;

	g_return_val_if_fail (RSS_IS_PARSER (self), NULL);
	g_return_val_if_fail (mrss != NULL, NULL);

	/* create our document object */
	document = rss_document_new ();

	/* set our document level properties */
	g_object_set (document,
	              "encoding",           mrss->encoding,
	              "guid",               mrss->id,
	              "title",              mrss->title,
	              "description",        mrss->description,
	              "link",               mrss->link,
	              "language",           mrss->language,
	              "rating",             mrss->rating,
	              "copyright",          mrss->copyright,
	              "pub-date",           mrss->pubDate,
	              "ttl",                mrss->ttl,
	              "about",              mrss->about,
	              "contributor",        mrss->contributor,
	              "contributor-email",  mrss->contributor_email,
	              "contributor-uri",    mrss->contributor_uri,
	              "generator",          mrss->generator,
	              "generator-uri",      mrss->generator_uri,
	              "generator-version",  mrss->generator_version,
	              "image-title",        mrss->image_title,
	              "image-url",          mrss->image_url,
	              "image-link",         mrss->image_link,
	              NULL);

	/* build the list of categories */
	if (NULL != (cat = mrss->category)) {
		list = NULL;
		do {
			list = g_list_prepend (list, g_strdup (cat->category));
		} while (NULL != (cat = cat->next));
		document->priv->categories = list;
	}

	/* build the list of items */
	if (NULL != (item = mrss->item)) {
		list = NULL;
		do {
			rss_item = rss_item_new ();

			/* set the rss item properties */
			g_object_set (rss_item,
			              "guid",              item->guid,
			              "title",             item->title,
			              "link",              item->link,
			              "description",       item->description,
			              "copyright",         item->copyright,
			              "author",            item->author,
			              "author-uri",        item->author_uri,
			              "author-email",      item->author_email,
			              "contributor",       item->contributor,
			              "contributor-uri",   item->contributor_uri,
			              "contributor-email", item->contributor_email,
			              "comments",          item->comments,
			              "pub-date",          item->pubDate,
			              "source",	           item->source,
			              "source-url",        item->source_url,
			              "enclosure",         item->enclosure,
	                              "enclosure-url",     item->enclosure_url,
			              NULL);

			/* parse the items categories */
			if (NULL != (cat = item->category)) {
				list2 = NULL;
				do {
					list2 = g_list_prepend (list2, g_strdup (cat->category));
				} while (NULL != (cat = cat->next));
				rss_item->priv->categories = list2;
			}

			list = g_list_prepend (list, rss_item);
		} while (NULL != (item = item->next));
		document->priv->items = list;
	}

	return document;
}

/**
 * rss_parser_load_from_data:
 * @self: a #RssParser
 * @data: a buffer containing the syndication data
 * @length: the length of the buffer
 * @error: a location to place a newly created GError in case of error
 *
 * Parses the contents found at @data as an rss file. You can retrieve
 * the parsed document with rss_parser_get_document().
 *
 * Returns: TRUE on success.
 */
gboolean
rss_parser_load_from_data (RssParser   *self,
                           const gchar *data,
                           gsize        length,
                           GError     **error)
{
	mrss_t       *mrss;
	mrss_error_t  res;

	g_signal_emit (self, parser_signals[PARSE_START], 0);

	/* parse the buffer */
	res = mrss_parse_buffer ((char*)data, length, &mrss);

	/* if there was an error parsing, set the error and return false */
	if (MRSS_OK != res) {
		if (error) {
			g_set_error (error, RSS_PARSER_ERROR,
			             RSS_PARSER_ERROR_INVALID_DATA,
			             "Could not parse data contents");
		}
		return FALSE;
	}

	/* keep a copy of our parsed document */
	self->priv->document = rss_parser_parse (self, mrss);

	/* free our mrss data */
	mrss_free (mrss);

	g_signal_emit (self, parser_signals[PARSE_END], 0);

	return TRUE;
}

/**
 * rss_parser_load_from_file:
 * @self: a #RssParser
 * @filename: the path to the file to parse
 * @error: a location for a newly created #GError
 *
 * Parses the file found at @filename as an rss file. You can retrieve
 * the parsed document with rss_parser_get_document().
 *
 * Returns: TRUE if the parse was successful
 */
gboolean
rss_parser_load_from_file (RssParser  *self,
                           gchar      *filename,
                           GError    **error)
{
	mrss_t       *mrss;
	mrss_error_t  res;

	g_signal_emit (self, parser_signals[PARSE_START], 0);

	/* parse the buffer */
	res = mrss_parse_file (filename, &mrss);

	/* if there was an error parsing, set the error and return false */
	if (MRSS_OK != res) {
		if (error) {
			g_set_error (error, RSS_PARSER_ERROR,
			             RSS_PARSER_ERROR_INVALID_DATA,
			             "Could not parse file contents");
		}
		return FALSE;
	}

	/* keep a copy of our parsed document */
	self->priv->document = rss_parser_parse (self, mrss);

	/* free our mrss data */
	mrss_free (mrss);

	g_signal_emit (self, parser_signals[PARSE_END], 0);

	return TRUE;
}

/**
 * rss_parser_get_document:
 * @self: a #RssParser
 *
 * Retreives the document result from parsing rss data from either
 * a buffer or a file. The document's ref-count is increased, so
 * call g_object_unref when you are done.
 *
 * Returns: a #RssDocument
 */
RssDocument*
rss_parser_get_document (RssParser *self)
{
	g_return_val_if_fail (RSS_IS_PARSER (self), NULL);

	return g_object_ref (self->priv->document);
}
