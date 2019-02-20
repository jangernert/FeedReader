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
	private Password m_password;

	public FeedHQUtils(GLib.SettingsBackend? settings_backend, Secret.Collection secrets)
	{
		if(settings_backend != null)
		{
			m_settings = new GLib.Settings.with_backend("org.gnome.feedreader.feedhq", settings_backend);
		}
		else
		{
			m_settings = new GLib.Settings("org.gnome.feedreader.feedhq");
		}

		var pwSchema = new Secret.Schema ("org.gnome.feedreader.feedhq", Secret.SchemaFlags.NONE,
			"type", Secret.SchemaAttributeType.STRING,
		"Username", Secret.SchemaAttributeType.STRING);
		m_password = new Password(secrets, pwSchema, "Feedserver login", () => {
			var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
			attributes["type"] = "FeedHQ";
			attributes["Username"] = getUser();
			return attributes;
		});
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

	public string getPostToken()
	{
		return Utils.gsettingReadString(m_settings, "post-token");
	}

	public void setPostToken(string token)
	{
		Utils.gsettingWriteString(m_settings, "post-token", token);
	}
	public string getUserID()
	{
		return Utils.gsettingReadString(m_settings, "user-id");
	}

	public void setUserID(string id)
	{
		Utils.gsettingWriteString(m_settings, "user-id", id);
	}

	public string getEmail()
	{
		return Utils.gsettingReadString(m_settings, "user-email");
	}

	public void setEmail(string email)
	{
		Utils.gsettingWriteString(m_settings, "user-email", email);
	}

	public void resetAccount()
	{
		Utils.resetSettings(m_settings);
		m_password.delete_password();
	}

	public bool tagIsCat(string tagID, Gee.List<Feed> feeds)
	{
		foreach(Feed feed in feeds)
		{
			if(feed.hasCat(tagID))
			{
				return true;
			}
		}
		return false;
	}

	public string getPasswd()
	{
		return m_password.get_password();
	}

	public void setPassword(string passwd)
	{
		m_password.set_password(passwd);
	}
}
