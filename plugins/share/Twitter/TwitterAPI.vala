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

namespace FeedReader.TwitterSecrets {
	const string base_uri			= "https://api.twitter.com/";
	const string key				= "hqScCfRLj5ImAtwypRKhbVpXo";
	const string secret				= "wydD2zd6mgBUnlrdbqNqS0U0dJCWBJ9X0cqtdErk8Hn7aeperP";
	const string callback			= "feedreader://twitter";
}

public class FeedReader.TwitterAPI : ShareAccountInterface, Peas.ExtensionBase {

	private Rest.OAuthProxy m_oauthObject;
	private string m_tweet;
    public Logger m_logger { get; construct set; }

    public TwitterAPI()
    {

    }

    public string getRequestToken()
    {
		m_logger.print(LogMessage.DEBUG, "TwitterAPI: get request token");

		m_oauthObject = new Rest.OAuthProxy (
            TwitterSecrets.key,
            TwitterSecrets.secret,
            "https://api.twitter.com/",
            false);


        m_oauthObject.request_token("oauth/request_token", TwitterSecrets.callback);
		return m_oauthObject.get_token();
    }

    public bool getAccessToken(string id, string verifier)
    {
		m_oauthObject.access_token("oauth/access_token", verifier);

        var settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/twitter/%s/".printf(id));
		string token = m_oauthObject.get_token();
		string secret = m_oauthObject.get_token_secret();
		settings.set_string("oauth-access-token", token);
		settings.set_string("oauth-access-token-secret", secret);

		var call = m_oauthObject.new_call();
		call.set_function("1.1/account/verify_credentials.json");
		call.set_method("GET");
		call.add_param ("include_entities", "false");
		call.add_param ("skip_status", "true");
		call.add_param ("include_email", "true");

		try
		{
            call.run();
        }
        catch(Error e)
        {
            m_logger.print(LogMessage.ERROR, e.message);
		}

		var parser = new Json.Parser();
        try
		{
            parser.load_from_data(call.get_payload());
        }
        catch(Error e)
		{
            m_logger.print(LogMessage.ERROR, "Could not load response to Message from twitter");
            m_logger.print(LogMessage.ERROR, e.message);
		}

		var root_object = parser.get_root().get_object();

		if(root_object.has_member("screen_name"))
		{
			string screenName = "@" + root_object.get_string_member("screen_name");
			settings.set_string("username", screenName);
		}
		else
		{
			settings.set_string("username", root_object.get_string_member("name"));
		}



		var shareSettings = new GLib.Settings("org.gnome.feedreader.share");
        var array = shareSettings.get_strv("twitter");
        array += id;
		shareSettings.set_strv("twitter", array);

        return true;
    }


    public bool addBookmark(string id, string url)
    {
		var settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/twitter/%s/".printf(id));
		string token = settings.get_string("oauth-access-token");
		string secret = settings.get_string("oauth-access-token-secret");

		var oauthObject = new Rest.OAuthProxy.with_token (
            TwitterSecrets.key,
            TwitterSecrets.secret,
			token,
			secret,
            "https://api.twitter.com/",
            false);

		var call = oauthObject.new_call();
		call.set_function("1.1/statuses/update.json");
		call.set_method("POST");
		call.add_param ("status", m_tweet.replace("$URL", url));

		try
		{
            call.run();
        }
        catch(Error e)
        {
            m_logger.print(LogMessage.ERROR, e.message);
			return false;
		}

        return true;
    }

    public bool logout(string id)
    {
        var settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/twitter/%s/".printf(id));
    	var keys = settings.list_keys();
		foreach(string key in keys)
		{
			settings.reset(key);
		}

		var shareSettings = new GLib.Settings("org.gnome.feedreader.share");
        var array = shareSettings.get_strv("twitter");
    	string[] array2 = {};

    	foreach(string i in array)
		{
			if(i != id)
				array2 += i;
		}
		shareSettings.set_strv("twitter", array2);
		deleteAccount(id);

        return true;
    }

    public string getURL(string token)
    {
		return	TwitterSecrets.base_uri
				+ "oauth/authenticate"
				+ "?oauth_token=" + token;
    }

    public string getIconName()
    {
        return "feed-share-twitter";
    }

    public string getUsername(string id)
    {
        var settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/twitter/%s/".printf(id));
        return settings.get_string("username");
    }

    public bool needSetup()
	{
		return true;
	}

    public string pluginID()
    {
        return "twitter";
    }

    public string pluginName()
    {
        return "Twitter";
    }

    public ServiceSetup? newSetup_withID(string id, string username)
    {
        return new TwitterSetup(id, this, username);
    }

    public ServiceSetup? newSetup()
    {
        return new TwitterSetup(null, this);
    }

	public ShareForm? shareWidget(string url)
	{
		var widget = new TwitterForm(url);
		widget.share.connect(() => {
			m_tweet = widget.getTweet();
		});
		return widget;
	}

	public static int getUrlLength()
	{
		var shareSettings = new GLib.Settings("org.gnome.feedreader.share");
        var array = shareSettings.get_strv("twitter");
		string id = array[0];

		var settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/twitter/%s/".printf(id));
		string token = settings.get_string("oauth-access-token");
		string secret = settings.get_string("oauth-access-token-secret");

		var oauthObject = new Rest.OAuthProxy.with_token (
            TwitterSecrets.key,
            TwitterSecrets.secret,
			token,
			secret,
            "https://api.twitter.com/",
            false);

		var call = oauthObject.new_call();
		call.set_function("1.1/help/configuration.json");
		call.set_method("GET");

		try
		{
            call.run();
        }
        catch(Error e){}

		var parser = new Json.Parser();
        try
		{
            parser.load_from_data(call.get_payload());
        }
        catch(Error e){}

		var root_object = parser.get_root().get_object();
		return (int)root_object.get_int_member("short_url_length");
	}
}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.ShareAccountInterface), typeof(FeedReader.TwitterAPI));
}
