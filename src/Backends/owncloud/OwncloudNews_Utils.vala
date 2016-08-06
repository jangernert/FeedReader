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

public class FeedReader.OwncloudNews_Utils : GLib.Object {

    public static string getURL()
	{
        //https://yourowncloud.com/index.php/apps/news/api/v1-2/

		string tmp_url = settings_owncloud.get_string("url");
		if(tmp_url != ""){
			if(!tmp_url.has_suffix("/"))
				tmp_url = tmp_url + "/";

			if(!tmp_url.has_suffix("/index.php/apps/news/api/v1-2/"))
				tmp_url = tmp_url + "index.php/apps/news/api/v1-2/";

			if(!tmp_url.has_prefix("http://") && !tmp_url.has_prefix("https://"))
					tmp_url = "https://" + tmp_url;
		}

		logger.print(LogMessage.DEBUG, "OwnCloud URL: " + tmp_url);

		return tmp_url;
	}

    public static string getUser()
	{
		return settings_owncloud.get_string ("username");
	}

    public static string getHtaccessUser()
	{
		return settings_owncloud.get_string ("htaccess-username");
	}

    public static string getUnmodifiedURL()
    {
        return settings_owncloud.get_string("url");
    }

	public static string getPasswd()
	{
		var pwSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
		                                  "URL", Secret.SchemaAttributeType.STRING,
		                                  "Username", Secret.SchemaAttributeType.STRING);

		var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
		attributes["URL"] = settings_owncloud.get_string("url");
		attributes["Username"] = getUser();

		string passwd = "";
		try{
            passwd = Secret.password_lookupv_sync(pwSchema, attributes, null);
        }
        catch(GLib.Error e){
			logger.print(LogMessage.ERROR, e.message);
		}

        pwSchema.unref();

		if(passwd == null)
		{
			return "";
		}

		return passwd;
	}

    public static bool deletePassword()
	{
		bool removed = false;
		var pwSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
										"URL", Secret.SchemaAttributeType.STRING,
										"Username", Secret.SchemaAttributeType.STRING);
		var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
        attributes["URL"] = settings_owncloud.get_string("url");
		attributes["Username"] = getUser();

		Secret.password_clearv.begin (pwSchema, attributes, null, (obj, async_res) => {
			removed = Secret.password_clearv.end(async_res);
			pwSchema.unref();
		});
		return removed;
	}

    public static string getHtaccessPasswd()
	{
		var pwSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
		                                  "URL", Secret.SchemaAttributeType.STRING,
		                                  "Username", Secret.SchemaAttributeType.STRING,
                                          "htaccess", Secret.SchemaAttributeType.BOOLEAN);

		var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
		attributes["URL"] = settings_owncloud.get_string("url");
		attributes["Username"] = getHtaccessUser();
        attributes["Username"] = "true";

		string passwd = "";
		try{
            passwd = Secret.password_lookupv_sync(pwSchema, attributes, null);
        }
        catch(GLib.Error e){
			logger.print(LogMessage.ERROR, e.message);
		}

        pwSchema.unref();

		if(passwd == null)
		{
			return "";
		}

		return passwd;
	}


    public static bool downloadIcon(string feed_id, string icon_url)
	{
        if(icon_url == "")
            return false;

		string icon_path = GLib.Environment.get_home_dir() + "/.local/share/feedreader/data/feed_icons/";
		var path = GLib.File.new_for_path(icon_path);
		try{
			path.make_directory_with_parents();
		}
		catch(GLib.Error e){
			//logger.print(LogMessage.DEBUG, e.message);
		}

		string local_filename = icon_path + feed_id + ".ico";



		if(!FileUtils.test(local_filename, GLib.FileTest.EXISTS))
		{
			Soup.Message message_dlIcon;
			message_dlIcon = new Soup.Message("GET", icon_url);

			if(settings_tweaks.get_boolean("do-not-track"))
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
					logger.print(LogMessage.ERROR, "Error writing icon: %s".printf(e.message));
				}
				return true;
			}
			logger.print(LogMessage.ERROR, "Error downloading icon for feed %s, url: %s, status: %u".printf(feed_id, icon_url, status));
			return false;
		}

		// file already exists
		return true;
	}


    public static int countUnread(Gee.LinkedList<feed> feeds, string id)
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
