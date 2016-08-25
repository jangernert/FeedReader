/* rss-document.c
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
 * SECTION:rss-document
 * @short_description: a RSS document representation
 * @see_also: rss_parser_get_document()
 *
 * #RssDocument is the representation of the resource that was parsed. It
 * contains a list of #RssItem<!-- -->s which in turn contain article information.
 */

#include "rss-document.h"
#include "rss-document-private.h"

G_DEFINE_TYPE (RssDocument, rss_document, G_TYPE_OBJECT);

enum {
	PROP_0,

	PROP_ENCODING,
	PROP_GUID,
	PROP_TITLE,
	PROP_DESCRIPTION,
	PROP_LINK,
	PROP_LANGUAGE,
	PROP_RATING,
	PROP_COPYRIGHT,
	PROP_PUB_DATE,
	PROP_PUB_DATE_PARSED,
	PROP_EDITOR,
	PROP_EDITOR_EMAIL,
	PROP_EDITOR_URI,
	PROP_TTL,
	PROP_ABOUT,
	PROP_CONTRIBUTOR,
	PROP_CONTRIBUTOR_EMAIL,
	PROP_CONTRIBUTOR_URI,
	PROP_GENERATOR,
	PROP_GENERATOR_URI,
	PROP_GENERATOR_VERSION,
	PROP_IMAGE_TITLE,
	PROP_IMAGE_URL,
	PROP_IMAGE_LINK
};

static void
rss_document_get_property (GObject    *object,
                           guint       property_id,
                           GValue     *value,
                           GParamSpec *pspec)
{
	RssDocumentPrivate *priv = RSS_DOCUMENT (object)->priv;

	switch (property_id) {
	case PROP_ENCODING:
		g_value_set_string (value, priv->encoding);
		break;
	case PROP_GUID:
		g_value_set_string (value, priv->guid);
		break;
	case PROP_TITLE:
		g_value_set_string (value, priv->title);
		break;
	case PROP_DESCRIPTION:
		g_value_set_string (value, priv->description);
		break;
	case PROP_LINK:
		g_value_set_string (value, priv->link);
		break;
	case PROP_LANGUAGE:
		g_value_set_string (value, priv->language);
		break;
	case PROP_RATING:
		g_value_set_string (value, priv->rating);
		break;
	case PROP_COPYRIGHT:
		g_value_set_string (value, priv->copyright);
		break;
	case PROP_PUB_DATE:
		g_value_set_string (value, priv->pub_date);
		break;
	case PROP_EDITOR:
		g_value_set_string (value, priv->editor);
		break;
	case PROP_EDITOR_EMAIL:
		g_value_set_string (value, priv->editor_email);
		break;
	case PROP_EDITOR_URI:
		g_value_set_string (value, priv->editor_uri);
		break;
	case PROP_ABOUT:
		g_value_set_string (value, priv->about);
		break;
	case PROP_CONTRIBUTOR:
		g_value_set_string (value, priv->contributor);
		break;
	case PROP_CONTRIBUTOR_EMAIL:
		g_value_set_string (value, priv->contributor_email);
		break;
	case PROP_CONTRIBUTOR_URI:
		g_value_set_string (value, priv->contributor_uri);
		break;
	case PROP_GENERATOR:
		g_value_set_string (value, priv->generator);
		break;
	case PROP_GENERATOR_URI:
		g_value_set_string (value, priv->generator_uri);
		break;
	case PROP_GENERATOR_VERSION:
		g_value_set_string (value, priv->generator_version);
		break;
	case PROP_IMAGE_TITLE:
		g_value_set_string (value, priv->image_title);
		break;
	case PROP_IMAGE_URL:
		g_value_set_string (value, priv->image_url);
		break;
	case PROP_IMAGE_LINK:
		g_value_set_string (value, priv->image_link);
		break;
	case PROP_TTL:
		g_value_set_int (value, priv->ttl);
		break;

	default:
		G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
	}
}

static void
rss_document_set_property (GObject      *object,
                           guint         property_id,
                           const GValue *value,
                           GParamSpec   *pspec)
{
	RssDocumentPrivate *priv = RSS_DOCUMENT (object)->priv;

	switch (property_id) {
	case PROP_ENCODING:
		g_free (priv->encoding);
		priv->encoding = g_value_dup_string (value);
		break;
	case PROP_GUID:
		g_free (priv->guid);
		priv->guid = g_value_dup_string (value);
		break;
	case PROP_TITLE:
		g_free (priv->title);
		priv->title = g_value_dup_string (value);
		break;
	case PROP_DESCRIPTION:
		g_free (priv->description);
		priv->description = g_value_dup_string (value);
		break;
	case PROP_LINK:
		g_free (priv->link);
		priv->link = g_value_dup_string (value);
		break;
	case PROP_LANGUAGE:
		g_free (priv->language);
		priv->language = g_value_dup_string (value);
		break;
	case PROP_RATING:
		g_free (priv->rating);
		priv->rating = g_value_dup_string (value);
		break;
	case PROP_COPYRIGHT:
		g_free (priv->copyright);
		priv->copyright = g_value_dup_string (value);
		break;
	case PROP_PUB_DATE:
		g_free (priv->pub_date);
		priv->pub_date = g_value_dup_string (value);
		break;
	case PROP_EDITOR:
		g_free (priv->editor);
		priv->editor = g_value_dup_string (value);
		break;
	case PROP_EDITOR_EMAIL:
		g_free (priv->editor_email);
		priv->editor_email = g_value_dup_string (value);
		break;
	case PROP_EDITOR_URI:
		g_free (priv->editor_uri);
		priv->editor_uri = g_value_dup_string (value);
		break;
	case PROP_ABOUT:
		g_free (priv->about);
		priv->about = g_value_dup_string (value);
		break;
	case PROP_CONTRIBUTOR:
		g_free (priv->contributor);
		priv->contributor = g_value_dup_string (value);
		break;
	case PROP_CONTRIBUTOR_EMAIL:
		g_free (priv->contributor_email);
		priv->contributor_email = g_value_dup_string (value);
		break;
	case PROP_CONTRIBUTOR_URI:
		g_free (priv->contributor_uri);
		priv->contributor_uri = g_value_dup_string (value);
		break;
	case PROP_GENERATOR:
		g_free (priv->generator);
		priv->generator = g_value_dup_string (value);
		break;
	case PROP_GENERATOR_URI:
		g_free (priv->generator_uri);
		priv->generator_uri = g_value_dup_string (value);
		break;
	case PROP_GENERATOR_VERSION:
		g_free (priv->generator_version);
		priv->generator_version = g_value_dup_string (value);
		break;
	case PROP_IMAGE_TITLE:
		g_free (priv->image_title);
		priv->image_title = g_value_dup_string (value);
		break;
	case PROP_IMAGE_URL:
		g_free (priv->image_url);
		priv->image_url = g_value_dup_string (value);
		break;
	case PROP_IMAGE_LINK:
		g_free (priv->image_link);
		priv->image_link = g_value_dup_string (value);
		break;
	case PROP_TTL:
		priv->ttl = g_value_get_int (value);
		break;

	default:
		G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
	}
}

static void
rss_document_dispose (GObject *object)
{
	RssDocumentPrivate *priv = RSS_DOCUMENT (object)->priv;

	g_free (priv->encoding);
	g_free (priv->guid);
	g_free (priv->title);
	g_free (priv->description);
	g_free (priv->link);
	g_free (priv->language);
	g_free (priv->rating);
	g_free (priv->copyright);
	g_free (priv->pub_date);
	g_free (priv->editor);
	g_free (priv->editor_email);
	g_free (priv->editor_uri);
	g_free (priv->about);
	g_free (priv->contributor);
	g_free (priv->contributor_email);
	g_free (priv->contributor_uri);
	g_free (priv->generator);
	g_free (priv->generator_uri);
	g_free (priv->generator_version);
	g_free (priv->image_title);
	g_free (priv->image_url);
	g_free (priv->image_link);

	/* free the items */
	g_list_foreach (priv->items, (GFunc) g_object_unref, NULL);
	g_list_free (priv->items);

	/* free the category strings */
	g_list_foreach (priv->categories, (GFunc) g_free, NULL);
	g_list_free (priv->categories);

	G_OBJECT_CLASS (rss_document_parent_class)->dispose (object);
}

static void
rss_document_class_init (RssDocumentClass *klass)
{
	GObjectClass *gobject_class = G_OBJECT_CLASS (klass);
	GParamSpec *pspec;

	g_type_class_add_private (klass, sizeof (RssDocumentPrivate));

	gobject_class->get_property = rss_document_get_property;
	gobject_class->set_property = rss_document_set_property;
	gobject_class->dispose = rss_document_dispose;

	/**
	 * RssDocument:encoding:
	 *
	 * The encoding of the #RssDocument.
	 */
	pspec = g_param_spec_string ("encoding",
	                             "Encoding",
	                             "Encoding of the document",
	                             NULL,
	                             G_PARAM_READWRITE);
	g_object_class_install_property (gobject_class,
	                                 PROP_ENCODING,
	                                 pspec);

	/**
	 * RssDocument:guid:
	 *
	 * The guid associated with the feed. This is often the url of the
	 * feed.
	 */
	pspec = g_param_spec_string ("guid",
	                             "GUID",
	                             "The GUID of the document",
	                             NULL,
	                             G_PARAM_READWRITE);
	g_object_class_install_property (gobject_class,
	                                 PROP_GUID,
	                                 pspec);

	/**
	 * RssDocument:title:
	 *
	 * The title of the #RssDocument.
	 */
	pspec = g_param_spec_string ("title",
	                             "Title",
	                             "Title of the document",
	                             NULL,
	                             G_PARAM_READWRITE);
	g_object_class_install_property (gobject_class,
	                                 PROP_TITLE,
	                                 pspec);

	/**
	 * RssDocument:description:
	 *
	 * The description of the #RssDocument.
	 */
	pspec = g_param_spec_string ("description",
	                             "Description",
	                             "Description of the document",
	                             NULL,
	                             G_PARAM_READWRITE);
	g_object_class_install_property (gobject_class,
	                                 PROP_DESCRIPTION,
	                                 pspec);

	/**
	 * RssDocument:link:
	 *
	 * The link to the source document.  This is parsed from the actual
	 * document and can point to whatever the source publisher choses.
	 */
	pspec = g_param_spec_string ("link",
	                             "Link",
	                             "The link to the source document",
	                             NULL,
	                             G_PARAM_READWRITE);
	g_object_class_install_property (gobject_class,
	                                 PROP_LINK,
	                                 pspec);

	/**
	 * RssDocument:language:
	 *
	 * The language the #RssDocument was published in.
	 */
	pspec = g_param_spec_string ("language",
	                             "Language",
	                             "Language of the document",
	                             NULL,
	                             G_PARAM_READWRITE);
	g_object_class_install_property (gobject_class,
	                                 PROP_LANGUAGE,
	                                 pspec);

	/**
	 * RssDocument:rating:
	 *
	 * The rating associated with the #RssDocument.
	 */
	pspec = g_param_spec_string ("rating",
	                             "Rating",
	                             "Rating of the document",
	                             NULL,
	                             G_PARAM_READWRITE);
	g_object_class_install_property (gobject_class,
	                                 PROP_RATING,
	                                 pspec);

	/**
	 * RssDocument:copyright:
	 *
	 * The copyright of the #RssDocument.
	 */
	pspec = g_param_spec_string ("copyright",
	                             "Copyright",
	                             "Copyright of the document",
	                             NULL,
	                             G_PARAM_READWRITE);
	g_object_class_install_property (gobject_class,
	                                 PROP_COPYRIGHT,
	                                 pspec);

	/**
	 * RssDocument:pub-date:
	 *
	 * The string representation of the date the document was published.
	 */
	pspec = g_param_spec_string ("pub-date",
	                             "Publication Date",
	                             "Publication date of the document",
	                             NULL,
	                             G_PARAM_READWRITE);
	g_object_class_install_property (gobject_class,
	                                 PROP_PUB_DATE,
	                                 pspec);

	/**
	 * RssDocument:editor:
	 *
	 * The name of the editor.
	 */
	pspec = g_param_spec_string ("editor",
	                             "Editor",
	                             "Editor of the document",
	                             NULL,
	                             G_PARAM_READWRITE);
	g_object_class_install_property (gobject_class,
	                                 PROP_EDITOR,
	                                 pspec);

	/**
	 * RssDocument:editor-email:
	 *
	 * The email address of the editor.
	 */
	pspec = g_param_spec_string ("editor-email",
	                             "Editor Email",
	                             "Email of the editor",
	                             NULL,
	                             G_PARAM_READWRITE);
	g_object_class_install_property (gobject_class,
	                                 PROP_EDITOR_EMAIL,
	                                 pspec);

	/**
	 * RssDocument:editor-uri:
	 *
	 * The uri for more information about the editor.
	 */
	pspec = g_param_spec_string ("editor-uri",
	                             "Editor URI",
	                             "The URI of the editor",
	                             NULL,
	                             G_PARAM_READWRITE);
	g_object_class_install_property (gobject_class,
	                                 PROP_EDITOR_URI,
	                                 pspec);

	/**
	 * RssDocument:about:
	 *
	 * Information about the #RssDocument.
	 */
	pspec = g_param_spec_string ("about",
	                             "About",
	                             "Information about the document",
	                             NULL,
	                             G_PARAM_READWRITE);
	g_object_class_install_property (gobject_class,
	                                 PROP_ABOUT,
	                                 pspec);

	/**
	 * RssDocument:contributor:
	 *
	 * The name of the particular contributor.
	 */
	pspec = g_param_spec_string ("contributor",
	                             "Contributor",
	                             "Name of the contributor",
	                             NULL,
	                             G_PARAM_READWRITE);
	g_object_class_install_property (gobject_class,
	                                 PROP_CONTRIBUTOR,
	                                 pspec);

	/**
	 * RssDocument:contributor-email:
	 *
	 * The email of the particular contributor.
	 */
	pspec = g_param_spec_string ("contributor-email",
	                             "Contributor Email",
	                             "Email of the contributor",
	                             NULL,
	                             G_PARAM_READWRITE);
	g_object_class_install_property (gobject_class,
	                                 PROP_CONTRIBUTOR_EMAIL,
	                                 pspec);

	/**
	 * RssDocument:contributor-uri:
	 *
	 * The uri to more information on the particular contributer.
	 */
	pspec = g_param_spec_string ("contributor-uri",
	                             "Contributor URI",
	                             "URI of the contributor",
	                             NULL,
	                             G_PARAM_READWRITE);
	g_object_class_install_property (gobject_class,
	                                 PROP_CONTRIBUTOR_URI,
	                                 pspec);

	/**
	 * RssDocument:generator:
	 *
	 * The name of the generator on the server side.
	 */
	pspec = g_param_spec_string ("generator",
	                             "Generator",
	                             "Name of the document generator",
	                             NULL,
	                             G_PARAM_READWRITE);
	g_object_class_install_property (gobject_class,
	                                 PROP_GENERATOR,
	                                 pspec);

	/**
	 * RssDocument:generator-uri:
	 *
	 * Url to more information about the generator on the server side.
	 */
	pspec = g_param_spec_string ("generator-uri",
	                             "Generator URI",
	                             "URI of the document generator",
	                             NULL,
	                             G_PARAM_READWRITE);
	g_object_class_install_property (gobject_class,
	                                 PROP_GENERATOR_URI,
	                                 pspec);

	/**
	 * RssDocument:generator-version:
	 *
	 * The version of the server side generator.
	 */
	pspec = g_param_spec_string ("generator-version",
	                             "Generator Version",
	                             "Version of the document generator",
	                             NULL,
	                             G_PARAM_READWRITE);
	g_object_class_install_property (gobject_class,
	                                 PROP_GENERATOR_VERSION,
	                                 pspec);

	/**
	 * RssDocument:image-title:
	 *
	 * The title for the image.  This is often the alt="" tag in HTML.
	 */
	pspec = g_param_spec_string ("image-title",
	                             "Image Title",
	                             "Title of the image for the document",
	                             NULL,
	                             G_PARAM_READWRITE);
	g_object_class_install_property (gobject_class,
	                                 PROP_IMAGE_TITLE,
	                                 pspec);

	/**
	 * RssDocument:image-url:
	 *
	 * A url to the image for the RssDocument.  Use this before checking
	 * for a favicon.ico.
	 */
	pspec = g_param_spec_string ("image-url",
	                             "Image URL",
	                             "URL of the image for the document",
	                             NULL,
	                             G_PARAM_READWRITE);
	g_object_class_install_property (gobject_class,
	                                 PROP_IMAGE_URL,
	                                 pspec);

	/**
	 * RssDocument:image-link:
	 *
	 * The url a user should be redirected to when clicking on the image
	 * for the #RssDocument.  Of course, its up to UI designers if they
	 * wish to implement this in any sort of way.
	 */
	pspec = g_param_spec_string ("image-link",
	                             "Image Link",
	                             "URL for document image link",
	                             NULL,
	                             G_PARAM_READWRITE);
	g_object_class_install_property (gobject_class,
	                                 PROP_IMAGE_LINK,
	                                 pspec);

	/**
	 * RssDocument:ttl:
	 *
	 * The publisher determined TTL for the source. Readers should try
	 * to respect this value and not update feeds any more often than
	 * necessary.
	 */
	pspec = g_param_spec_int ("ttl",
	                          "TTL",
	                          "Time to live for the document",
	                          0, G_MAXINT32, 0,
	                          G_PARAM_READWRITE);
	g_object_class_install_property (gobject_class,
	                                 PROP_TTL,
	                                 pspec);
}

static void
rss_document_init (RssDocument *self)
{
	self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self, RSS_TYPE_DOCUMENT,
	                                          RssDocumentPrivate);
}

/**
 * rss_document_new:
 *
 * Creates a new instance of #RssDocument.  This isn't incredibly useful
 * currently, but is here none-the-less.  The desire is to create an
 * RSS generator that will allow for building RSS streams out of the
 * document hierarchy.
 *
 * Returns: a new #RssDocument. Use g_object_unref() when you are done.
 */
RssDocument*
rss_document_new (void)
{
	return g_object_new (RSS_TYPE_DOCUMENT, NULL);
}

/**
 * rss_document_get_items:
 * @self: a #RssDocument
 *
 * Creates a #GList of #RssItem<!-- -->s that were found in the syndication. The objects
 * in the list are weak references. Consumers of those objects should ref
 * them with g_object_ref.
 *
 * Returns: a new #GList owned by the caller.
 */
GList*
rss_document_get_items (RssDocument *self)
{
	g_return_val_if_fail (RSS_IS_DOCUMENT (self), NULL);

	return g_list_copy (self->priv->items);
}

/**
 * rss_document_get_categories:
 * @self: a #RssDocument
 *
 * Creates a #GList of categories found in the syndication. The strings
 * in the list are weak references.  Consumers should duplicate them
 * with g_strdup().
 *
 * Returns: a new #GList owned by the caller
 */
GList*
rss_document_get_categories (RssDocument *self)
{
	g_return_val_if_fail (RSS_IS_DOCUMENT (self), NULL);

	return g_list_copy (self->priv->categories);
}

/**
 * rss_document_get_guid:
 * @self: a #RssDocument
 *
 * Retrieves the #RssDocument:guid field.
 *
 * Return value: the contents of the field. The returned string is
 *   owned by the #RssDocument and should never be modified of freed
 */
const gchar *
rss_document_get_guid (RssDocument *self)
{
	g_return_val_if_fail (RSS_IS_DOCUMENT (self), NULL);

	return self->priv->guid;
}

/**
 * rss_document_get_about:
 * @self: a #RssDocument
 *
 * Retrieves the #RssDocument:about field.
 *
 * Return value: the contents of the field. The returned string is
 *   owned by the #RssDocument and should never be modified of freed
 */
const gchar *
rss_document_get_about (RssDocument *self)
{
	g_return_val_if_fail (RSS_IS_DOCUMENT (self), NULL);

	return self->priv->about;
}

/**
 * rss_document_get_title:
 * @self: a #RssDocument
 *
 * Retrieves the #RssDocument:title field.
 *
 * Return value: the contents of the field. The returned string is
 *   owned by the #RssDocument and should never be modified of freed
 */
const gchar *
rss_document_get_title (RssDocument *self)
{
	g_return_val_if_fail (RSS_IS_DOCUMENT (self), NULL);

	return self->priv->title;
}

/**
 * rss_document_get_description:
 * @self: a #RssDocument
 *
 * Retrieves the #RssDocument:description field.
 *
 * Return value: the contents of the field. The returned string is
 *   owned by the #RssDocument and should never be modified of freed
 */
const gchar *
rss_document_get_description (RssDocument *self)
{
	g_return_val_if_fail (RSS_IS_DOCUMENT (self), NULL);

	return self->priv->description;
}

/**
 * rss_document_get_link:
 * @self: a #RssDocument
 *
 * Retrieves the #RssDocument:link field.
 *
 * Return value: the contents of the field. The returned string is
 *   owned by the #RssDocument and should never be modified of freed
 */
const gchar *
rss_document_get_link (RssDocument *self)
{
	g_return_val_if_fail (RSS_IS_DOCUMENT (self), NULL);

	return self->priv->link;
}

/**
 * rss_document_get_encoding:
 * @self: a #RssDocument
 *
 * Retrieves the #RssDocument:encoding field.
 *
 * Return value: the contents of the field. The returned string is
 *   owned by the #RssDocument and should never be modified of freed
 */
const gchar *
rss_document_get_encoding (RssDocument *self)
{
	g_return_val_if_fail (RSS_IS_DOCUMENT (self), NULL);

	return self->priv->encoding;
}

/**
 * rss_document_get_language:
 * @self: a #RssDocument
 *
 * Retrieves the #RssDocument:language field.
 *
 * Return value: the contents of the field. The returned string is
 *   owned by the #RssDocument and should never be modified of freed
 */
const gchar *
rss_document_get_language (RssDocument *self)
{
	g_return_val_if_fail (RSS_IS_DOCUMENT (self), NULL);

	return self->priv->language;
}

/**
 * rss_document_get_rating:
 * @self: a #RssDocument
 *
 * Retrieves the #RssDocument:rating field.
 *
 * Return value: the contents of the field. The returned string is
 *   owned by the #RssDocument and should never be modified of freed
 */
const gchar *
rss_document_get_rating (RssDocument *self)
{
	g_return_val_if_fail (RSS_IS_DOCUMENT (self), NULL);

	return self->priv->rating;
}

/**
 * rss_document_get_copyright:
 * @self: a #RssDocument
 *
 * Retrieves the #RssDocument:copyright field.
 *
 * Return value: the contents of the field. The returned string is
 *   owned by the #RssDocument and should never be modified of freed
 */
const gchar *
rss_document_get_copyright (RssDocument *self)
{
	g_return_val_if_fail (RSS_IS_DOCUMENT (self), NULL);

	return self->priv->copyright;
}

/**
 * rss_document_get_pub_date:
 * @self: a #RssDocument
 *
 * Retrieves the #RssDocument:pub-date field.
 *
 * Return value: the contents of the field. The returned string is
 *   owned by the #RssDocument and should never be modified of freed
 */
const gchar *
rss_document_get_pub_date (RssDocument *self)
{
	g_return_val_if_fail (RSS_IS_DOCUMENT (self), NULL);

	return self->priv->pub_date;
}

/**
 * rss_document_get_editor_name:
 * @self: a #RssDocument
 *
 * Retrieves the #RssDocument:editor field.
 *
 * Return value: the contents of the field. The returned string is
 *   owned by the #RssDocument and should never be modified of freed
 */
const gchar *
rss_document_get_editor_name (RssDocument *self)
{
	g_return_val_if_fail (RSS_IS_DOCUMENT (self), NULL);

	return self->priv->editor;
}

/**
 * rss_document_get_editor_email:
 * @self: a #RssDocument
 *
 * Retrieves the #RssDocument:editor-email field.
 *
 * Return value: the contents of the field. The returned string is
 *   owned by the #RssDocument and should never be modified of freed
 */
const gchar *
rss_document_get_editor_email (RssDocument *self)
{
	g_return_val_if_fail (RSS_IS_DOCUMENT (self), NULL);

	return self->priv->editor_email;
}

/**
 * rss_document_get_editor_uri:
 * @self: a #RssDocument
 *
 * Retrieves the #RssDocument:editor-uri field.
 *
 * Return value: the contents of the field. The returned string is
 *   owned by the #RssDocument and should never be modified of freed
 */
const gchar *
rss_document_get_editor_uri (RssDocument *self)
{
	g_return_val_if_fail (RSS_IS_DOCUMENT (self), NULL);

	return self->priv->editor_uri;
}

/**
 * rss_document_get_contributor:
 * @self: a #RssDocument
 *
 * Retrieves the #RssDocument:contributor field.
 *
 * Return value: the contents of the field. The returned string is
 *   owned by the #RssDocument and should never be modified of freed
 */
const gchar *
rss_document_get_contributor_name (RssDocument *self)
{
	g_return_val_if_fail (RSS_IS_DOCUMENT (self), NULL);

	return self->priv->contributor;
}

/**
 * rss_document_get_contributor_email:
 * @self: a #RssDocument
 *
 * Retrieves the #RssDocument:contributor-email field.
 *
 * Return value: the contents of the field. The returned string is
 *   owned by the #RssDocument and should never be modified of freed
 */
const gchar *
rss_document_get_contributor_email (RssDocument *self)
{
	g_return_val_if_fail (RSS_IS_DOCUMENT (self), NULL);

	return self->priv->contributor_email;
}

/**
 * rss_document_get_contributor_uri:
 * @self: a #RssDocument
 *
 * Retrieves the #RssDocument:contributor-uri field.
 *
 * Return value: the contents of the field. The returned string is
 *   owned by the #RssDocument and should never be modified of freed
 */
const gchar *
rss_document_get_contributor_uri (RssDocument *self)
{
	g_return_val_if_fail (RSS_IS_DOCUMENT (self), NULL);

	return self->priv->contributor_uri;
}

/**
 * rss_document_get_generator_name:
 * @self: a #RssDocument
 *
 * Retrieves the #RssDocument:generator-name field.
 *
 * Return value: the contents of the field. The returned string is
 *   owned by the #RssDocument and should never be modified of freed
 */
const gchar *
rss_document_get_generator_name (RssDocument *self)
{
	g_return_val_if_fail (RSS_IS_DOCUMENT (self), NULL);

	return self->priv->generator;
}

/**
 * rss_document_get_generator_uri:
 * @self: a #RssDocument
 *
 * Retrieves the #RssDocument:generator-uri field.
 *
 * Return value: the contents of the field. The returned string is
 *   owned by the #RssDocument and should never be modified of freed
 */
const gchar *
rss_document_get_generator_uri (RssDocument *self)
{
	g_return_val_if_fail (RSS_IS_DOCUMENT (self), NULL);

	return self->priv->generator_uri;
}

/**
 * rss_document_get_generator_version:
 * @self: a #RssDocument
 *
 * Retrieves the #RssDocument:generator-version field.
 *
 * Return value: the contents of the field. The returned string is
 *   owned by the #RssDocument and should never be modified of freed
 */
const gchar *
rss_document_get_generator_version (RssDocument *self)
{
	g_return_val_if_fail (RSS_IS_DOCUMENT (self), NULL);

	return self->priv->generator_version;
}

/**
 * rss_document_get_image_title:
 * @self: a #RssDocument
 *
 * Retrieves the #RssDocument:image-title field.
 *
 * Return value: the contents of the field. The returned string is
 *   owned by the #RssDocument and should never be modified of freed
 */
const gchar *
rss_document_get_image_title (RssDocument *self)
{
	g_return_val_if_fail (RSS_IS_DOCUMENT (self), NULL);

	return self->priv->image_title;
}

/**
 * rss_document_get_image_url:
 * @self: a #RssDocument
 *
 * Retrieves the #RssDocument:image-url field.
 *
 * Return value: the contents of the field. The returned string is
 *   owned by the #RssDocument and should never be modified of freed
 */
const gchar *
rss_document_get_image_url (RssDocument *self)
{
	g_return_val_if_fail (RSS_IS_DOCUMENT (self), NULL);

	return self->priv->image_url;
}

/**
 * rss_document_get_image_link:
 * @self: a #RssDocument
 *
 * Retrieves the #RssDocument:image-link field.
 *
 * Return value: the contents of the field. The returned string is
 *   owned by the #RssDocument and should never be modified of freed
 */
const gchar *
rss_document_get_image_link (RssDocument *self)
{
	g_return_val_if_fail (RSS_IS_DOCUMENT (self), NULL);

	return self->priv->image_link;
}

/**
 * rss_document_get_ttl:
 * @self: a #RssDocument
 *
 * Retrieves the #RssDocument:ttl field.
 *
 * Return value: the contents of the field. The returned string is
 *   owned by the #RssDocument and should never be modified of freed
 */
gint
rss_document_get_ttl (RssDocument *self)
{
	g_return_val_if_fail (RSS_IS_DOCUMENT (self), 0);

	return self->priv->ttl;
}
