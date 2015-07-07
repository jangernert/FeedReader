public class FeedReader.ReadabilityAPI : GLib.Object {

    private Rest.OAuthProxy m_oauth;

    public ReadabilityAPI()
    {
        m_oauth = new Rest.OAuthProxy (
			ReadabilitySecrets.oauth_consumer_key,
			ReadabilitySecrets.oauth_consumer_secret,
			ReadabilitySecrets.base_uri,
			false);
    }

    public bool getRequestToken()
    {
        try {
			m_oauth.request_token ("oauth/request_token", ReadabilitySecrets.oauth_callback);
		} catch (Error e) {
			logger.print(LogMessage.ERROR, "ReadabilityAPI: cannot get request token: " + e.message);
            return false;
		}

        settings_readability.set_string("oauth-request-token", m_oauth.get_token());
        return true;
    }

    public bool getAccessToken()
    {
        if(settings_readability.get_string("oauth-verifier") == "")
        {
            return false;
        }

        try {
			m_oauth.access_token("oauth/access_token", settings_readability.get_string("oauth-verifier"));
		} catch (Error e) {
			logger.print(LogMessage.ERROR, "ReadabilityAPI: cannot get access token: " + e.message);
            return false;
		}

        settings_readability.set_boolean("is-logged-in", true);

        return true;
    }

    public bool addBookmark(string url)
    {
        if(!isLoggedIn())
            return false;

        var call = m_oauth.new_call();
		m_oauth.url_format = "https://www.readability.com/api/rest/v1/";
		call.set_function ("bookmarks");
		call.set_method("POST");
		call.add_param("url", url);
		call.add_param("favorite", "1");

        call.run_async ((call, error, obj) => {}, null);
        return true;
    }

    private bool isLoggedIn()
    {
        return settings_readability.get_boolean("is-logged-in");
    }
}
