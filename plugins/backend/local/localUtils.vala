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

	public feed ? downloadFeed(Soup.Session session, string xmlURL, string feedID, string[] catIDs, out string errmsg)
	{
		errmsg = "";

		// download
		Logger.debug(@"Requesting: $xmlURL");
		var msg = new Soup.Message("GET", xmlURL);
		if (msg == null)
		{
			errmsg = @"Couldn't parse feed URL: $xmlURL";
			Logger.warning(errmsg);
			return null;
		}
		uint status = session.send_message(msg);
		if(status != 200)
		{
			errmsg = "Could not download feed";
			Logger.warning(errmsg);
			return null;
		}
		string xml = (string)msg.response_body.flatten().data;
		string url = "https://google.com";

		// parse
		Rss.Parser parser = new Rss.Parser();

		try
		{
			parser.load_from_data(xml, xml.length);
		}
		catch(Error e)
		{
			errmsg = "Could not parse feed";
			Logger.warning(errmsg);
			return null;
		}

		var doc = parser.get_document();

		if(doc.link != null
		   && doc.link != "")
			url = doc.link;

		var uri = new Soup.URI(url);
		string ? icon_url = (doc.image_url != "") ? doc.image_url : null;
		string ? title = doc.title;
		if(title == null)
		{
			if(uri == null)
				title = _("unknown Feed");
			else
				title = uri.get_host();
		}

		var Feed = new feed(
			feedID,
			title,
			url,
			0,
			catIDs,
			icon_url,
			xmlURL);

		return Feed;
	}

	public string ? convert(string ? text, string ? locale)
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
