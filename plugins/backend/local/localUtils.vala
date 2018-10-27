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

	public Feed? downloadFeed(Soup.Session session, string xmlURL, string feedID, Gee.List<string> catIDs, out string errmsg)
	{
		errmsg = "";

		// download
		//Logger.debug(@"Requesting: $xmlURL");
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

		var Feed = new Feed(
					feedID,
					doc.title,
					url,
					0,
					catIDs,
					doc.image_url,
					xmlURL);

		return Feed;
	}

	public string? convert(string? text, string? locale)
	{
		if(text == null)
			return null;

		if(locale == null)
			return text;

		try
		{
			return GLib.convert(text, -1, "utf-8", locale);
		}
		catch(ConvertError e)
		{
			Logger.error(e.message);
		}

		return "";
	}
}
