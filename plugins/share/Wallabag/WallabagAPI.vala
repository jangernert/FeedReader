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

namespace FeedReader{
	Logger logger;

	/*namespace WallabagSecrets {
		const string base_uri				= "https://v2.wallabag.org/";
		const string oauth_callback			= "feedreader://wallabag";
		const string clientID				= "26_22ptghqq832880sww04s4kwww0wc4ok8cg0w88wokgw4sgscc8";
		const string clientSecret			= "2qzxbatep7s48gsgww0k0gs8c4wscg4c4sgcgcso4o80g44sw0";
	}*/
}

public class FeedReader.WallabagAPI : ShareAccountInterface, Peas.ExtensionBase {

    public Logger m_logger { get; construct set; }

    public WallabagAPI()
    {
		logger = m_logger;

		this.addAccount.connect((id, type, username, iconName, accountName) => {
			logger.print(LogMessage.INFO, "WallabagAPI: addAccount()");
		});
    }

    public bool getAccessToken(string id, string username, string password, string clientID, string clientSecret, string baseURL)
    {
		logger.print(LogMessage.DEBUG, "WallabagAPI getAccessToken");
        var session = new Soup.Session();
        string message = "grant_type=password"
		 				+ "&client_id=" + clientID
						+ "&client_secret=" + clientSecret
						+ "&username=" + username
						+ "&password=" + password;


		string url = baseURL + "oauth/v2/token";
        var message_soup = new Soup.Message("POST", url);
        message_soup.set_request("application/x-www-form-urlencoded; charset=UTF8", Soup.MemoryUse.COPY, message.data);
		session.send_message(message_soup);

        if((string)message_soup.response_body.flatten().data == null
		|| (string)message_soup.response_body.flatten().data == "")
		{
			logger.print(LogMessage.ERROR, "WallabagAPI - getAccessToken: no response");
			logger.print(LogMessage.ERROR, url);
			logger.print(LogMessage.ERROR, message);
			return false;
		}

        string response = (string)message_soup.response_body.flatten().data;
        logger.print(LogMessage.DEBUG, response);

		var parser = new Json.Parser();
        try
        {
            parser.load_from_data(response);
        }
        catch (Error e)
        {
            logger.print(LogMessage.ERROR, "Could not load response to Message from instapaper");
            logger.print(LogMessage.ERROR, e.message);
        }

        var root_node = parser.get_root();
        var root_object = root_node.get_object();
		string accessToken = root_object.get_string_member("access_token");
		int64 now = (new DateTime.now_local()).to_unix();
		int64 expires = root_object.get_int_member("expires_in");
		string refreshToken = root_object.get_string_member("refresh_token");

        var settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/wallabag/%s/".printf(id));
        settings.set_string("oauth-access-token", accessToken);
        settings.set_string("username", username);
		settings.set_int("access-token-expires", (int)(now + expires));
		settings.set_string("url", baseURL);
        settings.set_string("client-id", clientID);
		settings.set_string("client-secret", clientSecret);


		var share_settings = new GLib.Settings("org.gnome.feedreader.share");
        var array = share_settings.get_strv("wallabag");
		foreach(string i in array)
		{
			if(i == id)
			{
				logger.print(LogMessage.WARNING, "WallabagAPI - getAccessToken: id already part of array. Returning");
				return true;
			}
		}
        array += id;
		share_settings.set_strv("wallabag", array);


		var pwSchema = new Secret.Schema ("org.gnome.feedreader.wallabag.password", Secret.SchemaFlags.NONE,
                                        "username", Secret.SchemaAttributeType.STRING,
										"id", Secret.SchemaAttributeType.STRING);

        var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
        attributes["username"] = username;
		attributes["id"] = id;
        try
        {
            Secret.password_storev_sync(pwSchema, attributes, Secret.COLLECTION_DEFAULT, "Feedreader: Wallabag login", password, null);
        }
        catch(GLib.Error e)
        {
            m_logger.print(LogMessage.ERROR, "WallabagAPI - getAccessToken: " + e.message);
        }

        return true;
    }


    public bool addBookmark(string id, string url)
    {
		var settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/wallabag/%s/".printf(id));

		logger.print(LogMessage.DEBUG, "WallabagAPI - addBookmark: " + url);
		if(!accessTokenValid(id))
		{
			string username = getUsername(id);
			string password = getPasswd(id);
			string clientID = settings.get_string("client-id");
			string clientSecret = settings.get_string("client-secret");
			string baseURL = settings.get_string("url");

			getAccessToken(id, username, password, clientID, clientSecret, baseURL);
		}

		logger.print(LogMessage.DEBUG, "WallabagAPI - addBookmark: token still valid");

        var session = new Soup.Session();
        string message = "url=" + GLib.Uri.escape_string(url);
		string baseURL = settings.get_string("url");

        var message_soup = new Soup.Message("POST", baseURL + "api/entries.json");
        message_soup.set_request("application/x-www-form-urlencoded; charset=UTF8", Soup.MemoryUse.COPY, message.data);
		message_soup.request_headers.append("Authorization", "Bearer " + settings.get_string("oauth-access-token"));
		session.send_message(message_soup);

        if((string)message_soup.response_body.flatten().data == null
		|| (string)message_soup.response_body.flatten().data == "")
		{
			logger.print(LogMessage.ERROR, "WallabagAPI - addBookmark: no response");
			logger.print(LogMessage.ERROR, url);
			logger.print(LogMessage.ERROR, message);
			return false;
		}

        return true;
    }

    public bool logout(string id)
    {
		logger.print(LogMessage.DEBUG, "WallabagAPI - logout");
        var settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/wallabag/%s/".printf(id));
    	var keys = settings.list_keys();
		foreach(string key in keys)
		{
			settings.reset(key);
		}

		var share_settings = new GLib.Settings("org.gnome.feedreader.share");
        var array = share_settings.get_strv("wallabag");
    	string[] array2 = {};

    	foreach(string i in array)
		{
			if(i != id)
				array2 += i;
		}
		share_settings.set_strv("wallabag", array2);
		deletePassword(id);
		deleteAccount(id);

        return true;
    }

	private bool accessTokenValid(string id)
	{
		var settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/wallabag/%s/".printf(id));
		var now = new DateTime.now_local();
		int expires = settings.get_int("access-token-expires");

		if((int)now.to_unix() >  expires)
		{
			logger.print(LogMessage.WARNING, "WallabagAPI: access token expired");
			return false;
		}

		return true;
	}

    public string getIconName()
    {
        return "feed-share-wallabag";
    }

    public string getUsername(string id)
    {
        var settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/wallabag/%s/".printf(id));
        return settings.get_string("username");
    }

	public string getPasswd(string id)
	{
		var pwSchema = new Secret.Schema ("org.gnome.feedreader.wallabag.password", Secret.SchemaFlags.NONE,
                                        "username", Secret.SchemaAttributeType.STRING,
										"id", Secret.SchemaAttributeType.STRING);

        var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
        attributes["username"] = getUsername(id);
		attributes["id"] = id;

		string passwd = "";

		try{
			passwd = Secret.password_lookupv_sync(pwSchema, attributes, null);
		}
		catch(GLib.Error e){
			logger.print(LogMessage.ERROR, e.message);
		}

		if(passwd == null)
		{
			return "";
		}

		return passwd;
	}

	private bool deletePassword(string id)
	{
		bool removed = false;
		var pwSchema = new Secret.Schema ("org.gnome.feedreader.wallabag.password", Secret.SchemaFlags.NONE,
                                        "username", Secret.SchemaAttributeType.STRING,
										"id", Secret.SchemaAttributeType.STRING);

        var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
        attributes["username"] = getUsername(id);
		attributes["id"] = id;

		Secret.password_clearv.begin (pwSchema, attributes, null, (obj, async_res) => {
			removed = Secret.password_clearv.end(async_res);
		});
		return removed;
	}

    public bool needSetup()
	{
		return true;
	}

    public string pluginID()
    {
        return "wallabag";
    }

    public string pluginName()
    {
        return "Wallabag";
    }

    public ServiceSetup? newSetup_withID(string id, string username)
    {
        return new WallabagSetup(id, this, username);
    }

    public ServiceSetup? newSetup()
    {
        return new WallabagSetup(null, this);
    }
}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.ShareAccountInterface), typeof(FeedReader.WallabagAPI));
}
