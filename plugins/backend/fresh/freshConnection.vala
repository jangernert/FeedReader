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

public class FeedReader.freshConnection {

	private freshUtils m_utils;
	private GLib.Settings m_settingsTweaks;

	public freshConnection()
	{
		m_utils = new freshUtils();
		m_settingsTweaks = new GLib.Settings("org.gnome.feedreader.tweaks");
	}

	public LoginResponse getSID()
	{
		var session = new Soup.Session();
		var message = new Soup.Message("POST", m_utils.getURL()+"accounts/ClientLogin");

		var msg = new freshMessage();
		msg.add("Email", m_utils.getUser());
		msg.add("Passwd", m_utils.getPasswd());

		message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, msg.get().data);
		session.send_message(message);

		if((string)message.response_body.flatten().data == null
		|| (string)message.response_body.flatten().data == "")
		{
			Logger.error("No response from freshRSS to message");
			Logger.error(msg.get());
			return LoginResponse.NO_CONNECTION;
		}

		string response = (string)message.response_body.flatten().data;

		if(!response.has_prefix("SID="))
		{
			m_utils.setToken("");
			m_utils.setUser("");
			m_utils.setURL("");
			return LoginResponse.WRONG_LOGIN;
		}
		else
		{
			int start = response.index_of("=")+1;
			int end = response.index_of("\n");
			string token = response.substring(start, end-start);
			Logger.debug("Token: " + token);
			m_utils.setToken(token);
			return LoginResponse.SUCCESS;
		}
	}

	public string getToken()
	{
		return getRequest("reader/api/0/token").replace("\n", "");
	}

	public string postRequest(string path, string input, string type)
	{
		var session = new Soup.Session();
		var message = new Soup.Message("POST", m_utils.getURL()+path);

		if(m_settingsTweaks.get_boolean("do-not-track"))
				message.request_headers.append("DNT", "1");

		message.request_headers.append("Authorization","GoogleLogin auth=%s".printf(m_utils.getToken()));
		message.request_headers.append("Content-Type", type);

		message.request_body.append_take(input.data);
		session.send_message(message);

		return (string)message.response_body.flatten().data;
    }

	public string getRequest(string path)
	{
		var session = new Soup.Session();
		var message = new Soup.Message("GET", m_utils.getURL()+path);
		message.request_headers.append("Authorization","GoogleLogin auth=%s".printf(m_utils.getToken()));

		if(m_settingsTweaks.get_boolean("do-not-track"))
				message.request_headers.append("DNT", "1");

		session.send_message(message);
		return (string)message.response_body.data;
	}
}


public class FeedReader.freshMessage {

	string request = "";

	public freshMessage()
	{

	}

	public void add(string parameter, string val)
	{
		if(request != "")
			request += "&";

		request += parameter;
		request += "=";
		request += GLib.Uri.escape_string(val);
	}

	public string get()
	{
		return request;
	}
}
