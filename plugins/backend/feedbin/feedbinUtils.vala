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

public class FeedReader.FeedbinUtils : GLib.Object {
	static Secret.Schema m_pwSchema =
		new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
						   "URL", Secret.SchemaAttributeType.STRING,
						   "Username", Secret.SchemaAttributeType.STRING);

	GLib.Settings m_settings;

	public FeedbinUtils(GLib.SettingsBackend settings_backend)
	{
		m_settings = new GLib.Settings.with_backend("org.gnome.feedreader.feedbin", settings_backend);
	}

	public string getUser()
	{
		return Utils.gsettingReadString(m_settings, "username");
	}

	public void setUser(string user)
	{
		Utils.gsettingWriteString(m_settings, "username", user);
	}

	private HashTable<string, string> getPasswordAttributes()
	{
		var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
		attributes["URL"] = "feedbin.com";
		attributes["Username"] = getUser();
		return attributes;
	}

	public string getPassword()
	{

		var attributes = getPasswordAttributes();
		try
		{
			var password = Secret.password_lookupv_sync(m_pwSchema, attributes, null);
			if(password != null)
				return password;
		}
		catch(GLib.Error e)
		{
			Logger.error(e.message);
		}
		return "";
	}

	public void setPassword(string passwd)
	{
		var attributes = getPasswordAttributes();
		try
		{
			Secret.password_storev_sync(m_pwSchema, attributes, Secret.COLLECTION_DEFAULT, "FeedReader: feedbin login", passwd);
		}
		catch(GLib.Error e)
		{
			Logger.error("FeedbinUtils: setPassword: " + e.message);
		}
	}

	public void resetAccount()
	{
		Utils.resetSettings(m_settings);
		deletePassword();
	}

	public bool deletePassword()
	{
		var attributes = getPasswordAttributes();
		try
		{
			return Secret.password_clearv_sync (m_pwSchema, attributes, null);
		}
		catch(GLib.Error e)
		{
			Logger.error("FeedbinUtils.deletePassword: %s".printf(e.message));
			return false;
		}
	}
}
