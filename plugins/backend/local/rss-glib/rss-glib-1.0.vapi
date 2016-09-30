/* rss-glib-1.0.vapi
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

[CCode (cprefix = "Rss", lower_case_cprefix = "rss_", cheader_filename = "rss-glib.h")]
namespace Rss {
	public errordomain ParserError {
		INVALID_DATA
	}

	public class Parser : GLib.Object {
		public Parser ();
		public bool load_from_data (string data, ulong length) throws Rss.ParserError;
		public bool load_from_file (string filename) throws Rss.ParserError;
		public Rss.Document get_document ();
	}

	public class Document : GLib.Object {
		[NoAccessorMethod]
		public string encoding { owned get; set; }
		[NoAccessorMethod]
		public string guid { owned get; set; }
		[NoAccessorMethod]
		public string title { owned get; set; }
		[NoAccessorMethod]
		public string description { owned get; set; }
		[NoAccessorMethod]
		public string link { owned get; set; }
		[NoAccessorMethod]
		public string language { owned get; set; }
		[NoAccessorMethod]
		public string rating { owned get; set; }
		[NoAccessorMethod]
		public string copyright { owned get; set; }
		[NoAccessorMethod]
		public string pub_date { owned get; set; }
		[NoAccessorMethod]
		public string editor { owned get; set; }
		[NoAccessorMethod]
		public string editor_email { owned get; set; }
		[NoAccessorMethod]
		public string editor_uri { owned get; set; }
		[NoAccessorMethod]
		public int ttl { owned get; set; }
		[NoAccessorMethod]
		public string about { owned get; set; }
		[NoAccessorMethod]
		public string contributor { owned get; set; }
		[NoAccessorMethod]
		public string contributor_email { owned get; set; }
		[NoAccessorMethod]
		public string contributor_uri { owned get; set; }
		[NoAccessorMethod]
		public string generator { owned get; set; }
		[NoAccessorMethod]
		public string generator_uri { owned get; set; }
		[NoAccessorMethod]
		public string generator_version { owned get; set; }
		[NoAccessorMethod]
		public string image_title { owned get; set; }
		[NoAccessorMethod]
		public string image_url { owned get; set; }
		[NoAccessorMethod]
		public string image_link { owned get; set; }
		public Document ();
		public GLib.List<weak Rss.Item> get_items ();
		public GLib.List<string> get_categories ();
	}

	public class Item : GLib.Object {
		[NoAccessorMethod]
		public string guid { owned get; set; }
		[NoAccessorMethod]
		public string title { owned get; set; }
		[NoAccessorMethod]
		public string link { owned get; set; }
		[NoAccessorMethod]
		public string description { owned get; set; }
		[NoAccessorMethod]
		public string copyright{ owned get; set; }
		[NoAccessorMethod]
		public string author { owned get; set; }
		[NoAccessorMethod]
		public string author_uri { owned get; set; }
		[NoAccessorMethod]
		public string author_email { owned get; set; }
		[NoAccessorMethod]
		public string contributor { owned get; set; }
		[NoAccessorMethod]
		public string contributor_uri { owned get; set; }
		[NoAccessorMethod]
		public string contributor_email { owned get; set; }
		[NoAccessorMethod]
		public string comments { owned get; set; }
		[NoAccessorMethod]
		public string pub_date { owned get; set; }
		[NoAccessorMethod]
		public string source { owned get; set; }
		[NoAccessorMethod]
		public string source_url { owned get; set; }
        [NoAccessorMethod]
		public string enclosure { owned get; set; }
		[NoAccessorMethod]
		public string enclosure_url { owned get; set; }
		public Item ();
		public GLib.List<string> get_categories ();
	}
}
