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

public class FeedReader.FeedbinConnection {

	private FeedbinUtils m_utils;
	private GLib.Settings m_settingsTweaks;
	private Soup.Session m_session;

	private const string BASE_URI = "https://api.feedbin.com/v2/";

	public FeedbinConnection()
	{
		m_utils = new FeedbinUtils();
		m_settingsTweaks = new GLib.Settings("org.gnome.feedreader.tweaks");
		m_session = new Soup.Session();
		m_session.user_agent = Constants.USER_AGENT;
		m_session.authenticate.connect((msg, auth, retrying) => {
			if(!retrying)
				auth.authenticate(m_utils.getUser(), m_utils.getPasswd());
		});
	}

	public Response request(string method, string path, string? input = null)
	{
		var message = new Soup.Message(method, BASE_URI+path);
		if(m_settingsTweaks.get_boolean("do-not-track"))
			message.request_headers.append("DNT", "1");

		if(method == "POST" || method == "PUT")
			message.request_headers.append("Content-Type", "application/json; charset=utf-8");

		if(input != null)
			message.request_body.append_take(input.data);

		m_session.send_message(message);

		return Response() {
			status = message.status_code,
			data = (string)message.response_body.flatten().data,
			headers = message.response_headers
		};
	}

	public Response postRequest(string path, string input)
	{
		return request("POST", path, input);
	}

	public Response deleteRequest(string path, string? input = null)
	{
		return request("DELETE", path, input);
	}

	public Response getRequest(string path)
	{
		return request("GET", path);
	}
}
