public class FeedReader.InstaAPI : GLib.Object {

    private Soup.Session m_session;
	private Soup.Message m_message_soup;
    private string m_contenttype;

    public InstaAPI()
    {
		m_session = new Soup.Session();
		m_contenttype = "application/x-www-form-urlencoded";
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
        string username = settings_instapaper.get_string("username");

        var pwSchema = new Secret.Schema ("org.gnome.feedreader.instapaper.password", Secret.SchemaFlags.NONE,
                                          "Username", Secret.SchemaAttributeType.STRING);

        var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
        attributes["Username"] = username;

        string passwd = "";
        try{passwd = Secret.password_lookupv_sync(pwSchema, attributes, null);}catch(GLib.Error e){}

        string message = "username=" + username + "&password=" + passwd + "&url=" + GLib.Uri.escape_string(url);
        logger.print(LogMessage.DEBUG, message);

        m_message_soup = new Soup.Message("POST", "https://www.instapaper.com/api/add");
        m_message_soup.set_request(m_contenttype, Soup.MemoryUse.COPY, message.data);
		m_session.send_message(m_message_soup);

        if((string)m_message_soup.response_body.flatten().data == null
		|| (string)m_message_soup.response_body.flatten().data == "")
			return false;

        return true;
    }

}
