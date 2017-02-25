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

namespace FeedReader.bazquxSecret {
	 const string base_uri        = "https://www.bazqux.com/reader/api/0/";
}

public class FeedReader.bazquxUtils : GLib.Object {

	private GLib.Settings m_settings;

	public bazquxUtils()
	{
		m_settings = new GLib.Settings("org.gnome.feedreader.bazqux");
	}

	public string getUser()
	{
		return m_settings.get_string("username");
	}

	public void setUser(string user)
	{
		m_settings.set_string("username", user);
	}

	public string getAccessToken()
	{
		return m_settings.get_string("access-token");
	}

	public void setAccessToken(string token)
	{
		m_settings.set_string("access-token", token);
	}

	public string getUserID()
	{
		return m_settings.get_string("user-id");
	}

	public void setUserID(string id)
	{
		m_settings.set_string("user-id", id);
	}

	public void resetAccount()
	{
		Utils.resetSettings(m_settings);
	}

	public bool downloadIcon(string feed_id, string icon_url)
	{
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

		string local_filename = icon_path + feed_id.replace("/", "_").replace(".", "_") + ".ico";

		if(!FileUtils.test(local_filename, GLib.FileTest.EXISTS))
		{
			Soup.Message message_dlIcon;
			message_dlIcon = new Soup.Message("GET", icon_url);

			if(settingsTweaks.get_boolean("do-not-track"))
				message_dlIcon.request_headers.append("DNT", "1");

			var session = new Soup.Session();
			session.ssl_strict = false;
			var status = session.send_message(message_dlIcon);
			if (status == 200)
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

	public string getPasswd()
	{
		var pwSchema = new Secret.Schema ("org.gnome.feedreader.bazqux", Secret.SchemaFlags.NONE,
		                                  "type", Secret.SchemaAttributeType.STRING,
		                                  "Username", Secret.SchemaAttributeType.STRING);

		var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
		attributes["type"] = "BazQux";
		attributes["Username"] = getUser();
		string passwd = "";

		try
		{
			passwd = Secret.password_lookupv_sync(pwSchema, attributes, null);
		}
		catch(GLib.Error e)
		{
			Logger.error(e.message);
		}

		if(passwd == null)
		{
			return "";
		}

		return passwd;
	}

	public void setPassword(string passwd)
	{
		var pwSchema = new Secret.Schema ("org.gnome.feedreader.bazqux", Secret.SchemaFlags.NONE,
										  "type", Secret.SchemaAttributeType.STRING,
										  "Username", Secret.SchemaAttributeType.STRING);
		var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
		attributes["type"] = "BazQux";
		attributes["Username"] = getUser();
		try
		{
			Secret.password_storev_sync(pwSchema, attributes, Secret.COLLECTION_DEFAULT, "Feedserver login", passwd, null);
		}
		catch(GLib.Error e)
		{
			Logger.error("bazquxUtils.setPassword: " + e.message);
		}
	}
}
