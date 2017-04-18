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

namespace FeedReader.FeedHQSecret {
	 const string base_uri        = "https://feedhq.org/reader/api/0/";
}

public class FeedReader.FeedHQUtils : GLib.Object {

	private GLib.Settings m_settings;

	public FeedHQUtils()
	{
		m_settings = new GLib.Settings("org.gnome.feedreader.feedhq");
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

	public string getPostToken()
	{
		return m_settings.get_string("post-token");
	}

	public void setPostToken(string token)
	{
		m_settings.set_string("post-token", token);
	}
	public string getUserID()
	{
		return m_settings.get_string("user-id");
	}

	public void setUserID(string id)
	{
		m_settings.set_string("user-id", id);
	}

	public string getEmail()
	{
		return m_settings.get_string("user-email");
	}

	public void setEmail(string email)
	{
		m_settings.set_string("user-email", email);
	}

	public void resetAccount()
	{
		Utils.resetSettings(m_settings);
	}

	public bool tagIsCat(string tagID, Gee.List<feed> feeds)
	{
		foreach(feed Feed in feeds)
		{
			if(Feed.hasCat(tagID))
			{
				return true;
			}
		}
		return false;
	}

	public string getPasswd()
	{
		var pwSchema = new Secret.Schema ("org.gnome.feedreader.feedhq", Secret.SchemaFlags.NONE,
		                                  "type", Secret.SchemaAttributeType.STRING,
		                                  "Username", Secret.SchemaAttributeType.STRING);

		var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
		attributes["type"] = "FeedHQ";
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
		var pwSchema = new Secret.Schema ("org.gnome.feedreader.feedhq", Secret.SchemaFlags.NONE,
										  "type", Secret.SchemaAttributeType.STRING,
										  "Username", Secret.SchemaAttributeType.STRING);

		var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
		attributes["type"] = "FeedHQ";
		attributes["Username"] = getUser();
		try
		{
			Secret.password_storev_sync(pwSchema, attributes, Secret.COLLECTION_DEFAULT, "Feedserver login", passwd, null);
		}
		catch(GLib.Error e)
		{
			Logger.error("feedhqUtils: setPassword: " + e.message);
		}
	}
}
