public class FeedReader.ReadabilityAPI : GLib.Object {

    private Soup.Session m_session;
    private Json.Parser m_parser;
	private Json.Object m_root_object;
    private string m_contenttype;
    private string m_consumer_key;
    private string m_consumer_secret;

    public ReadabilityAPI()
    {
    	m_consumer_key = "jangernert";
    	m_consumer_secret = "3NSxqNW5d6zVwvZV6tskzVrqctHZceHr";
        m_session = new Soup.Session();
		m_contenttype = "application/x-www-form-urlencoded";
		m_parser = new Json.Parser();
    }

    public ConnectionError login_XAuth(string username, string password)
	{
        var message_soup = new Soup.Message("POST", "https://www.readability.com/api/rest/v1/oauth/access_token/");

        var now = new DateTime.now_local();
        string timestamp = now.to_unix().to_string();

		string message =
                "oauth_nonce=testnonce"
            +   "&oauth_timestamp=" + timestamp
            +   "&oauth_consumer_key=" + m_consumer_key
            +   "&oauth_consumer_secret=" + m_consumer_secret
            +   "&x_auth_username=" + username
            +   "&x_auth_password=" + password
            +   "&oauth_signature=" + m_consumer_secret + "%26";

        message_soup.set_request(m_contenttype, Soup.MemoryUse.COPY, message.data);
        m_session.send_message(message_soup);

        if((string)message_soup.response_body.flatten().data == null
		|| (string)message_soup.response_body.flatten().data == "")
			return ConnectionError.NO_RESPONSE;

        string response = (string)message_soup.response_body.flatten().data;

        if(response.has_prefix("oauth_token_secret="))
        {
            int secret_start = response.index_of_char('=');
            int secret_end = response.index_of_char('&', secret_start);
            string secret = response.substring(secret_start+1, secret_end-secret_start-1);
            logger.print(LogMessage.DEBUG, "readability api token secret: " + secret);
            settings_readability.set_string("oauth-token-secret", secret);

            int token_start = response.index_of_char('=', secret_end);
            int token_end = response.index_of_char('&', token_start);
            string token = response.substring(token_start+1, token_end-token_start-1);
            logger.print(LogMessage.DEBUG, "readability api token: " + token);
            settings_readability.set_string("oauth-token", token);

            return ConnectionError.SUCCESS;
        }

        return ConnectionError.UNKNOWN;
	}

    public ConnectionError login_OAuth(string username, string password)
    {

        return ConnectionError.UNKNOWN;
    }

    public ConnectionError bookmark(string url)
    {
        var message_soup = new Soup.Message("POST", "https://www.readability.com/api/rest/v1/bookmarks");

        var now = new DateTime.now_local();
        string timestamp = now.to_unix().to_string();
        string nonce = Utils.string_random(42);

        string message =
                    "oauth_nonce=" + nonce
                +   "&oauth_consumer_key=" + m_consumer_key
                +   "&oauth_signature=" + generateSignature(nonce, timestamp, url)
                +   "&oauth_signature_method=HMAC-SHA1"
                +   "&oauth_timestamp" + timestamp
                +   "&oauth_token" + settings_readability.get_string("oauth-token")
                +   "oauth_version=1.0"
                +   "&url=" + Uri.escape_string(url)
                +   "&favorite=1";

        message_soup.set_request(m_contenttype, Soup.MemoryUse.COPY, message.data);
        m_session.send_message(message_soup);

        if((string)message_soup.response_body.flatten().data == null
		|| (string)message_soup.response_body.flatten().data == "")
			return ConnectionError.NO_RESPONSE;

        string response = (string)message_soup.response_body.flatten().data;
        logger.print(LogMessage.DEBUG, response);

        return ConnectionError.UNKNOWN;
    }

    // https://dev.twitter.com/oauth/overview/creating-signatures
    private string generateSignature(string nonce, string timestamp, string url)
    {
        string method = "POST";
        string baseURL = "https://www.readability.com/api/rest/v1/bookmarks";

        string signatureBase = "";
        string parameterString = "";
        string signingKey = "";

        parameterString += "&" +    Uri.escape_string("favorite")               + "=" + Uri.escape_string("1");
        parameterString +=          Uri.escape_string("oauth_consumer_key")     + "=" + Uri.escape_string(m_consumer_key);
        parameterString += "&" +    Uri.escape_string("oauth_nonce")            + "=" + Uri.escape_string(nonce);
        parameterString += "&" +    Uri.escape_string("oauth_signature_method") + "=" + Uri.escape_string("HMAC-SHA1");
        parameterString += "&" +    Uri.escape_string("oauth_timestamp")        + "=" + Uri.escape_string(timestamp);
        parameterString += "&" +    Uri.escape_string("oauth_token")            + "=" + Uri.escape_string(settings_readability.get_string("oauth-token"));
        parameterString += "&" +    Uri.escape_string("oauth_version")          + "=" + Uri.escape_string("1.0");
        parameterString += "&" +    Uri.escape_string("url")                    + "=" + Uri.escape_string(url);


        signatureBase += method + "&" + Uri.escape_string(baseURL) + "&" + Uri.escape_string(parameterString);
        signingKey += Uri.escape_string(m_consumer_secret) + "&" + Uri.escape_string(settings_readability.get_string("oauth-token-secret"));

        var encoder = new GLib.Hmac(GLib.ChecksumType.SHA1, signingKey.data);
        encoder.update(signatureBase.data);

        return Base64.encode(encoder.get_string().data);
    }
}
