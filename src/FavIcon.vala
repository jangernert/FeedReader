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
public class FeedReader.FavIcon : GLib.Object
{
	private static string m_icon_path = GLib.Environment.get_user_data_dir() + "/feedreader/data/feed_icons/";
	private static Gee.Map<string, FavIcon> m_map = null;

	public static FavIcon for_feed(Feed feed)
	{
		if(m_map == null)
			m_map = new Gee.HashMap<string, FavIcon>();

		var feed_id = feed.getFeedID();
		var icon = m_map.get(feed_id);
		if(icon == null)
		{
			icon = new FavIcon(feed);
			m_map.set(feed_id, icon);
		}

		return icon;
	}

	private Feed m_feed;
	private Gee.Promise<Gdk.Pixbuf?> m_icon = null;
	private ResourceMetadata m_metadata;

	public signal void pixbuf_changed(Feed feed, Gdk.Pixbuf pixbuf);

	private FavIcon(Feed feed)
	{
		m_feed = feed;
	}

	public async Gdk.Pixbuf? get_pixbuf()
	{
		if(m_icon == null || m_metadata.is_expired())
		{
			m_icon = new Gee.Promise<Gdk.Pixbuf?>();
			load.begin((obj, res) => {
				load.end(res);
			});
		}
		try
		{
			return yield m_icon.future.wait_async();
		}
		catch(Error e)
		{
			Logger.error("FavIcon.get_pixbuf: " + e.message);
			return null;
		}
	}

	private async void load()
	{
		try
		{
			var stream = yield downloadFavIcon();
			if(stream == null)
				return;

			var pixbuf = yield new Gdk.Pixbuf.from_stream_async(stream);
			stream.close();

			if(pixbuf.get_height() <= 1 && pixbuf.get_width() <= 1)
			{
				Logger.warning("FavIcon: Icon for feed %s is too small".printf(m_feed.getTitle()));
				return;
			}
			pixbuf = pixbuf.scale_simple(24, 24, Gdk.InterpType.BILINEAR);

			m_icon.set_value(pixbuf);
			if(pixbuf != null)
				pixbuf_changed(m_feed, pixbuf);
		}
		catch(Error e)
		{
			Logger.error("FavIcon.load: " + e.message);
		}
		finally
		{
			if(!m_icon.future.ready)
				m_icon.set_value(null);
		}
	}

	private async InputStream? downloadFavIcon(GLib.Cancellable? cancellable = null) throws GLib.Error
	{
		string filename_prefix = m_icon_path + m_feed.getFeedFileName();
		string local_filename = @"$filename_prefix.ico";
		string metadata_filename = @"$filename_prefix.txt";

		if(!yield Utils.ensure_path(m_icon_path))
			return null;

		m_metadata = yield ResourceMetadata.from_file_async(metadata_filename);
		DateTime? expires = m_metadata.expires;

		if(cancellable != null && cancellable.is_cancelled())
			return null;

		if(!m_metadata.is_expired())
		{
			Logger.debug("Favicon for %s is valid until %s, skipping this time".printf(m_feed.getTitle(), expires.to_string()));
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

		var default_expires = new DateTime.now_utc().add_days(Constants.REDOWNLOAD_FAVICONS_AFTER_DAYS);
		if(m_metadata.expires == null || m_metadata.expires.to_unix() < default_expires.to_unix())
		{
			m_metadata.expires = default_expires;
			yield m_metadata.save_to_file_async(metadata_filename);
		}

		var obvious_icons = new Gee.ArrayList<string>();

		if(m_feed.getIconURL() != null)
			obvious_icons.add(m_feed.getIconURL());

		// try domainname/favicon.ico
		var uri = new Soup.URI(m_feed.getURL());
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
			var stream = yield downloadIcon(url, cancellable);
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
					return yield downloadIcon(xpath, cancellable);
				}
			}
			finally
			{
				delete doc;
			}
		}

		return null;
	}

	private async InputStream? downloadIcon(string? icon_url, Cancellable? cancellable) throws GLib.Error
	{
		if(icon_url == "" || icon_url == null || GLib.Uri.parse_scheme(icon_url) == null)
		{
			Logger.warning(@"Utils.downloadIcon: icon_url not valid $icon_url");
			return null;
		}

		string filename_prefix = m_icon_path + m_feed.getFeedFileName();
		string local_filename = @"$filename_prefix.ico";
		string metadata_filename = @"$filename_prefix.txt";

		string etag = m_metadata.etag;
		string last_modified = m_metadata.last_modified;

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

			m_metadata.etag = message.response_headers.get_one("ETag");
			m_metadata.last_modified = message.response_headers.get_one("Last-Modified");

			var cache_control = message.response_headers.get_list("Cache-Control");
			m_metadata.expires = new DateTime.now_utc().add_days(Constants.REDOWNLOAD_FAVICONS_AFTER_DAYS);
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
					if(expires.to_unix() > m_metadata.expires.to_unix())
						m_metadata.expires = expires;
				}
			}

			m_metadata.last_modified = message.response_headers.get_one("Last-Modified");
			yield m_metadata.save_to_file_async(metadata_filename);
			return new MemoryInputStream.from_data(data);
		}

		Logger.warning(@"Could not download icon for feed: %s $icon_url, got response code $status".printf(m_feed.getFeedID()));
		return null;
	}
}
