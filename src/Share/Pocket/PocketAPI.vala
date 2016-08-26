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

public class FeedReader.PocketAPI : GLib.Object {


    public static string getRequestToken()
    {
    	logger.print(LogMessage.DEBUG, "PocketAPI: get request token");
        var session = new Soup.Session();
        string message = "consumer_key=" + PocketSecrets.oauth_consumer_key + "&redirect_uri=" + PocketSecrets.oauth_callback;

        var message_soup = new Soup.Message("POST", "https://getpocket.com/v3/oauth/request");
        message_soup.set_request("application/x-www-form-urlencoded; charset=UTF8", Soup.MemoryUse.COPY, message.data);

        if(settings_tweaks.get_boolean("do-not-track"))
				message_soup.request_headers.append("DNT", "1");

		session.send_message(message_soup);

        string response = (string)message_soup.response_body.flatten().data;
        return response.substring(response.index_of_char('=')+1);
    }


    public static bool getAccessToken(string requestToken, string id)
    {
        var session = new Soup.Session();
        string message = "consumer_key=" + PocketSecrets.oauth_consumer_key + "&code=" + requestToken;

        var message_soup = new Soup.Message("POST", "https://getpocket.com/v3/oauth/authorize");
        message_soup.set_request("application/x-www-form-urlencoded; charset=UTF8", Soup.MemoryUse.COPY, message.data);

        if(settings_tweaks.get_boolean("do-not-track"))
				message_soup.request_headers.append("DNT", "1");

		session.send_message(message_soup);

        if((string)message_soup.response_body.flatten().data == null
		|| (string)message_soup.response_body.flatten().data == "")
			return false;

        string response = (string)message_soup.response_body.flatten().data;
        logger.print(LogMessage.DEBUG, response);
        int tokenStart = response.index_of_char('=')+1;
        int tokenEnd = response.index_of_char('&', tokenStart);
        int userStart = response.index_of_char('=', tokenEnd)+1;

        string accessToken = response.substring(tokenStart, tokenEnd-tokenStart);
        string username = GLib.Uri.unescape_string(response.substring(userStart));
        var settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/pocket/%s/".printf(id));
        settings.set_string("oauth-access-token", accessToken);
        settings.set_string("username", username);

        var array = settings_share.get_strv("pocket");
        array += id;
		settings_share.set_strv("pocket", array);

        return true;
    }


    public static bool addBookmark(string id, string url)
    {
        var settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/pocket/%s/".printf(id));

        var session = new Soup.Session();
        string message = "url=" + GLib.Uri.escape_string(url)
                        + "&consumer_key=" + PocketSecrets.oauth_consumer_key
                        + "&access_token=" + settings.get_string("oauth-access-token");

        logger.print(LogMessage.DEBUG, "PocketAPI: " + message);

        var message_soup = new Soup.Message("POST", "https://getpocket.com/v3/add");
        message_soup.set_request("application/x-www-form-urlencoded; charset=UTF8", Soup.MemoryUse.COPY, message.data);

        if(settings_tweaks.get_boolean("do-not-track"))
				message_soup.request_headers.append("DNT", "1");

		session.send_message(message_soup);

        if((string)message_soup.response_body.flatten().data == null
		|| (string)message_soup.response_body.flatten().data == "")
			return false;

        return true;
    }

    public static bool logout(string id)
    {
        var settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/pocket/%s/".printf(id));
    	var keys = settings.list_keys();
		foreach(string key in keys)
		{
			settings.reset(key);
		}

        var array = settings_share.get_strv("pocket");
    	string[] array2 = {};

    	foreach(string i in array)
		{
			if(i != id)
				array2 += i;
		}
		settings_share.set_strv("pocket", array2);

        return true;
    }

    public static string getURL(string token)
    {
		return	"https://getpocket.com/auth/authorize?request_token="
				+ token + "&redirect_uri="
				+ GLib.Uri.escape_string(PocketSecrets.oauth_callback);
    }

    public static string getIconName()
    {
        return "feed-share-pocket";
    }

    public static string getUsername(string id)
    {
        var settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/pocket/%s/".printf(id));
        return settings.get_string("username");
    }

}
