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

public class FeedReader.localUtils : GLib.Object {

	public localUtils()
	{

	}

	public feed? downloadFeed(string xmlURL, string feedID, string[] catIDs)
	{
		if(xmlURL == "" || xmlURL == null || GLib.Uri.parse_scheme(xmlURL) == null)
            return null;

		try
		{
			// download
			var session = new Soup.Session();
			session.user_agent = Constants.USER_AGENT;
	        session.timeout = 5;
	        var msg = new Soup.Message("GET", xmlURL.escape(""));
			session.send_message(msg);
			string xml = (string)msg.response_body.flatten().data;
			bool hasIcon = true;
			string url = "https://google.com";

			// parse
			Rss.Parser parser = new Rss.Parser();
			parser.load_from_data(xml, xml.length);
			var doc = parser.get_document();

			if(doc.link != null
			&& doc.link != "")
				url = doc.link;

			if(doc.image_url != null
			&& doc.image_url != "")
			{
				downloadIcon(feedID, doc.image_url);
			}
			else if(doc.link != null
			&& doc.link != "")
			{
				Utils.downloadIcon(feedID, doc.link);
			}
			else
				hasIcon = false;

			var Feed = new feed(
						feedID,
						doc.title,
						url,
						hasIcon,
						0,
						catIDs,
						xmlURL);

			return Feed;
		}
		catch(GLib.Error e)
		{
			Logger.error("localInterface - addFeed " + xmlURL + " : " + e.message);
		}

		return null;
	}

	public string? convert(string? text, string? locale)
	{
		if(text == null)
			return null;

		if(locale == null)
			return Utils.UTF8fix(text, false);

		try
		{
			return Utils.UTF8fix(GLib.convert(text, -1, "utf-8", locale), false);
		}
		catch(ConvertError e)
		{
			Logger.error(e.message);
		}

		return "";
	}

	public bool deleteIcon(string feedID)
	{
		try
		{
			string icon_path = GLib.Environment.get_home_dir() + "/.local/share/feedreader/data/feed_icons/";
			var file = GLib.File.new_for_path(icon_path + feedID + ".ico");
			file.delete();
			return true;
		}
		catch(GLib.Error e)
		{
			Logger.error("localUtils - deleteIcon: " + e.message);
		}
		return false;
	}

	private bool downloadIcon(string feed_id, string icon_url)
	{
		if(icon_url == "" || icon_url == null || GLib.Uri.parse_scheme(icon_url) == null)
            return false;

		var settingsTweaks = new GLib.Settings("org.gnome.feedreader.tweaks");
		string icon_path = GLib.Environment.get_home_dir() + "/.local/share/feedreader/data/feed_icons/";
		var path = GLib.File.new_for_path(icon_path);
		try
		{
			path.make_directory_with_parents();
		}
		catch(GLib.Error e)
		{
			//Logger.debug(e.message);
		}

		string local_filename = icon_path + feed_id + ".ico";

		if(!FileUtils.test(local_filename, GLib.FileTest.EXISTS))
		{
			Soup.Message message_dlIcon;
			message_dlIcon = new Soup.Message("GET", icon_url);

			if(settingsTweaks.get_boolean("do-not-track"))
				message_dlIcon.request_headers.append("DNT", "1");

			var session = new Soup.Session();
			session.user_agent = Constants.USER_AGENT;
			session.ssl_strict = false;
			var status = session.send_message(message_dlIcon);
			if(status == 200)
			{
				try{
					FileUtils.set_contents(	local_filename,
											(string)message_dlIcon.response_body.flatten().data,
											(long)message_dlIcon.response_body.length);
				}
				catch(GLib.FileError e)
				{
					Logger.error("Error writing icon: %s".printf(e.message));
				}
				return true;
			}
			Logger.error("Error downloading icon for feed: %s".printf(feed_id));
			return false;
		}

		// file already exists
		return true;
	}
}
