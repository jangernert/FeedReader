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

public class FeedReader.OwncloudNewsUtils : GLib.Object {

    GLib.Settings m_settings;

    public OwncloudNewsUtils()
    {
        m_settings = new GLib.Settings ("org.gnome.feedreader.owncloud");
    }

    public string getURL()
	{
		string tmp_url = m_settings.get_string("url");
		if(tmp_url != ""){
			if(!tmp_url.has_suffix("/"))
				tmp_url = tmp_url + "/";

			if(!tmp_url.has_suffix("/index.php/apps/news/api/v1-2/"))
				tmp_url = tmp_url + "index.php/apps/news/api/v1-2/";

			if(!tmp_url.has_prefix("http://") && !tmp_url.has_prefix("https://"))
					tmp_url = "https://" + tmp_url;
		}

		Logger.debug("OwnCloud URL: " + tmp_url);

		return tmp_url;
	}

    public void setURL(string url)
    {
        m_settings.set_string ("url", url);
    }

    public string getUser()
	{
		return m_settings.get_string ("username");
	}

    public void setUser(string user)
	{
		m_settings.set_string ("username", user);
	}

    public string getHtaccessUser()
	{
		return m_settings.get_string ("htaccess-username");
	}

    public void setHtaccessUser(string ht_user)
	{
		m_settings.set_string ("htaccess-username", ht_user);
	}

    public string getUnmodifiedURL()
    {
        return m_settings.get_string("url");
    }

	public string getPasswd()
	{
		var pwSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
		                                  "URL", Secret.SchemaAttributeType.STRING,
		                                  "Username", Secret.SchemaAttributeType.STRING);

		var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
		attributes["URL"] = getURL();
		attributes["Username"] = getUser();

		string passwd = "";
		try{
            passwd = Secret.password_lookupv_sync(pwSchema, attributes, null);
        }
        catch(GLib.Error e){
			Logger.error("OwncloudNewsUtils: getPasswd: " + e.message);
		}

		if(passwd == null)
		{
			return "";
		}

		return passwd;
	}

    public void setPassword(string passwd)
    {
        var pwSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
                                          "URL", Secret.SchemaAttributeType.STRING,
                                          "Username", Secret.SchemaAttributeType.STRING);
        var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
        attributes["URL"] = getURL();
        attributes["Username"] = getUser();
        try
        {
            Secret.password_storev_sync(pwSchema, attributes, Secret.COLLECTION_DEFAULT, "FeedReader: ownCloud login", passwd, null);
        }
        catch(GLib.Error e)
        {
            Logger.error("OwncloudNewsUtils: setPassword: " + e.message);
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
		var pwSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
										"URL", Secret.SchemaAttributeType.STRING,
										"Username", Secret.SchemaAttributeType.STRING);
		var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
        attributes["URL"] = getURL();
		attributes["Username"] = getUser();

		Secret.password_clearv.begin (pwSchema, attributes, null, (obj, async_res) => {
            try
            {
                removed = Secret.password_clearv.end(async_res);
            }
            catch(GLib.Error e)
            {
                Logger.error("OwncloudNewsUtils.deletePassword: %s".printf(e.message));
            }
		});
		return removed;
	}

    public string getHtaccessPasswd()
	{
		var pwSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
		                                  "URL", Secret.SchemaAttributeType.STRING,
		                                  "Username", Secret.SchemaAttributeType.STRING,
                                          "htaccess", Secret.SchemaAttributeType.BOOLEAN);

		var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
		attributes["URL"] = getURL();
		attributes["Username"] = getHtaccessUser();
        attributes["Username"] = "true";

		string passwd = "";
		try{
            passwd = Secret.password_lookupv_sync(pwSchema, attributes, null);
        }
        catch(GLib.Error e){
			Logger.error("OwncloudNewsUtils: getHtaccessPasswd: " + e.message);
		}

		if(passwd == null)
		{
			return "";
		}

		return passwd;
	}

    public void setHtAccessPassword(string passwd)
    {
        var pwAuthSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
                                              "URL", Secret.SchemaAttributeType.STRING,
                                              "Username", Secret.SchemaAttributeType.STRING,
                                              "htaccess", Secret.SchemaAttributeType.BOOLEAN);
        var authAttributes = new GLib.HashTable<string,string>(str_hash, str_equal);
        authAttributes["URL"] = getURL();
        authAttributes["Username"] = getHtaccessUser();
        authAttributes["htaccess"] = "true";
        try
        {
            Secret.password_storev_sync(pwAuthSchema,
                                        authAttributes,
                                        Secret.COLLECTION_DEFAULT,
                                        "FeedReader: ownCloud htaccess Authentication",
                                        passwd,
                                        null);
        }
        catch(GLib.Error e)
        {
            Logger.error("OwncloudNewsUtils: setHtaccessPasswd: " + e.message);
        }
    }


    public bool downloadIcon(string feed_id, string? icon_url)
	{
        if(icon_url == "" || icon_url == null)
            return false;

		string icon_path = GLib.Environment.get_home_dir() + "/.local/share/feedreader/data/feed_icons/";
		var path = GLib.File.new_for_path(icon_path);
		try{
			path.make_directory_with_parents();
		}
		catch(GLib.Error e){
			//Logger.debug(e.message);
		}

		string local_filename = icon_path + feed_id + ".ico";



		if(!FileUtils.test(local_filename, GLib.FileTest.EXISTS))
		{
            var settingsTweaks = new GLib.Settings("org.gnome.feedreader.tweaks");
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
			Logger.error("Error downloading icon for feed %s, url: %s, status: %u".printf(feed_id, icon_url, status));
			return false;
		}

		// file already exists
		return true;
	}


    public int countUnread(Gee.LinkedList<feed> feeds, string id)
    {
        int unread = 0;

        foreach(feed Feed in feeds)
        {
            var ids = Feed.getCatIDs();
            foreach(string ID in ids)
            {
                if(ID == id)
                {
                    unread += (int)Feed.getUnread();
                    break;
                }
            }
        }

        return unread;
    }
}
