public class FeedReader.InstaAPI : GLib.Object {

    private Soup.Session m_session;
	private Soup.Message m_message_soup;
    private string m_contenttype;
    private Rest.OAuthProxy m_oauth;

    public InstaAPI()
    {
		m_session = new Soup.Session();
		m_contenttype = "application/x-www-form-urlencoded";

        if(settings_instapaper.get_string("oauth-token") == "")
        {
            m_oauth = new Rest.OAuthProxy (
                InstapaperSecrets.oauth_consumer_key,
                InstapaperSecrets.oauth_consumer_secret,
                "https://www.instapaper.com/api/1/",
                false);
        }
        else
        {
            m_oauth = new Rest.OAuthProxy.with_token (
    			InstapaperSecrets.oauth_consumer_key,
    			InstapaperSecrets.oauth_consumer_secret,
                settings_instapaper.get_string("oauth-token"),
                settings_instapaper.get_string("oauth-token-secret"),
    			"https://www.instapaper.com/api/1/",
    			false);

            if(settings_instapaper.get_string("username") != "")
            {
                if(getPassword() != "")
                {
                    settings_instapaper.set_boolean("is-logged-in", true);
                }
            }
        }

    }

    public bool login(string username, string password)
    {
        string message = "username=" + username + "&password=" + password;

        m_message_soup = new Soup.Message("POST", "https://www.instapaper.com/api/authenticate");
        m_message_soup.set_request(m_contenttype, Soup.MemoryUse.COPY, message.data);
		m_session.send_message(m_message_soup);

        if((string)m_message_soup.response_body.flatten().data == null
		|| (string)m_message_soup.response_body.flatten().data == "")
			return false;

        string response = (string)m_message_soup.response_body.flatten().data;

        if(response == "200")
        {
            settings_instapaper.set_string("username", username);
            var pwSchema = new Secret.Schema ("org.gnome.feedreader.instapaper.password", Secret.SchemaFlags.NONE,
                                            "Username", Secret.SchemaAttributeType.STRING);

            var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
            attributes["Username"] = username;
            try{
                Secret.password_storev_sync(pwSchema, attributes, Secret.COLLECTION_DEFAULT, "Feedreader: Instapaper login", password, null);
            }
            catch(GLib.Error e){}

            settings_instapaper.set_boolean("is-logged-in", true);
            settings_instapaper.set_string("username", username);
            getAccessToken();
            return true;
        }

        return false;
    }

    private void getAccessToken()
    {
        var call = m_oauth.new_call();
		m_oauth.url_format = "https://www.instapaper.com/api/1/";
		call.set_function ("oauth/access_token");
		call.set_method("POST");
		call.add_param("x_auth_mode", "client_auth");
		call.add_param("x_auth_username", settings_instapaper.get_string("username"));
        call.add_param("x_auth_password", getPassword());
        try{
            call.run();
        }
        catch(Error e)
        {
            logger.print(LogMessage.DEBUG, "getAccessToken: " + e.message);
        }

        string response = call.get_payload();

        int secretStart = response.index_of_char('=')+1;
        int secretEnd = response.index_of_char('&', secretStart);
        int tokenStart = response.index_of_char('=', secretEnd)+1;

        string secret = response.substring(secretStart, secretEnd-secretStart);
        string token = response.substring(tokenStart);

        m_oauth.set_token(token);
        m_oauth.set_token_secret(secret);

        settings_instapaper.set_string("oauth-token-secret", secret);
        settings_instapaper.set_string("oauth-token", token);

        if(settings_instapaper.get_string("user-id") == "")
        {
            getUserID();
        }
    }

    private void getUserID()
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
            var userID = root_object.get_int_member("user_id");
            var username = root_object.get_string_member("username");
            settings_instapaper.set_string("user-id", userID.to_string());
            settings_instapaper.set_string("username", username);
        }
    }

    public bool addBookmark(string url)
    {
        string message  = "username=" + settings_instapaper.get_string("username")
                        + "&password=" + getPassword()
                        + "&url=" + GLib.Uri.escape_string(url);

        logger.print(LogMessage.DEBUG, message);

        m_message_soup = new Soup.Message("POST", "https://www.instapaper.com/api/add");
        m_message_soup.set_request(m_contenttype, Soup.MemoryUse.COPY, message.data);
		m_session.send_message(m_message_soup);

        if((string)m_message_soup.response_body.flatten().data == null
		|| (string)m_message_soup.response_body.flatten().data == "")
			return false;

        return true;
    }


    private string getPassword()
    {
        string username = settings_instapaper.get_string("username");
        var pwSchema = new Secret.Schema ("org.gnome.feedreader.instapaper.password", Secret.SchemaFlags.NONE, "Username", Secret.SchemaAttributeType.STRING);

        var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
        attributes["Username"] = username;

        string passwd = "";
        try{passwd = Secret.password_lookupv_sync(pwSchema, attributes, null);}catch(GLib.Error e){}

        return passwd;
    }

    public bool logout()
    {
        var pwSchema = new Secret.Schema ("org.gnome.feedreader.instapaper.password", Secret.SchemaFlags.NONE, "Username", Secret.SchemaAttributeType.STRING);

        var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
        attributes["Username"] = settings_instapaper.get_string("username");

        Secret.password_clearv.begin (pwSchema, attributes, null, (obj, async_res) => {
            bool removed = Secret.password_clearv.end(async_res);
        });

        settings_instapaper.set_string("oauth-token", "");
        settings_instapaper.set_string("oauth-token-secret", "");
        settings_instapaper.set_string("user-id", "");
        settings_instapaper.set_string("username", "");
        settings_instapaper.set_boolean("is-logged-in", false);

        m_oauth = new Rest.OAuthProxy (
            InstapaperSecrets.oauth_consumer_key,
            InstapaperSecrets.oauth_consumer_secret,
            "https://www.instapaper.com/api/1/",
            false);

        return true;
    }

}
