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

public class FeedReader.bazquxConnection {
	private string m_username;
	private string m_api_code;
	private string m_passwd;
	private bazquxUtils m_utils;
	private Soup.Session m_session;

	public bazquxConnection()
	{
		m_utils = new bazquxUtils();
		m_username = m_utils.getUser();
		m_api_code = m_utils.getAccessToken();
		m_passwd = m_utils.getPasswd();
		m_session = new Soup.Session();
		m_session.user_agent = Constants.USER_AGENT;
	}

	public LoginResponse getToken()
	{
		Logger.debug("bazqux Connection: getToken()");

		if(m_username == "" && m_passwd == "")
			return LoginResponse.ALL_EMPTY;
		if(m_username == "")
			return LoginResponse.MISSING_USER;
		if(m_passwd == "")
			return LoginResponse.MISSING_PASSWD;

		var message = new Soup.Message("POST", "https://bazqux.com/accounts/ClientLogin/");
		string message_string = "Email=" + m_username + "&Passwd=" + m_passwd;
		message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, message_string.data);
		m_session.send_message(message);
		string response = (string)message.response_body.flatten().data;
		try{

			var regex = new Regex(".*\\w\\s.*\\w\\sAuth=");
			if(regex.match(response))
			{
				Logger.error("Regex bazqux - %s".printf(response));
				string split = regex.replace( response, -1, 0, "");
				Logger.error("authcode" + split);
				m_utils.setAccessToken(split.strip());
				return LoginResponse.SUCCESS;
			}
			else
			{
				Logger.debug(response);
				return LoginResponse.WRONG_LOGIN;
			}
		}
		catch(Error e)
		{
			Logger.error("bazquxConnection - getToken: Could not load message response");
			Logger.error(e.message);
			return LoginResponse.UNKNOWN_ERROR;
		}
	}

	public Response send_get_request(string path, string ? message_string = null)
	{
		return send_request(path, "GET", message_string);
	}

	public Response send_post_request(string path, string ? message_string = null)
	{
		return send_request(path, "POST", message_string);
	}

	private Response send_request(string path, string type, string ? message_string = null)
	{

		var message = new Soup.Message(type, bazquxSecret.base_uri + path);

		string oldauth = "GoogleLogin auth=" + m_utils.getAccessToken();
		message.request_headers.append("Authorization", oldauth);

		if(message_string != null)
			message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, message_string.data);

		m_session.send_message(message);

		return Response() {
				   status = message.status_code,
				   data = (string)message.response_body.flatten().data
		};
	}

	public bool ping()
	{
		var message = new Soup.Message("GET", "https://www.bazqux.com/reader/ping");

		string oldauth = "GoogleLogin auth=" + m_utils.getAccessToken();
		message.request_headers.append("Authorization", oldauth);
		m_session.send_message(message);

		if((string)message.response_body.data == "OK")
			return true;

		return false;
	}

}

public class FeedReader.bazquxMessage {

	string request = "";

	public bazquxMessage()
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
