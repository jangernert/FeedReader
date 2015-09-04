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

public class FeedReader.ReadabilityAPI : GLib.Object {

    private Rest.OAuthProxy m_oauth;

    public ReadabilityAPI()
    {
        if(settings_readability.get_string("oauth-access-token") == "")
        {
            m_oauth = new Rest.OAuthProxy (
    			ReadabilitySecrets.oauth_consumer_key,
    			ReadabilitySecrets.oauth_consumer_secret,
    			ReadabilitySecrets.base_uri,
    			false);
        }
        else
        {
            m_oauth = new Rest.OAuthProxy.with_token (
    			ReadabilitySecrets.oauth_consumer_key,
    			ReadabilitySecrets.oauth_consumer_secret,
                settings_readability.get_string("oauth-access-token"),
                settings_readability.get_string("oauth-access-token-secret"),
    			ReadabilitySecrets.base_uri,
    			false);

            settings_readability.set_boolean("is-logged-in", true);
        }
    }

    public bool getRequestToken()
    {
        try
        {
			m_oauth.request_token("oauth/request_token", ReadabilitySecrets.oauth_callback);
		}
        catch (Error e)
        {
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

        settings_readability.set_string("oauth-access-token", m_oauth.get_token());
        settings_readability.set_string("oauth-access-token-secret", m_oauth.get_token_secret());
        getUsername();

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
		call.add_param("url", GLib.Uri.escape_string(url));
		call.add_param("favorite", "1");

        call.run_async((call, error, obj) => {}, null);
        return true;
    }

    public bool getUsername()
    {
        bool login = false;
        var call = m_oauth.new_call();
		m_oauth.url_format = "https://www.readability.com/api/rest/v1/";
		call.set_function ("users/_current");
		call.set_method("GET");

        try{
            call.run();
        }
        catch(Error e)
        {
            logger.print(LogMessage.ERROR, e.message);
        }

        if(call.get_status_code() == 403)
        {
            return login;
        }

        var parser = new Json.Parser();
        try{
            parser.load_from_data(call.get_payload());
        }
        catch (Error e) {
            logger.print(LogMessage.ERROR, "Could not load response to Message from readability");
            logger.print(LogMessage.ERROR, e.message);
        }

        var root_object = parser.get_root().get_object();
        if(root_object.has_member("username"))
        {
            string username = root_object.get_string_member("username");
            settings_readability.set_string("username", username);
            login = true;
        }

        settings_readability.set_boolean("is-logged-in", login);
        return login;
    }

    private bool isLoggedIn()
    {
        return settings_readability.get_boolean("is-logged-in");
    }

    public bool logout()
    {
        settings_readability.set_string("username", "");
        settings_readability.set_string("oauth-access-token", "");
        settings_readability.set_string("oauth-access-token-secret", "");
        settings_readability.set_string("oauth-verifier", "");
        settings_readability.set_string("oauth-request-token", "");
        settings_readability.set_boolean("is-logged-in", false);

        m_oauth = new Rest.OAuthProxy (
            ReadabilitySecrets.oauth_consumer_key,
            ReadabilitySecrets.oauth_consumer_secret,
            ReadabilitySecrets.base_uri,
            false);

        return true;
    }
}
