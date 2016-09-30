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

public class FeedReader.feedbinConnection {

	private feedbinUtils m_utils;
	private GLib.Settings m_settingsTweaks;

	private const string BASE_URI = "https://api.feedbin.com/v2/";

	public feedbinConnection()
	{
		m_utils = new feedbinUtils();
		m_settingsTweaks = new GLib.Settings("org.gnome.feedreader.tweaks");
	}

	public string postRequest(string path, string input)
	{
		var session = new Soup.Session();
		session.authenticate.connect((msg, auth, retrying) => {
			auth.authenticate(m_utils.getUser(), m_utils.getPasswd());
		});

		var message = new Soup.Message("POST", BASE_URI+path);
		if(m_settingsTweaks.get_boolean("do-not-track"))
				message.request_headers.append("DNT", "1");

		message.request_headers.append("Content-Type", "application/json; charset=utf-8");

		message.request_body.append_take(input.data);
		session.send_message(message);

		return (string)message.response_body.flatten().data;
    }

	public string deleteRequest(string path, string input)
	{
		var session = new Soup.Session();
		session.authenticate.connect((msg, auth, retrying) => {
			auth.authenticate(m_utils.getUser(), m_utils.getPasswd());
		});

		var message = new Soup.Message("DELETE", BASE_URI+path);
		if(m_settingsTweaks.get_boolean("do-not-track"))
				message.request_headers.append("DNT", "1");

		message.request_headers.append("Content-Type", "application/json; charset=utf-8");

		message.request_body.append_take(input.data);
		session.send_message(message);

		return (string)message.response_body.flatten().data;
    }

	public string getRequest(string path)
	{
		var session = new Soup.Session();
		session.authenticate.connect((msg, auth, retrying) => {
			auth.authenticate(m_utils.getUser(), m_utils.getPasswd());
		});

		var message = new Soup.Message("GET", BASE_URI+path);
		if(m_settingsTweaks.get_boolean("do-not-track"))
				message.request_headers.append("DNT", "1");

		session.send_message(message);
		return (string)message.response_body.data;
	}
}
