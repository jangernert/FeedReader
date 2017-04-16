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

	public feed? downloadFeed(Soup.Session session, string xmlURL, string feedID, string[] catIDs)
	{
		if(xmlURL == "" || xmlURL == null || GLib.Uri.parse_scheme(xmlURL) == null)
            return null;

		try
		{
			// download
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
				if(Utils.downloadIcon(session, feedID, doc.image_url))
				{
					// success
				}
				else
				{
					Utils.downloadFavIcon(session, feedID, doc.link);
				}
			}
			else if(doc.link != null
			&& doc.link != "")
			{
				Utils.downloadFavIcon(session, feedID, doc.link);
			}
			else
				hasIcon = false;

			string? title = doc.title;
			if(title == null)
			{
				var uri = new Soup.URI(xmlURL);
				if(uri == null)
					title = _("unknown Feed");
				else
					title = uri.get_host();
			}

			var Feed = new feed(
						feedID,
						title,
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
			string icon_path = GLib.Environment.get_user_data_dir() + "/feedreader/data/feed_icons/";
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
}
