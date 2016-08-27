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

    public static const string ID = "readability";

    public static string getRequestToken()
    {
        try
        {
            var oauthObject = new Rest.OAuthProxy (
                ReadabilitySecrets.oauth_consumer_key,
                ReadabilitySecrets.oauth_consumer_secret,
                ReadabilitySecrets.base_uri,
                false);

			oauthObject.request_token("oauth/request_token", ReadabilitySecrets.oauth_callback);
            return oauthObject.get_token();
		}
        catch (Error e)
        {
			logger.print(LogMessage.ERROR, "ReadabilityAPI: cannot get request token: " + e.message);
		}

        return "";
    }

    public static bool getAccessToken(string verifier, string id)
    {
        try
        {
            var oauthObject = new Rest.OAuthProxy (
                ReadabilitySecrets.oauth_consumer_key,
                ReadabilitySecrets.oauth_consumer_secret,
                ReadabilitySecrets.base_uri,
                false);

			oauthObject.access_token("oauth/access_token", verifier);

            string accessToken = oauthObject.get_token();
    		string secret = oauthObject.get_token_secret();
            string username = "";
            var settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/readability/%s/".printf(id));


            // get username -----------------------------------------------------------------------
            var call = oauthObject.new_call();
    		oauthObject.url_format = "https://www.readability.com/api/rest/v1/";
    		call.set_function("users/_current");
    		call.set_method("GET");
            try
            {
                call.run();
            }
            catch(Error e)
            {
                logger.print(LogMessage.ERROR, e.message);
            }
            if(call.get_status_code() == 403)
            {
                return false;
            }
            var parser = new Json.Parser();

            try
            {
                parser.load_from_data(call.get_payload());
            }
            catch(Error e)
            {
                logger.print(LogMessage.ERROR, "Could not load response to Message from readability");
                logger.print(LogMessage.ERROR, e.message);
            }

            var root_object = parser.get_root().get_object();
            if(root_object.has_member("username"))
                username = root_object.get_string_member("username");
            // -----------------------------------------------------------------------------------------------

            settings.set_string("oauth-access-token", accessToken);
    		settings.set_string("oauth-access-token-secret", secret);
    		settings.set_string("username", username);

            var array = settings_share.get_strv("readability");
    		array += id;
    		settings_share.set_strv("readability", array);

            return true;
		}
        catch(Error e)
        {
			logger.print(LogMessage.ERROR, "ReadabilityAPI: cannot get access token: " + e.message);
		}

        return false;
    }

    public static bool addBookmark(string id, string url)
    {
        var settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/readability/%s/".printf(id));

        var oauthObject = new Rest.OAuthProxy.with_token (
            ReadabilitySecrets.oauth_consumer_key,
            ReadabilitySecrets.oauth_consumer_secret,
            settings.get_string("oauth-access-token"),
            settings.get_string("oauth-access-token-secret"),
            ReadabilitySecrets.base_uri,
            false);

        var call = oauthObject.new_call();
		oauthObject.url_format = "https://www.readability.com/api/rest/v1/";
		call.set_function ("bookmarks");
		call.set_method("POST");
		call.add_param("url", url);
		call.add_param("favorite", "1");

        call.run_async((call, error, obj) => {
        	logger.print(LogMessage.DEBUG, "ReadabilityAPI: status code " + call.get_status_code().to_string());
        	logger.print(LogMessage.DEBUG, "ReadabilityAPI: payload " + call.get_payload());
        }, null);
        return true;
    }


    public static bool logout(string id)
    {
        var settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/readability/%s/".printf(id));
    	var keys = settings.list_keys();
		foreach(string key in keys)
		{
			settings.reset(key);
		}

        var array = settings_share.get_strv("readability");
    	string[] array2 = {};

    	foreach(string i in array)
		{
			if(i != id)
				array2 += i;
		}
		settings_share.set_strv("readability", array2);

        return true;
    }

    public static string getURL(string token)
    {
		return	ReadabilitySecrets.base_uri + "oauth/authorize/" + "?oauth_token=" + token;
    }

    public static string getIconName()
    {
        return "feed-share-readability";
    }

    public static string getUsername(string id)
    {
        var settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/readability/%s/".printf(id));
        return settings.get_string("username");
    }

    public static bool isArg(string arg)
    {
        if(arg.has_prefix(ReadabilitySecrets.oauth_callback))
            return true;

        return false;
    }

    public static string parseArgs(string arg)
    {
		int verifier_start = arg.index_of("=")+1;
		int verifier_end = arg.index_of("&", verifier_start);
		return arg.substring(verifier_start, verifier_end-verifier_start);
    }
}
