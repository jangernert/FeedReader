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
		return Utils.gsettingReadString(m_settings, "username");
	}

	public void setUser(string user)
	{
		Utils.gsettingWriteString(m_settings, "username", user);
	}

	public string getAccessToken()
	{
		return Utils.gsettingReadString(m_settings, "access-token");
	}

	public void setAccessToken(string token)
	{
		Utils.gsettingWriteString(m_settings, "access-token", token);
	}

	public string getUserID()
	{
		return Utils.gsettingReadString(m_settings, "user-id");
	}

	public void setUserID(string id)
	{
		Utils.gsettingWriteString(m_settings, "user-id", id);
	}

	public void resetAccount()
	{
		Utils.resetSettings(m_settings);
	}

	public string getPasswd()
	{
		var pwSchema = new Secret.Schema ("org.gnome.feedreader.bazqux", Secret.SchemaFlags.NONE,
										  "type", Secret.SchemaAttributeType.STRING,
										  "Username", Secret.SchemaAttributeType.STRING);

		var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
		attributes["type"] = "BazQux";
		attributes["Username"] = getUser();
		string? passwd = "";

		try
		{
			passwd = Secret.password_lookupv_sync(pwSchema, attributes, null);
		}
		catch(GLib.Error e)
		{
			Logger.error("bazquxUtils.getPasswd: " + e.message);
		}

		if(passwd == null)
		{
			Logger.warning("bazquxUtils.getPasswd: failed to read password");
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
}
