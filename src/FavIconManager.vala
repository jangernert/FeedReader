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

	private Gee.Map<string, Gee.Future<Gdk.Pixbuf?>> m_map = new Gee.HashMap<string, Gee.Future<Gdk.Pixbuf?>>();
	private static FavIconManager? m_cache = null;

	public static FavIconManager get_default()
	{
		if(m_cache == null)
			m_cache = new FavIconManager();

		return m_cache;
	}

	private FavIconManager()
	{
	}

	public async Gdk.Pixbuf? getIcon(Feed feed)
	{
		try
		{
			var feed_id = feed.getFeedID();
			var future = m_map.get(feed_id);
			if(future == null)
			{
				var promise = new Gee.Promise<Gdk.Pixbuf?>();
				try
				{
					future = promise.future;
					m_map.set(feed_id, future);

					var stream = yield downloadFavIcon(feed);
					if(stream == null)
						return null;

					var pixbuf = yield new Gdk.Pixbuf.from_stream_async(stream);
					stream.close();

					if(pixbuf.get_height() <= 1 && pixbuf.get_width() <= 1)
					{
						Logger.warning(@"FavIconManager: Icon for feed %s is too small".printf(feed.getTitle()));
						return null;
					}
					pixbuf = pixbuf.scale_simple(24, 24, Gdk.InterpType.BILINEAR);

					promise.set_value(pixbuf);
				}
				finally
				{
					if(!future.ready)
						promise.set_value(null);
				}
			}
			return yield future.wait_async();
		}
		catch(Error e)
		{
			Logger.error("FavIconManager.getIcon: %s".printf(e.message));
			return null;
		}
	}

	private async InputStream? downloadFavIcon(Feed feed, GLib.Cancellable? cancellable = null, string icon_path = GLib.Environment.get_user_data_dir() + "/feedreader/data/feed_icons/") throws GLib.Error
	{
		string filename_prefix = icon_path + feed.getFeedFileName();
		string local_filename = @"$filename_prefix.ico";
		string metadata_filename = @"$filename_prefix.txt";

		var metadata = yield ResourceMetadata.from_file_async(metadata_filename);
		DateTime? expires = metadata.expires;

		if(cancellable != null && cancellable.is_cancelled())
			return null;

		var now = new DateTime.now_utc();
		if(expires != null)
		{
			if(expires.to_unix() > now.to_unix())
			{
				Logger.debug("Favicon for %s is valid until %s, skipping this time".printf(feed.getTitle(), expires.to_string()));
				var file = File.new_for_path(local_filename);
				try
				{
					return yield file.read_async();
				}
				catch(IOError.NOT_FOUND e)
				{
					return null;
				}
			}
		}

		var default_expires = now.add_days(Constants.REDOWNLOAD_FAVICONS_AFTER_DAYS);
		if(metadata.expires == null || metadata.expires.to_unix() < default_expires.to_unix())
		{
			metadata.expires = default_expires;
			yield metadata.save_to_file_async(metadata_filename);
		}

		var obvious_icons = new Gee.ArrayList<string>();

		if(feed.getIconURL() != null)
			obvious_icons.add(feed.getIconURL());

		// try domainname/favicon.ico
		var uri = new Soup.URI(feed.getURL());
		string? siteURL = null;
		if(uri != null)
		{
			string hostname = uri.get_host();
			siteURL = uri.get_scheme() + "://" + hostname;

			var icon_url = siteURL;
			if(!icon_url.has_suffix("/"))
				icon_url += "/";
			icon_url += "favicon.ico";
			obvious_icons.add(icon_url);
		}

		// Try to find one of those icons
		foreach(var url in obvious_icons)
		{
			var stream = yield downloadIcon(feed, url, cancellable, icon_path);
			if(stream != null)
				return stream;

			if(cancellable != null && cancellable.is_cancelled())
				return null;
		}

		// If all else fails, download html and parse to find location of favicon
		if(siteURL == null)
			return null;

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
			return null;
		}
		if(html != null && message_html.status_code == 200)
		{
			var html_cntx = new Html.ParserCtxt();
			html_cntx.use_options(Html.ParserOption.NOERROR + Html.ParserOption.NOWARNING);
			Html.Doc* doc = html_cntx.read_doc(html, siteURL, null, Html.ParserOption.NOERROR + Html.ParserOption.NOWARNING);
			if(doc == null)
			{
				Logger.debug(@"Utils.downloadFavIcon: parsing html on $siteURL failed");
				return null;
			}

			try
			{
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
					return yield downloadIcon(feed, xpath, cancellable, icon_path);
				}
			}
			finally
			{
				delete doc;
			}
		}

		return null;
	}

	private async InputStream? downloadIcon(Feed feed, string? icon_url, Cancellable? cancellable, string icon_path = GLib.Environment.get_user_data_dir() + "/feedreader/data/feed_icons/") throws GLib.Error
	{
		if(icon_url == "" || icon_url == null || GLib.Uri.parse_scheme(icon_url) == null)
		{
			Logger.warning(@"Utils.downloadIcon: icon_url not valid $icon_url");
			return null;
		}

		if(!yield Utils.ensure_path(icon_path))
			return null;

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
			return null;
		}
		var status = message.status_code;
		if(status == 304)
		{
			var file = File.new_for_path(local_filename);
			return yield file.read_async();
		}
		else if(status == 404 || data == null)
		{
			return null;
		}
		else if(status == 200)
		{
			var local_file = File.new_for_path(local_filename);
			try
			{
				yield local_file.replace_contents_async(data, null, false, FileCreateFlags.NONE, null, null);
			}
			catch(Error e)
			{
				Logger.error("Error writing icon: %s".printf(e.message));
				return null;
			}

			metadata.etag = message.response_headers.get_one("ETag");
			metadata.last_modified = message.response_headers.get_one("Last-Modified");

			var cache_control = message.response_headers.get_list("Cache-Control");
			metadata.expires = new DateTime.now_utc().add_days(Constants.REDOWNLOAD_FAVICONS_AFTER_DAYS);;
			if(cache_control != null)
			{
				foreach(var header in message.response_headers.get_list("Cache-Control").split(","))
				{
					var parts = header.split("=");
					if(parts.length < 2 || parts[0] != "max-age")
						continue;
					var seconds = int64.parse(parts[1]);
					var expires = new DateTime.now_utc();
					expires.add_seconds(seconds);
					if(expires.to_unix() > metadata.expires.to_unix())
						metadata.expires = expires;
				}
			}

			metadata.last_modified = message.response_headers.get_one("Last-Modified");
			yield metadata.save_to_file_async(metadata_filename);
			return new MemoryInputStream.from_data(data);
		}

		Logger.warning(@"Could not download icon for feed: %s $icon_url, got response code $status".printf(feed.getFeedID()));
		return null;
	}
}
