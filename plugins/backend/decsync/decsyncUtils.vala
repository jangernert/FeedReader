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

public class FeedReader.DecsyncUtils : GLib.Object {

GLib.Settings m_settings;

public DecsyncUtils(GLib.SettingsBackend? settings_backend)
{
	if(settings_backend != null)
		m_settings = new GLib.Settings.with_backend("org.gnome.feedreader.decsync", settings_backend);
	else
		m_settings = new GLib.Settings("org.gnome.feedreader.decsync");
}

public string getDecsyncDir()
{
	var dir = Utils.gsettingReadString(m_settings, "decsync-dir");
	if (dir == "")
	{
		return GLib.Environment.get_variable("DECSYNC_DIR") ?? getDefaultDecsyncBaseDir();
	}
	else
	{
		return dir;
	}
}

public void setDecsyncDir(string decsyncDir)
{
	Utils.gsettingWriteString(m_settings, "decsync-dir", decsyncDir);
}

public Feed? downloadFeed(Soup.Session session, string feed_url, string feedID, Gee.List<string> catIDs, out string errmsg)
{
	var error = new StringBuilder(_("Failed to add feed"));
	error.append_printf(" %s\n", feed_url);

	var msg = new Soup.Message("GET", feed_url);
	if (msg == null)
	{
		error.append(_("Failed to parse URL."));
		errmsg = error.str;
		Logger.warning(errmsg);
		return null;
	}

	uint status = session.send_message(msg);
	if(status < 100 || status >= 400)
	{
		if(status < 100)
		{
			error.append(_("Network error connecting to the server."));
		}
		else
		{
			error.append(_("Got HTTP error code"));
			error.append_printf(" %u %s", status, Soup.Status.get_phrase(status));
		}

		errmsg = error.str;
		Logger.warning(errmsg);
		return null;
	}
	string xml = (string)msg.response_body.flatten().data;
	string? url = null;

	// parse
	Rss.Parser parser = new Rss.Parser();
	try
	{
		parser.load_from_data(xml, xml.length);
	}
	catch(Error e)
	{
		error.append(_("Could not parse feed as RSS or ATOM."));
		errmsg = error.str;
		Logger.warning(errmsg);
		return null;
	}

	var doc = parser.get_document();

	if(doc.link != null
	   && doc.link != "")
		url = doc.link;

	errmsg = "";
	return new Feed(
		feedID,
		doc.title,
		url,
		0,
		catIDs,
		doc.image_url,
		feed_url);
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
