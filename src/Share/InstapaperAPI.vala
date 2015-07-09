public class FeedReader.InstaAPI : GLib.Object {

    private Soup.Session m_session;
	private Soup.Message m_message_soup;
    private string m_contenttype;
    private Rest.OAuthProxy m_oauth;

    public InstaAPI()
    {
		m_session = new Soup.Session();
		m_contenttype = "application/x-www-form-urlencoded";

        if(settings_instapaper.get_string("username") != "")
        {
            if(getPassword() != "")
            {
                settings_instapaper.set_boolean("is-logged-in", true);
            }
        }

        m_oauth = new Rest.OAuthProxy (
            InstapaperSecrets.oauth_consumer_key,
            InstapaperSecrets.oauth_consumer_secret,
            "https://www.instapaper.com/api/1/",
            false);
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
            settings_instapaper.set_boolean("is-logged-in", true);
            return true;
        }

        return false;
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
        var pwSchema = new Secret.Schema ("org.gnome.feedreader.instapaper.password", Secret.SchemaFlags.NONE,
                                          "Username", Secret.SchemaAttributeType.STRING);

        var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
        attributes["Username"] = username;

        string passwd = "";
        try{passwd = Secret.password_lookupv_sync(pwSchema, attributes, null);}catch(GLib.Error e){}

        return passwd;
    }

}
