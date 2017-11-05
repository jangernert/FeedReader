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

	public string getPassword()
	{

		var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
		attributes["URL"] = "feedbin.com";
		attributes["Username"] = getUser();

		string passwd = "";

		try{
			passwd = Secret.password_lookupv_sync(m_pwSchema, attributes, null);
		}
		catch(GLib.Error e){
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
		var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
		attributes["URL"] = "feedbin.com";
		attributes["Username"] = getUser();
		try
		{
			Secret.password_storev_sync(m_pwSchema, attributes, Secret.COLLECTION_DEFAULT, "FeedReader: feedbin login", passwd, null);
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
		bool removed = false;
		var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
		attributes["URL"] = "feedbin.com";
		attributes["Username"] = getUser();

		Secret.password_clearv.begin (m_pwSchema, attributes, null, (obj, async_res) => {
			try
			{
				removed = Secret.password_clearv.end(async_res);
			}
			catch(GLib.Error e)
			{
				Logger.error("FeedbinUtils.deletePassword: %s".printf(e.message));
			}
		});
		return removed;
	}
}
