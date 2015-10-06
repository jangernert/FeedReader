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

    private Soup.Session m_session;
	private Soup.Message m_message_soup;
	private GLib.Settings m_settings;
    private string m_contenttype;
    private string m_id;
    private string m_requestToken;
    private string m_accessToken;
    private string m_username;
    private bool m_loggedIn;

    public PocketAPI(string id, string settings_path = "")
    {
    	m_id = id;
		m_session = new Soup.Session();
		m_contenttype = "application/x-www-form-urlencoded; charset=UTF8";

		if(settings_path == "")
		{
			m_settings = new Settings.with_path("org.gnome.feedreader.share.account", "/org/gnome/feedreader/share/pocket/%s/".printf(id));
			m_loggedIn = false;
		}
		else
		{
			m_settings = new Settings.with_path("org.gnome.feedreader.share.account", settings_path);
			m_username = m_settings.get_string("username");
			m_accessToken = m_settings.get_string("oauth-access-token");
			m_loggedIn = false;
		}
    }


    public bool getRequestToken()
    {
    	logger.print(LogMessage.DEBUG, "PocketAPI: get request token");
        string message = "consumer_key=" + PocketSecrets.oauth_consumer_key + "&redirect_uri=" + PocketSecrets.oauth_callback;

        m_message_soup = new Soup.Message("POST", "https://getpocket.com/v3/oauth/request");
        m_message_soup.set_request(m_contenttype, Soup.MemoryUse.COPY, message.data);

        if(settings_tweaks.get_boolean("do-not-track"))
				m_message_soup.request_headers.append("DNT", "1");

		m_session.send_message(m_message_soup);

        if((string)m_message_soup.response_body.flatten().data == null
		|| (string)m_message_soup.response_body.flatten().data == "")
			return false;

        string response = (string)m_message_soup.response_body.flatten().data;
        m_requestToken = response.substring(response.index_of_char('=')+1);
        return true;
    }


    public bool getAccessToken()
    {
        string message = "consumer_key=" + PocketSecrets.oauth_consumer_key + "&code=" + m_requestToken;

        m_message_soup = new Soup.Message("POST", "https://getpocket.com/v3/oauth/authorize");
        m_message_soup.set_request(m_contenttype, Soup.MemoryUse.COPY, message.data);

        if(settings_tweaks.get_boolean("do-not-track"))
				m_message_soup.request_headers.append("DNT", "1");

		m_session.send_message(m_message_soup);

        if((string)m_message_soup.response_body.flatten().data == null
		|| (string)m_message_soup.response_body.flatten().data == "")
			return false;

        string response = (string)m_message_soup.response_body.flatten().data;
        logger.print(LogMessage.DEBUG, response);
        int tokenStart = response.index_of_char('=')+1;
        int tokenEnd = response.index_of_char('&', tokenStart);
        int userStart = response.index_of_char('=', tokenEnd)+1;

        m_accessToken = response.substring(tokenStart, tokenEnd-tokenStart);
        m_username = GLib.Uri.unescape_string(response.substring(userStart));
        m_loggedIn = true;
        writeData();
        return true;
    }


    public bool addBookmark(string url)
    {
        string message = "url=" + GLib.Uri.escape_string(url) + "&consumer_key=" + PocketSecrets.oauth_consumer_key + "&access_token=" + m_accessToken;

        logger.print(LogMessage.DEBUG, "PocketAPI: " + message);

        m_message_soup = new Soup.Message("POST", "https://getpocket.com/v3/add");
        m_message_soup.set_request(m_contenttype, Soup.MemoryUse.COPY, message.data);

        if(settings_tweaks.get_boolean("do-not-track"))
				m_message_soup.request_headers.append("DNT", "1");

		m_session.send_message(m_message_soup);

        if((string)m_message_soup.response_body.flatten().data == null
		|| (string)m_message_soup.response_body.flatten().data == "")
			return false;

        return true;
    }

    public string getUsername()
    {
    	return m_username;
    }

    private bool isLoggedIn()
    {
        return m_loggedIn;
    }

    private void writeData()
    {
		m_settings.set_string("oauth-access-token", m_accessToken);
		m_settings.set_string("username", m_username);
		setArray();
    }

    private void setArray()
    {
		var array = settings_share.get_strv("pocket");

		foreach(string id in array)
		{
			if(id == m_id)
				return;
		}

		array += m_id;
		settings_share.set_strv("pocket", array);
    }


    private void deleteArray()
    {
    	var array = settings_share.get_strv("pocket");
    	string[] array2 = {};

    	foreach(string id in array)
		{
			if(id != m_id)
				array2 += id;
		}

		settings_share.set_strv("pocket", array2);
    }


    public bool logout()
    {
    	var keys = m_settings.list_keys();
		foreach(string key in keys)
		{
			m_settings.reset(key);
		}

		deleteArray();
        return true;
    }

    public string getURL()
    {
		return	"https://getpocket.com/auth/authorize?request_token="
				+ m_requestToken + "&redirect_uri="
				+ GLib.Uri.escape_string(PocketSecrets.oauth_callback);
    }

    public string getID()
    {
    	return m_id;
    }

}
