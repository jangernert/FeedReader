public class FeedReader.PocketAPI : GLib.Object {

    private Soup.Session m_session;
	private Soup.Message m_message_soup;
    private string m_contenttype;

    public PocketAPI()
    {
		m_session = new Soup.Session();
		m_contenttype = "application/x-www-form-urlencoded; charset=UTF8";
    }

    public bool getRequestToken()
    {
        string message = "consumer_key=" + PocketSecrets.oauth_consumer_key + "&redirect_uri=" + PocketSecrets.oauth_callback;

        m_message_soup = new Soup.Message("POST", "https://getpocket.com/v3/oauth/request");
        m_message_soup.set_request(m_contenttype, Soup.MemoryUse.COPY, message.data);
		m_session.send_message(m_message_soup);

        if((string)m_message_soup.response_body.flatten().data == null
		|| (string)m_message_soup.response_body.flatten().data == "")
			return false;

        string response = (string)m_message_soup.response_body.flatten().data;
        response = response.substring(response.index_of_char('=')+1);
        settings_pocket.set_string("oauth-request-token", response);
        return true;
    }


    public bool getAccessToken()
    {
        string message = "consumer_key=" + PocketSecrets.oauth_consumer_key + "&code=" + settings_pocket.get_string("oauth-request-token");

        m_message_soup = new Soup.Message("POST", "https://getpocket.com/v3/oauth/authorize");
        m_message_soup.set_request(m_contenttype, Soup.MemoryUse.COPY, message.data);
		m_session.send_message(m_message_soup);

        if((string)m_message_soup.response_body.flatten().data == null
		|| (string)m_message_soup.response_body.flatten().data == "")
			return false;

        string response = (string)m_message_soup.response_body.flatten().data;
        logger.print(LogMessage.DEBUG, response);
        int start = response.index_of_char('=')+1;
        int end = response.index_of_char('&', start);

        string accessToken = response.substring(start, end-start);

        settings_pocket.set_string("oauth-access-token", accessToken);
        settings_pocket.set_boolean("is-logged-in", true);
        return true;
    }


    public bool addBookmark(string url)
    {
        string message = "url=" + GLib.Uri.escape_string(url) + "&consumer_key=" + PocketSecrets.oauth_consumer_key + "&access_token=" + settings_pocket.get_string("oauth-access-token");

        m_message_soup = new Soup.Message("POST", "https://getpocket.com/v3/add");
        m_message_soup.set_request(m_contenttype, Soup.MemoryUse.COPY, message.data);
		m_session.send_message(m_message_soup);

        if((string)m_message_soup.response_body.flatten().data == null
		|| (string)m_message_soup.response_body.flatten().data == "")
			return false;

        return true;
    }

}
