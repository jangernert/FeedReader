//	This file is part of FeedReader.
//
//	FeedReader is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	FeedReader is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with FeedReader.  If not, see <http://www.gnu.org/licenses/>.

public class FeedReader.FavIconManager : GLib.Object {

	private Gee.HashMap<string, Gdk.Pixbuf> m_map;
	private static FavIconManager? m_cache = null;

	public static FavIconManager get_default()
	{
		if(m_cache == null)
			m_cache = new FavIconManager();

		return m_cache;
	}

	private FavIconManager()
	{
		m_map = new Gee.HashMap<string, Gdk.Pixbuf>();
	}

	private async void load(Feed feed)
	{
		var fileName = GLib.Base64.encode(feed.getFeedID().data) + ".ico";
		try
		{
			var file = File.new_for_path(GLib.Environment.get_user_data_dir() + "/feedreader/data/feed_icons/" + fileName);
			var stream = yield file.read_async();
			var pixbuf = yield new Gdk.Pixbuf.from_stream_async(stream);
			stream.close();
			if(pixbuf.get_height() <= 1 && pixbuf.get_width() <= 1)
			{
				Logger.warning(@"FavIconManager: $fileName is too small");
				return;
			}

			pixbuf = pixbuf.scale_simple(24, 24, Gdk.InterpType.BILINEAR);
			m_map.set(feed.getFeedID(), pixbuf);
		}
		catch (IOError.NOT_FOUND e)
		{
			//Logger.debug(@"FavIconManager: Icon $fileName does not exist");
		}
		catch(Gdk.PixbufError.UNKNOWN_TYPE e)
		{
			Logger.warning(@"FavIconManager.load: Icon $fileName is an unknown type");
		}
		catch(Error e)
		{
			Logger.error(@"FavIconManager.load: $fileName: %s".printf(e.message));
		}
	}

	private bool hasIcon(Feed feed)
	{
		if(m_map == null)
		{
			m_map = new Gee.HashMap<string, Gdk.Pixbuf>();
			return false;
		}

		return m_map.has_key(feed.getFeedID());
	}

	public async Gdk.Pixbuf? getIcon(Feed feed, bool firstTry = true)
	{
		if(hasIcon(feed))
		{
			return m_map.get(feed.getFeedID()).copy();
		}
		else if(firstTry)
		{
			yield load(feed);
			return yield getIcon(feed, false);
		}

		return null;
	}

	private async void getFavIcons(Gee.List<Feed> feeds, GLib.Cancellable? cancellable = null)
	{
		// TODO: It would be nice if we could queue these in parallel
		foreach(Feed f in feeds)
		{
			if(cancellable != null && cancellable.is_cancelled())
				return;

			// try to find favicon on the website
			if(!yield downloadFavIcon(f, null, cancellable))
			{
				Logger.warning("Couldn't find a favicon for feed " + f.getTitle());
			}
		}
	}

	private async bool downloadFavIcon(Feed feed, string? hint_url = null, GLib.Cancellable? cancellable = null, string icon_path = GLib.Environment.get_user_data_dir() + "/feedreader/data/feed_icons/")
	{
		string filename_prefix = icon_path + feed.getFeedFileName();
		string local_filename = @"$filename_prefix.ico";
		string metadata_filename = @"$filename_prefix.txt";

		var metadata = yield ResourceMetadata.from_file_async(metadata_filename);
		DateTime? expires = metadata.expires;

		if(cancellable != null && cancellable.is_cancelled())
			return false;

		var now = new DateTime.now_utc();
		if(expires != null)
		{
			if(expires.to_unix() > now.to_unix())
			{
				Logger.debug("Favicon for %s is valid until %s, skipping this time".printf(feed.getTitle(), expires.to_string()));
				return yield Utils.file_exists(local_filename, FileType.REGULAR);
			}
		}

		metadata.expires = now.add_days(Constants.REDOWNLOAD_FAVICONS_AFTER_DAYS);
		yield metadata.save_to_file_async(metadata_filename);

		var obvious_icons = new Gee.ArrayList<string>();

		if(hint_url != null)
			obvious_icons.add(hint_url);

		if(feed.getIconURL() != null)
			obvious_icons.add(feed.getIconURL());

		// try domainname/favicon.ico
		var uri = new Soup.URI(feed.getURL());
		string hostname = uri.get_host();
		string siteURL = uri.get_scheme() + "://" + hostname;

		var icon_url = siteURL;
		if(!icon_url.has_suffix("/"))
			icon_url += "/";
		icon_url += "favicon.ico";
		obvious_icons.add(icon_url);

		// Try to find one of those icons
		foreach(var url in obvious_icons)
		{
			if(yield downloadIcon(feed, url, cancellable, icon_path))
				return true;

			if(cancellable != null && cancellable.is_cancelled())
				return false;
		}

		// If all else fails, download html and parse to find location of favicon
		var message_html = new Soup.Message("GET", siteURL);
		if(Settings.tweaks().get_boolean("do-not-track"))
			message_html.request_headers.append("DNT", "1");

		string html;
		try
		{
			var bodyStream = yield Utils.getSession().send_async(message_html);
			html = (string)yield Utils.inputStreamToArray(bodyStream, cancellable);
		}
		catch (Error e)
		{
			Logger.warning(@"Request for $siteURL failed: " + e.message);
			return false;
		}
		if(html != null && message_html.status_code == 200)
		{
			var html_cntx = new Html.ParserCtxt();
			html_cntx.use_options(Html.ParserOption.NOERROR + Html.ParserOption.NOWARNING);
			Html.Doc* doc = html_cntx.read_doc(html, siteURL, null, Html.ParserOption.NOERROR + Html.ParserOption.NOWARNING);
			if(doc == null)
			{
				Logger.debug(@"Utils.downloadFavIcon: parsing html on $siteURL failed");
				return false;
			}

			// check for <link rel="icon">
			var xpath = grabberUtils.getURL(doc, "//link[@rel='icon']");

			if(xpath == null)
				// check for <link rel="shortcut icon">
				xpath = grabberUtils.getURL(doc, "//link[@rel='shortcut icon']");

			if(xpath == null)
				// check for <link rel="apple-touch-icon">
				xpath = grabberUtils.getURL(doc, "//link[@rel='apple-touch-icon']");

			if(xpath != null)
			{
				xpath = grabberUtils.completeURL(xpath, siteURL);
				if(yield downloadIcon(feed, xpath, cancellable, icon_path))
					return true;
			}

			delete doc;
		}

		return false;
	}

	private async bool downloadIcon(Feed feed, string? icon_url, Cancellable? cancellable, string icon_path = GLib.Environment.get_user_data_dir() + "/feedreader/data/feed_icons/")
	{
		if(icon_url == "" || icon_url == null || GLib.Uri.parse_scheme(icon_url) == null)
		{
			Logger.warning(@"Utils.downloadIcon: icon_url not valid $icon_url");
			return false;
		}

		if(!yield Utils.ensure_path(icon_path))
			return false;

		string filename_prefix = icon_path + feed.getFeedFileName();
		string local_filename = @"$filename_prefix.ico";
		string metadata_filename = @"$filename_prefix.txt";

		var metadata = yield ResourceMetadata.from_file_async(metadata_filename);
		string etag = metadata.etag;
		string last_modified = metadata.last_modified;

		Logger.debug(@"Utils.downloadIcon: url = $icon_url");
		var message = new Soup.Message("GET", icon_url);
		if(Settings.tweaks().get_boolean("do-not-track"))
			message.request_headers.append("DNT", "1");

		if(etag != null)
			message.request_headers.append("If-None-Match", etag);
		if(last_modified != null)
			message.request_headers.append("If-Modified-Since", last_modified);

		uint8[]? data;
		try
		{
			var bodyStream = yield Utils.getSession().send_async(message, cancellable);
			data = yield Utils.inputStreamToArray(bodyStream, cancellable);
		}
		catch (Error e)
		{
			Logger.error(@"Request for $icon_url failed: " + e.message);
			return false;
		}
		var status = message.status_code;
		if(status == 304)
		{
			return true;
		}
		else if(status == 404 || data == null)
		{
			return false;
		}
		else if(status == 200)
		{
			var local_file = File.new_for_path(local_filename);
			uint8[]? local_data = null;
			try
			{
				uint8[] contents;
				yield local_file.load_contents_async(null, out contents, null);
				local_data = contents;
			}
			catch(IOError.NOT_FOUND e){}
			catch(Error e)
			{
				Logger.error(@"Error reading icon $local_filename: %s".printf(e.message));
			}

			if(local_data == null
			||(local_data != null && data != local_data))
			{
				try
				{
					yield local_file.replace_contents_async(data, null, false, FileCreateFlags.NONE, null, null);
					FileUtils.set_data(local_filename, data);
				}
				catch(Error e)
				{
					Logger.error("Error writing icon: %s".printf(e.message));
					return false;
				}
			}

			metadata.etag = message.response_headers.get_one("ETag");
			metadata.last_modified = message.response_headers.get_one("Last-Modified");

			var cache_control = message.response_headers.get_list("Cache-Control");
			if(cache_control != null)
			{
				foreach(var header in message.response_headers.get_list("Cache-Control").split(","))
				{
					var parts = header.split("=");
					if(parts.length < 2 || parts[0] != "max-age")
						continue;
					Logger.debug(parts[1]);
					var seconds = int64.parse(parts[1]);
					var expires = new DateTime.now_utc();
					expires.add_seconds(seconds);
					if(metadata.expires == null || expires.to_unix() > metadata.expires.to_unix())
						metadata.expires = expires;
				}
			}
			metadata.last_modified = message.response_headers.get_one("Last-Modified");
			yield metadata.save_to_file_async(metadata_filename);
			return true;
		}
		Logger.warning(@"Could not download icon for feed: %s $icon_url, got response code $status".printf(feed.getFeedID()));
		return false;
	}
}
