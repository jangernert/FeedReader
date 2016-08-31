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

namespace FeedReader.InstapaperSecrets {
	const string base_uri			= "https://www.instapaper.com/api/";
	const string oauth_consumer_key		= "b7681e07bf554b15813511217054e1b2";
	const string oauth_consumer_secret	= "c5307cb359d54685904f6d38aaeede6f";
	const string oauth_callback			= "feedreader://instapaper";
}

public class FeedReader.InstaAPI : ShareAccountInterface, Peas.ExtensionBase {

    private GLib.Settings m_shareSettings;
    private GLib.Settings m_shareTweaks;
    public Logger m_logger { get; construct set; }

    public InstaAPI()
    {
        m_shareSettings = new GLib.Settings("org.gnome.feedreader.share");
        m_shareTweaks = new GLib.Settings("org.gnome.feedreader.tweaks");
    }

    public string getRequestToken()
    {
        return "";
    }

    public bool getAccessToken(string id, string username, string password)
    {
        string userID = "";

        var oauthObject = new Rest.OAuthProxy (
            InstapaperSecrets.oauth_consumer_key,
            InstapaperSecrets.oauth_consumer_secret,
            "https://www.instapaper.com/api/1/",
            false);

        var call = oauthObject.new_call();
		oauthObject.url_format = "https://www.instapaper.com/api/1/";
		call.set_function ("oauth/access_token");
		call.set_method("POST");
		call.add_param("x_auth_mode", "client_auth");
		call.add_param("x_auth_username", username);
        call.add_param("x_auth_password", password);
        try
        {
            call.run();
        }
        catch(Error e)
        {
            m_logger.print(LogMessage.ERROR, "instapaper getAccessToken: " + e.message);
        }

        string response = call.get_payload();
        int64 status = call.get_status_code();

        if(status != 200)
        {
            return false;
        }


        int secretStart = response.index_of_char('=')+1;
        int secretEnd = response.index_of_char('&', secretStart);
        int tokenStart = response.index_of_char('=', secretEnd)+1;

        string accessToken_secret = response.substring(secretStart, secretEnd-secretStart);
        string accessToken = response.substring(tokenStart);

        oauthObject.set_token(accessToken);
        oauthObject.set_token_secret(accessToken_secret);

        // get userID -------------------------------------------------------------------------------------------------
        var call2 = oauthObject.new_call();
		oauthObject.url_format = "https://www.instapaper.com/api/1/";
		call2.set_function("account/verify_credentials");
		call2.set_method("POST");
        try
        {
            call2.run();
        }
        catch(Error e)
        {
            m_logger.print(LogMessage.DEBUG, "getUserID: " + e.message);
        }

        var parser = new Json.Parser();
        try
        {
            parser.load_from_data(call2.get_payload());
        }
        catch (Error e)
        {
            m_logger.print(LogMessage.ERROR, "Could not load response to Message from instapaper");
            m_logger.print(LogMessage.ERROR, e.message);
        }

        var root_node = parser.get_root();
        var userArray = root_node.get_array();
        var root_object = userArray.get_object_element(0);
        if(root_object.has_member("user_id"))
        {
            userID = root_object.get_int_member("user_id").to_string();
        }
        else if(root_object.has_member("error"))
        {
            m_logger.print(LogMessage.ERROR, root_object.get_int_member("error_code").to_string());
            m_logger.print(LogMessage.ERROR, root_object.get_string_member("message"));
        }
        //-------------------------------------------------------------------------------------------------------------


        var settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/instapaper/%s/".printf(id));
        settings.set_string("oauth-access-token", accessToken);
    	settings.set_string("oauth-access-token-secret", accessToken_secret);
        settings.set_string("username", username);
        settings.set_string("user-id", userID);

        var array = m_shareSettings.get_strv("instapaper");
        array += id;
		m_shareSettings.set_strv("instapaper", array);

        var pwSchema = new Secret.Schema ("org.gnome.feedreader.instapaper.password", Secret.SchemaFlags.NONE,
                                        "userID", Secret.SchemaAttributeType.STRING);

        var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
        attributes["userID"] = userID;
        try
        {
            Secret.password_storev_sync(pwSchema, attributes, Secret.COLLECTION_DEFAULT, "Feedreader: Instapaper login", password, null);
        }
        catch(GLib.Error e)
        {
            m_logger.print(LogMessage.ERROR, "InstaAPI - getAccessToken: " + e.message);
        }

        return true;
    }

    public bool addBookmark(string id, string url)
    {
        var settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/instapaper/%s/".printf(id));

        var pwSchema = new Secret.Schema ("org.gnome.feedreader.instapaper.password", Secret.SchemaFlags.NONE, "userID", Secret.SchemaAttributeType.STRING);
        var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
        attributes["userID"] = settings.get_string("user-id");

        string password = "";
        try
        {
            password = Secret.password_lookupv_sync(pwSchema, attributes, null);
        }
        catch(GLib.Error e)
        {
            m_logger.print(LogMessage.ERROR, "InstaAPI addBookmark: " + e.message);
        }

        var session = new Soup.Session();
        string message  = "user_id=" + settings.get_string("user-id")
        				+ "&username=" + settings.get_string("username")
                        + "&password=" + password
                        + "&url=" + GLib.Uri.escape_string(url);

        m_logger.print(LogMessage.DEBUG, "InstaAPI: " + message);

        var message_soup = new Soup.Message("POST", "https://www.instapaper.com/api/add");
        message_soup.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, message.data);

        if(m_shareTweaks.get_boolean("do-not-track"))
				message_soup.request_headers.append("DNT", "1");

		session.send_message(message_soup);
		string response = (string)message_soup.response_body.flatten().data;

        if(response == null || response == "")
			return false;

		m_logger.print(LogMessage.DEBUG, "InstaAPI: " + response);

        return true;
    }

    public bool logout(string id)
    {
        var settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/instapaper/%s/".printf(id));
        var pwSchema = new Secret.Schema ("org.gnome.feedreader.instapaper.password",
                                        Secret.SchemaFlags.NONE, "userID", Secret.SchemaAttributeType.STRING);

        var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
        attributes["userID"] = settings.get_string("user-id");

        Secret.password_clearv.begin (pwSchema, attributes, null, (obj, async_res) => {
            bool removed = Secret.password_clearv.end(async_res);
        });

        var keys = settings.list_keys();
		foreach(string key in keys)
		{
			settings.reset(key);
		}

        var array = m_shareSettings.get_strv("instapaper");

    	string[] array2 = {};
    	foreach(string i in array)
		{
			if(i != id)
				array2 += i;
		}
		m_shareSettings.set_strv("instapaper", array2);
		deleteAccount(id);

        return true;
    }

    public string getIconName()
    {
        return "feed-share-instapaper";
    }

    public string getUsername(string id)
    {
        var settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/instapaper/%s/".printf(id));
        return settings.get_string("username");
    }

    public bool needSetup()
	{
		return true;
	}

    public string pluginID()
    {
        return "instapaper";
    }

    public string pluginName()
    {
        return "Instapaper";
    }

    public string getURL(string token)
    {
        return "";
    }

    public ServiceSetup? newSetup_withID(string id, string username)
    {
        return new InstapaperSetup(id, this, username);
    }

    public ServiceSetup? newSetup()
    {
        return new InstapaperSetup(null, this);
    }

	public ShareForm? shareWidget()
	{
		return null;
	}
}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.ShareAccountInterface), typeof(FeedReader.InstaAPI));
}
