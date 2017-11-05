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

namespace FeedReader.OldReaderSecret {
	 const string base_uri        = "https://theoldreader.com/reader/api/0/";
}

public class FeedReader.OldReaderUtils : GLib.Object {

	private GLib.Settings m_settings;
	private Password m_password;

	public OldReaderUtils(GLib.SettingsBackend settings_backend, Secret.Collection secrets)
	{
		m_settings = new GLib.Settings.with_backend("org.gnome.feedreader.oldreader", settings_backend);

		var pwSchema = new Secret.Schema ("org.gnome.feedreader.oldreader", Secret.SchemaFlags.NONE,
										  "type", "oldreader",
										  "Username", Secret.SchemaAttributeType.STRING);
		m_password = new Password(secrets, pwSchema, "FeedReader: oldreader login", () => {
			var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
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
		m_password.delete_password();
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
