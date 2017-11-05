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

	Secret.Collection m_secrets;
	GLib.Settings m_settings;

	public FeedbinUtils(GLib.SettingsBackend settings_backend, Secret.Collection secrets)
	{
		m_settings = new GLib.Settings.with_backend("org.gnome.feedreader.feedbin", settings_backend);
		m_secrets = secrets;
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

	public string getPassword(Cancellable? cancellable = null)
	{
		var attributes = getPasswordAttributes();
		try
		{
			var secrets = m_secrets.search_sync(m_pwSchema, attributes, Secret.SearchFlags.NONE, cancellable);

			if(cancellable != null && cancellable.is_cancelled())
				return "";

			if(secrets.length() != 0)
			{
				var item = secrets.data;
				item.load_secret_sync(cancellable);
				if(cancellable != null && cancellable.is_cancelled())
					return "";

				var secret = item.get_secret();
				if(secret == null)
				{
					Logger.error("FeedbinUtils.getPassword: Got NULL secret");
					return "";
				}
				var password = secret.get_text();
				if(password == null)
				{
					Logger.error("FeedbinUtils.getPassword: Got NULL password in non-NULL secret");
					return "";
				}
				return password;
			}
		}
		catch(GLib.Error e)
		{
			Logger.error(e.message);
		}
		return "";
	}

	public void setPassword(string password, Cancellable? cancellable = null)
	{
		var attributes = getPasswordAttributes();
		try
		{
			var value = new Secret.Value(password, password.length, "text/plain");
			Secret.Item.create_sync(m_secrets, m_pwSchema, attributes, "FeedReader: feedbin login", value, Secret.ItemCreateFlags.REPLACE, cancellable);
		}
		catch(GLib.Error e)
		{
			Logger.error("FeedbinUtils: setPassword: " + e.message);
		}
	}

	public void resetAccount(Cancellable? cancellable = null)
	{
		Utils.resetSettings(m_settings);
		deletePassword(cancellable);
	}

	public bool deletePassword(Cancellable? cancellable = null)
	{
		var attributes = getPasswordAttributes();
		try
		{
			var secrets = m_secrets.search_sync(m_pwSchema, attributes, Secret.SearchFlags.NONE, cancellable);

			if(cancellable != null && cancellable.is_cancelled())
				return false;

			if(secrets.length() != 0)
			{
				var item = secrets.data;
				item.delete_sync(cancellable);
				return true;
			}
			return false;
		}
		catch(GLib.Error e)
		{
			Logger.error("FeedbinUtils.deletePassword: %s".printf(e.message));
			return false;
		}
	}
}
