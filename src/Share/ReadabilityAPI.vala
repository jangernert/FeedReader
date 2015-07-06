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
                "oauth_nonce=" + Utils.string_random(42)
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

    public ConnectionError login_OAuth()
    {
        var message_soup = new Soup.Message("POST", "https://www.readability.com/api/rest/v1/oauth/access_token/");

        var now = new DateTime.now_local();
        string timestamp = now.to_unix().to_string();
        string nonce = Utils.string_random(42);
        string message = "";

        var parameters = new GLib.List<StringPair>();
        parameters.append(new StringPair("oauth_nonce", nonce));
        parameters.append(new StringPair("oauth_timestamp", timestamp));
        parameters.append(new StringPair("oauth_token", settings_readability.get_string("oauth-token")));
        parameters.append(new StringPair("oauth_consumer_key", m_consumer_key));
        parameters.append(new StringPair("oauth_verifier", settings_readability.get_string("oauth-verifier")));

        string signature = generateSignature(parameters, "https://www.readability.com/api/rest/v1/oauth/access_token/");
        parameters.append(new StringPair("oauth_signature", signature + "%26"));

        foreach(StringPair par in parameters)
        {
            message += par.getString1() + "=" + par.getString2() + "&";
        }
        message = message.substring(0, message.length-1);
        logger.print(LogMessage.DEBUG, "message: " + message);


        message_soup.set_request(m_contenttype, Soup.MemoryUse.COPY, message.data);
        m_session.send_message(message_soup);

        if((string)message_soup.response_body.flatten().data == null
    	|| (string)message_soup.response_body.flatten().data == "")
    		return ConnectionError.NO_RESPONSE;

        string response = (string)message_soup.response_body.flatten().data;
        logger.print(LogMessage.DEBUG, response);


        return ConnectionError.UNKNOWN;
    }

    public ConnectionError bookmark(string url)
    {
        var message_soup = new Soup.Message("POST", "https://www.readability.com/api/rest/v1/bookmarks");

        var now = new DateTime.now_local();
        string timestamp = now.to_unix().to_string();
        string nonce = Utils.string_random(42);
        string message = "";

        var parameters = new GLib.List<StringPair>();
        parameters.append(new StringPair("oauth_nonce", nonce));
        parameters.append(new StringPair("oauth_consumer_key", m_consumer_key));
        parameters.append(new StringPair("oauth_signature_method", nonce));
        parameters.append(new StringPair("oauth_nonce", "HMAC-SHA1"));
        parameters.append(new StringPair("oauth_timestamp", timestamp));
        parameters.append(new StringPair("oauth_token", settings_readability.get_string("oauth-token")));
        parameters.append(new StringPair("oauth_version", "1.0"));
        parameters.append(new StringPair("url", Uri.escape_string(url)));
        parameters.append(new StringPair("favorite", "1"));

        string signature = generateSignature(parameters, "https://www.readability.com/api/rest/v1/bookmarks");
        parameters.append(new StringPair("oauth_signature", signature));

        foreach(StringPair par in parameters)
        {
            message += par.getString1() + "=" + par.getString2() + "&";
        }
        message = message.substring(0, message.length-1);
        logger.print(LogMessage.DEBUG, "message: " + message);

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
    private string generateSignature(GLib.List<StringPair> parameters, string baseURL)
    {
        string method = "POST";

        string signatureBase = "";
        string parameterString = "";
        string signingKey = "";

        foreach(StringPair par in parameters)
        {
            parameterString += Uri.escape_string(par.getString1()) + "=" + Uri.escape_string(par.getString2()) + "&";
        }
        parameterString = parameterString.substring(0, parameterString.length-1);
        logger.print(LogMessage.DEBUG, "ParameterString: " + parameterString);

        signatureBase += method + "&" + Uri.escape_string(baseURL) + "&" + Uri.escape_string(parameterString);
        signingKey += Uri.escape_string(m_consumer_secret) + "&" + Uri.escape_string(settings_readability.get_string("oauth-token-secret"));

        var encoder = new GLib.Hmac(GLib.ChecksumType.SHA1, signingKey.data);
        encoder.update(signatureBase.data);

        return Base64.encode(encoder.get_string().data);
    }
}
