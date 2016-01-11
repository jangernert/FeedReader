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

public class FeedReader.InstaAPI : GLib.Object {

    private Soup.Session m_session;
	private Soup.Message m_message_soup;
    private string m_contenttype;
    private Rest.OAuthProxy m_oauth;
    private GLib.Settings m_settings;
    private string m_id;
    private string m_accessToken;
    private string m_accessToken_secret;
    private string m_username;
    private string m_userID;
    private string m_passwd;
    private bool m_loggedIn;

    public InstaAPI(string id)
    {
    	m_id = id;
		m_session = new Soup.Session();
		m_contenttype = "application/x-www-form-urlencoded";

        m_settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/instapaper/%s/".printf(id));

        m_oauth = new Rest.OAuthProxy (
            InstapaperSecrets.oauth_consumer_key,
            InstapaperSecrets.oauth_consumer_secret,
            "https://www.instapaper.com/api/1/",
            false);
    }

    public InstaAPI.open(string id)
    {
        m_id = id;
		m_session = new Soup.Session();
		m_contenttype = "application/x-www-form-urlencoded";

        m_settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/instapaper/%s/".printf(id));
        m_username = m_settings.get_string("username");
        m_userID = m_settings.get_string("user-id");
        m_passwd = getPassword();

        m_oauth = new Rest.OAuthProxy.with_token (
            InstapaperSecrets.oauth_consumer_key,
            InstapaperSecrets.oauth_consumer_secret,
            m_settings.get_string("oauth-access-token"),
            m_settings.get_string("oauth-access-token-secret"),
            "https://www.instapaper.com/api/1/",
            false);

        if(m_settings.get_string("user-id") != "")
        {
            if(m_passwd != "")
            {
                m_loggedIn = true;
            }
        }
    }

    public bool checkLogin()
    {
        bool login = false;
        string message = "username=" + m_username + "&password=" + getPassword();

        m_message_soup = new Soup.Message("POST", "https://www.instapaper.com/api/authenticate");
        m_message_soup.set_request(m_contenttype, Soup.MemoryUse.COPY, message.data);

        if(settings_tweaks.get_boolean("do-not-track"))
				m_message_soup.request_headers.append("DNT", "1");

		m_session.send_message(m_message_soup);

        if((string)m_message_soup.response_body.flatten().data == null
		|| (string)m_message_soup.response_body.flatten().data == "")
			return false;

        string response = (string)m_message_soup.response_body.flatten().data;

        if(response == "200")
        {
            login = true;
        }

        m_loggedIn = true;
        return login;
    }

    private void writeData()
    {
    	m_settings.set_string("oauth-access-token", m_accessToken);
    	m_settings.set_string("oauth-access-token-secret", m_accessToken_secret);
        m_settings.set_string("username", m_username);
        m_settings.set_string("user-id", m_userID);
        setArray();
        var pwSchema = new Secret.Schema ("org.gnome.feedreader.instapaper.password", Secret.SchemaFlags.NONE,
                                        "userID", Secret.SchemaAttributeType.STRING);

        var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
        attributes["userID"] = m_userID;
        try{
            Secret.password_storev_sync(pwSchema, attributes, Secret.COLLECTION_DEFAULT, "Feedreader: Instapaper login", m_passwd, null);
        }
        catch(GLib.Error e){}
        pwSchema.unref();
    }

    public bool getAccessToken(string username, string password)
    {
    	m_username = username;
    	m_passwd = password;
        var call = m_oauth.new_call();
		m_oauth.url_format = "https://www.instapaper.com/api/1/";
		call.set_function ("oauth/access_token");
		call.set_method("POST");
		call.add_param("x_auth_mode", "client_auth");
		call.add_param("x_auth_username", m_username);
        call.add_param("x_auth_password", m_passwd);
        try{
            call.run();
        }
        catch(Error e)
        {
            logger.print(LogMessage.ERROR, "instapaper getAccessToken: " + e.message);
        }

        string response = call.get_payload();
        int64 status = call.get_status_code();

        if(status != 200)
        {
            m_loggedIn = false;
            return false;
        }


        int secretStart = response.index_of_char('=')+1;
        int secretEnd = response.index_of_char('&', secretStart);
        int tokenStart = response.index_of_char('=', secretEnd)+1;

        m_accessToken_secret = response.substring(secretStart, secretEnd-secretStart);
        m_accessToken = response.substring(tokenStart);

        m_oauth.set_token(m_accessToken);
        m_oauth.set_token_secret(m_accessToken_secret);

        if(m_userID == "" || m_userID == null)
        {
            getUserID();
        }

		writeData();
        m_loggedIn = true;
        return true;
    }

    public void getUserID()
    {
        var call = m_oauth.new_call();
		m_oauth.url_format = "https://www.instapaper.com/api/1/";
		call.set_function ("account/verify_credentials");
		call.set_method("POST");
        try{
            call.run();
        }
        catch(Error e)
        {
            logger.print(LogMessage.DEBUG, "getUserID: " + e.message);
        }

        var parser = new Json.Parser();
        try{
            parser.load_from_data(call.get_payload());
        }
        catch (Error e) {
            logger.print(LogMessage.ERROR, "Could not load response to Message from instapaper");
            logger.print(LogMessage.ERROR, e.message);
        }

        var root_node = parser.get_root();
        var array = root_node.get_array();
        var root_object = array.get_object_element(0);
        if(root_object.has_member("user_id"))
        {
            m_userID = root_object.get_int_member("user_id").to_string();
            m_username = root_object.get_string_member("username");
        }
        else if(root_object.has_member("error"))
        {
            logger.print(LogMessage.ERROR, root_object.get_int_member("error_code").to_string());
            logger.print(LogMessage.ERROR, root_object.get_string_member("message"));
			m_loggedIn = false;
        }
    }

    public bool addBookmark(string url)
    {
        string message  = "user_id=" + m_userID
        				+ "&username=" + m_username
                        + "&password=" + getPassword()
                        + "&url=" + GLib.Uri.escape_string(url);

        logger.print(LogMessage.DEBUG, "InstaAPI: " + message);

        m_message_soup = new Soup.Message("POST", "https://www.instapaper.com/api/add");
        m_message_soup.set_request(m_contenttype, Soup.MemoryUse.COPY, message.data);

        if(settings_tweaks.get_boolean("do-not-track"))
				m_message_soup.request_headers.append("DNT", "1");

		m_session.send_message(m_message_soup);
		string response = (string)m_message_soup.response_body.flatten().data;

        if(response == null || response == "")
			return false;

		logger.print(LogMessage.DEBUG, "InstaAPI: " + response);

        return true;
    }


    private string getPassword()
    {
        var pwSchema = new Secret.Schema ("org.gnome.feedreader.instapaper.password", Secret.SchemaFlags.NONE, "userID", Secret.SchemaAttributeType.STRING);

        var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
        attributes["userID"] = m_userID;

        string passwd = "";
        try{passwd = Secret.password_lookupv_sync(pwSchema, attributes, null);}catch(GLib.Error e){}

        return passwd;
    }

    public bool logout()
    {
        var pwSchema = new Secret.Schema ("org.gnome.feedreader.instapaper.password", Secret.SchemaFlags.NONE, "userID", Secret.SchemaAttributeType.STRING);

        var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
        attributes["userID"] = m_userID;

        Secret.password_clearv.begin (pwSchema, attributes, null, (obj, async_res) => {
            bool removed = Secret.password_clearv.end(async_res);
        });

        var keys = m_settings.list_keys();
		foreach(string key in keys)
		{
			m_settings.reset(key);
		}

		deleteArray();

        m_oauth = new Rest.OAuthProxy (
            InstapaperSecrets.oauth_consumer_key,
            InstapaperSecrets.oauth_consumer_secret,
            "https://www.instapaper.com/api/1/",
            false);

        return true;
    }

    private void setArray()
    {
		var array = settings_share.get_strv("instapaper");

		foreach(string id in array)
		{
			if(id == m_id)
				return;
		}

		array += m_id;
		settings_share.set_strv("instapaper", array);
    }


    private void deleteArray()
    {
    	var array = settings_share.get_strv("instapaper");
    	string[] array2 = {};

    	foreach(string id in array)
		{
			if(id != m_id)
				array2 += id;
		}

		settings_share.set_strv("instapaper", array2);
    }


    public string getID()
    {
    	return m_id;
    }


    public string getUsername()
    {
    	return m_username;
    }

}
