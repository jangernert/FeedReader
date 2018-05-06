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

public class FeedReader.ttrssUtils : GLib.Object {

	public enum TTRSSSpecialID {
		ARCHIVED      = 0,
		STARRED       = -1,
		PUBLISHED     = -2,
		FRESH         = -3,
		ALL           = -4,
		RECENTLY_READ = -6
	}

	private GLib.Settings m_settings;
	private Password m_password;
	private Password m_htaccess_password;

	public ttrssUtils(GLib.SettingsBackend? settings_backend, Secret.Collection secrets)
	{
		if(settings_backend != null)
			m_settings = new GLib.Settings.with_backend("org.gnome.feedreader.ttrss", settings_backend);
		else
			m_settings = new GLib.Settings("org.gnome.feedreader.ttrss");

		var pwSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
										  "URL", Secret.SchemaAttributeType.STRING,
										  "Username", Secret.SchemaAttributeType.STRING);
		m_password = new Password(secrets, pwSchema, "FeedReader: ttrss login", () => {
			var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
			attributes["URL"] = getURL();
			attributes["Username"] = getUser();
			return attributes;
		});

		var htAccessSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
										        "URL", Secret.SchemaAttributeType.STRING,
										        "Username", Secret.SchemaAttributeType.STRING,
										        "htaccess", Secret.SchemaAttributeType.BOOLEAN);
		m_htaccess_password = new Password(secrets, htAccessSchema, "FeedReader: ttrss htaccess Authentication", () => {
			var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
			attributes["URL"] = getURL();
			attributes["Username"] = getHtaccessUser();
			attributes["htaccess"] = "true";
			return attributes;
		});
	}

	public string getURL()
	{

		string tmp_url = Utils.gsettingReadString(m_settings, "url");

		if(tmp_url != ""){
			if(!tmp_url.has_suffix("/"))
				tmp_url = tmp_url + "/";

			if(!tmp_url.has_suffix("/api/"))
				tmp_url = tmp_url + "api/";

			if(!tmp_url.has_prefix("http://") && !tmp_url.has_prefix("https://"))
					tmp_url = "https://" + tmp_url;
		}

		Logger.debug("ttrss URL: " + tmp_url);

		return tmp_url;
	}

	public void setURL(string url)
	{
		Utils.gsettingWriteString(m_settings, "url", url);
	}

	public string getUser()
	{
		return Utils.gsettingReadString(m_settings, "username");
	}

	public void setUser(string user)
	{
		Utils.gsettingWriteString(m_settings, "username", user);
	}

	public string getHtaccessUser()
	{
		return Utils.gsettingReadString(m_settings, "htaccess-username");
	}

	public void setHtaccessUser(string ht_user)
	{
		Utils.gsettingWriteString(m_settings, "htaccess-username", ht_user);
	}

	public string getUnmodifiedURL()
	{
		return Utils.gsettingReadString(m_settings, "url");
	}

	public string getPasswd()
	{
		return m_password.get_password();
	}

	public void setPassword(string passwd)
	{
		m_password.set_password(passwd);
	}

	public void resetAccount()
	{
		Utils.resetSettings(m_settings);
		m_password.delete_password();
		m_htaccess_password.delete_password();
	}

	public string getHtaccessPasswd()
	{
		return m_htaccess_password.get_password();
	}

	public void setHtAccessPassword(string passwd)
	{
		m_htaccess_password.set_password(passwd);
	}
}
