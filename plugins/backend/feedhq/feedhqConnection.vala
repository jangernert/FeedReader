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

public class FeedReader.FeedHQConnection {
	private string m_username;
	private string m_api_code;
	private string m_passwd;
	private FeedHQUtils m_utils;
	private Soup.Session m_session;

	public FeedHQConnection(FeedHQUtils utils)
	{
		m_utils = utils;
		m_username = m_utils.getUser();
		m_api_code = m_utils.getAccessToken();
		m_passwd = m_utils.getPasswd();
		m_session = new Soup.Session();
		m_session.user_agent = Constants.USER_AGENT;
	}

	public LoginResponse getToken()
	{
		Logger.debug("FeedHQ Connection: getToken()");

		if(m_username == "" && m_passwd == "")
		{
			return LoginResponse.ALL_EMPTY;
		}
		if(m_username == "")
		{
			return LoginResponse.MISSING_USER;
		}
		if(m_passwd == "")
		{
			return LoginResponse.MISSING_PASSWD;
		}

		var message = new Soup.Message("POST", "https://feedhq.org/accounts/ClientLogin");
		string message_string = "Email=" + m_username + "&Passwd=" + m_passwd;
		message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, message_string.data);
		m_session.send_message(message);
		string response = (string)message.response_body.flatten().data;
		try{

			var regex = new Regex(".*\\w\\s.*\\w\\sAuth=");
			if(regex.match(response))
			{
				string split = regex.replace(response, -1,0,"");
				Logger.debug("FeedHQ Authcode : " + split);
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
			Logger.error("FeedHQConnection - getToken: Could not load message response");
			Logger.error(e.message);
			return LoginResponse.UNKNOWN_ERROR;
		}
	}


	public bool postToken()
	{
		Logger.debug("FeedHQ Connection: postToken()");

		var message = new Soup.Message("GET", FeedHQSecret.base_uri + "token?output=json");

		string oldauth = "GoogleLogin auth=" + m_utils.getAccessToken();
		message.request_headers.append("Authorization", oldauth);
		m_session.send_message(message);

		if(message.status_code != 200)
		{
			Logger.debug("FeedHQ post token failed");
			return false;
		}

		string response = (string)message.response_body.data;
		Logger.debug("FeedHQ post token : " + response);
		m_utils.setPostToken(response);

		return true;

	}
	public Response send_get_request(string path, string? message_string = null)
	{
		return send_request(path, "GET", message_string);
	}

	public Response send_post_request(string path, string? message_string = null)
	{
		return send_request(path, "POST", message_string);
	}



	private Response send_request(string path, string type, string? message_string = null)
	{
		var message = new Soup.Message(type, FeedHQSecret.base_uri + path);

		string oldauth = "GoogleLogin auth=" + m_utils.getAccessToken();
		message.request_headers.append("Authorization", oldauth);
		var message_string_post = message_string + "&T=" + m_utils.getPostToken();
		if(message_string != null)
		{
			message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, message_string_post.data);
		}

		m_session.send_message(message);

		if(message.status_code != 200)
		{
			Logger.warning(@"feedHQConnection: message unexpected response - $message_string");
		}

		if((uint)message.status_code == 401)
		{
			Logger.debug("FeedHQ Post Token Expired");
			postToken();
			return send_request(path, type, message_string);
		}

		return Response() {
			status = message.status_code,
			data = (string)message.response_body.flatten().data
		};
	}

}


public class FeedReader.feedhqMessage {

	string request = "";

	public feedhqMessage()
	{

	}

	public void add(string parameter, string val)
	{
		if(request != "")
		{
			request += "&";
		}

		request += parameter;
		request += "=";
		request += GLib.Uri.escape_string(val);
	}

	public string get()
	{
		return request;
	}
}
