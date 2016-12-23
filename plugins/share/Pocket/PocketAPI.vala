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

namespace FeedReader.PocketSecrets {
	const string base_uri			= "https://getpocket.com/v3/";
	const string oauth_consumer_key		= "43273-30a11c29b5eeabfa905df168";
	const string oauth_callback			= "feedreader://pocket";
}

public class FeedReader.PocketAPI : ShareAccountInterface, Peas.ExtensionBase {

    public PocketAPI()
    {

    }

	public void setupSystemAccounts(Gee.ArrayList<ShareAccount> accounts)
	{
		try
		{
			Goa.Client? client = new Goa.Client.sync();
			if(client != null)
			{
				var goaAccounts = client.get_accounts();
				foreach(var object in goaAccounts)
				{
					if(object.account.provider_type == "pocket"
					&& !object.account.read_later_disabled)
					{
						accounts.add(
							new ShareAccount(
								object.account.id,
								pluginID(),
								object.account.identity,
								getIconName(),
								pluginName(),
								true
							)
						);
					}
				}
			}
			else
			{
				Logger.error("PocketAPI: goa not available");
			}
		}
		catch(GLib.Error e)
		{
			Logger.error("PocketAPI.setupSystemAccounts: %s".printf(e.message));
		}
	}

    public string getRequestToken()
    {
    	Logger.debug("PocketAPI: get request token");
        var session = new Soup.Session();
		session.user_agent = Constants.USER_AGENT;
        string message = "consumer_key=" + PocketSecrets.oauth_consumer_key + "&redirect_uri=" + PocketSecrets.oauth_callback;

        var message_soup = new Soup.Message("POST", "https://getpocket.com/v3/oauth/request");
        message_soup.set_request("application/x-www-form-urlencoded; charset=UTF8", Soup.MemoryUse.COPY, message.data);

        if(Settings.tweaks().get_boolean("do-not-track"))
				message_soup.request_headers.append("DNT", "1");

		session.send_message(message_soup);

        string response = (string)message_soup.response_body.flatten().data;
        return response.substring(response.index_of_char('=')+1);
    }

    public bool getAccessToken(string id, string requestToken)
    {
        var session = new Soup.Session();
		session.user_agent = Constants.USER_AGENT;
        string message = "consumer_key=" + PocketSecrets.oauth_consumer_key + "&code=" + requestToken;

        var message_soup = new Soup.Message("POST", "https://getpocket.com/v3/oauth/authorize");
        message_soup.set_request("application/x-www-form-urlencoded; charset=UTF8", Soup.MemoryUse.COPY, message.data);

        if(Settings.tweaks().get_boolean("do-not-track"))
				message_soup.request_headers.append("DNT", "1");

		session.send_message(message_soup);

        if((string)message_soup.response_body.flatten().data == null
		|| (string)message_soup.response_body.flatten().data == "")
			return false;

        string response = (string)message_soup.response_body.flatten().data;
        Logger.debug(response);
        int tokenStart = response.index_of_char('=')+1;
        int tokenEnd = response.index_of_char('&', tokenStart);
        int userStart = response.index_of_char('=', tokenEnd)+1;

        string accessToken = response.substring(tokenStart, tokenEnd-tokenStart);
        string user = GLib.Uri.unescape_string(response.substring(userStart));
        var settings = new GLib.Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/pocket/%s/".printf(id));
        settings.set_string("oauth-access-token", accessToken);
        settings.set_string("username", user);

        var array = Settings.share().get_strv("pocket");
        array += id;
		Settings.share().set_strv("pocket", array);

        return true;
    }


    public bool addBookmark(string id, string url, bool system)
    {
		string oauthToken = "";

		if(system)
		{
			Logger.debug(@"PocketAPI.addBookmark: $id is system account");
			try
			{
				Goa.Client? client = new Goa.Client.sync();
				if(client != null)
				{
					var accounts = client.get_accounts();
					foreach(var object in accounts)
					{
						if(object.account.provider_type == "pocket"
						&& object.account.id == id)
						{
							int expires = -1;
							object.oauth2_based.call_get_access_token_sync(out oauthToken, out expires);
							break;
						}
					}
				}
				else
				{
					Logger.error("PocketAPI: goa not available");
				}
			}
			catch(GLib.Error e)
			{
				Logger.error("PocketAPI GOA: %s".printf(e.message));
			}
		}
		else
		{
			var settings = new GLib.Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/pocket/%s/".printf(id));
			oauthToken = settings.get_string("oauth-access-token");
		}


        var session = new Soup.Session();
		session.user_agent = Constants.USER_AGENT;
        string message = "url=" + GLib.Uri.escape_string(url)
                        + "&consumer_key=" + PocketSecrets.oauth_consumer_key
                        + "&access_token=" + oauthToken;

        Logger.debug("PocketAPI: " + message);

        var message_soup = new Soup.Message("POST", "https://getpocket.com/v3/add");
        message_soup.set_request("application/x-www-form-urlencoded; charset=UTF8", Soup.MemoryUse.COPY, message.data);

        if(Settings.tweaks().get_boolean("do-not-track"))
				message_soup.request_headers.append("DNT", "1");

		session.send_message(message_soup);

        if((string)message_soup.response_body.flatten().data == null
		|| (string)message_soup.response_body.flatten().data == "")
			return false;

        return true;
    }

    public bool logout(string id)
    {
		Logger.debug(@"PocketAPI: logout($id)");
        var settings = new GLib.Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/pocket/%s/".printf(id));
    	var keys = settings.list_keys();
		foreach(string key in keys)
		{
			settings.reset(key);
		}

        var array = Settings.share().get_strv("pocket");
    	string[] array2 = {};

    	foreach(string i in array)
		{
			if(i != id)
				array2 += i;
		}
		Settings.share().set_strv("pocket", array2);
		deleteAccount(id);

        return true;
    }

    public string getURL(string token)
    {
		return	"https://getpocket.com/auth/authorize?request_token="
				+ token + "&redirect_uri="
				+ GLib.Uri.escape_string(PocketSecrets.oauth_callback);
    }

    public string getIconName()
    {
        return "feed-share-pocket";
    }

    public string getUsername(string id)
    {
        var settings = new GLib.Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/pocket/%s/".printf(id));
        return settings.get_string("username");
    }

    public bool needSetup()
	{
		return true;
	}

	public bool useSystemAccounts()
    {
		try
		{
			Goa.Client? client = new Goa.Client.sync();
			if(client != null)
				return true;

	        return false;
		}
		catch(GLib.Error e)
		{
			Logger.debug("PocketAPI.useSystemAccounts(): %s".printf(e.message));
			return false;
		}
    }

    public string pluginID()
    {
        return "pocket";
    }

    public string pluginName()
    {
        return "Pocket";
    }

    public ServiceSetup? newSetup_withID(string id, string username)
    {
        return new PocketSetup(id, this, username);
    }

    public ServiceSetup? newSetup()
    {
        return new PocketSetup(null, this);
    }

	public ServiceSetup? newSystemAccount(string id, string username)
	{
		return new PocketSetup(id, this, username, true);
	}

	public ShareForm? shareWidget(string url)
	{
		return null;
	}
}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.ShareAccountInterface), typeof(FeedReader.PocketAPI));
}
