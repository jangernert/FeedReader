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
	private string m_api_username;
	private string m_api_code;
	private string m_passwd;
	private FeedHQUtils m_utils;

	public FeedHQConnection()
	{
		m_utils = new FeedHQUtils();
		m_api_username = m_utils.getUser();
		m_api_code = m_utils.getAccessToken();
		m_passwd = m_utils.getPasswd();
	}

	public LoginResponse getToken()
	{
		logger.print(LogMessage.DEBUG, "FeedHQ Connection: getToken()");

		var session = new Soup.Session();
		var message = new Soup.Message("POST", "https://feedhq.org/accounts/ClientLogin");
		string message_string = "Email=" + m_api_username + "&Passwd=" + m_passwd;
		message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, message_string.data);
		session.send_message(message);
		string response = (string)message.response_body.flatten().data;
		try{

			var regex = new Regex(".*\\w\\s.*\\w\\sAuth=");
			if(regex.match(response))
			{
				string split = regex.replace( response, -1,0,"");
				logger.print(LogMessage.ERROR, "FeedHQ Authcode : "+split);
				m_utils.setAccessToken(split.strip());
				return LoginResponse.SUCCESS;
			}
			else
			{
				logger.print(LogMessage.DEBUG, response);
				return LoginResponse.WRONG_LOGIN;
			}
		}
		catch(Error e)
		{
			logger.print(LogMessage.ERROR, "FeedHQConnection - getToken: Could not load message response");
			logger.print(LogMessage.ERROR, e.message);
			return LoginResponse.UNKNOWN_ERROR;
		}

		return LoginResponse.SUCCESS;
	}


	public bool postToken()
	{
		logger.print(LogMessage.DEBUG, "FeedHQ Connection: postToken()");

		var session = new Soup.Session();
		var message = new Soup.Message("GET", FeedHQSecret.base_uri + "token?output=json");

		string oldauth = "GoogleLogin auth=" + m_utils.getAccessToken();
		message.request_headers.append("Authorization", oldauth);
		session.send_message(message);

		string response =  (string)message.response_body.data;
		
		logger.print( LogMessage.DEBUG, "FeedHQ post token : " +  response );
		m_utils.setPostToken(response);
		
		return true;

	}
	public string send_get_request(string path, string? message_string = null)
	{
		return send_request(path, "GET", message_string);
	}

	public string send_post_request(string path, string? message_string = null)
	{
		return send_request(path, "POST", message_string);
	}



	private string send_request(string path, string type, string? message_string = null)
	{

		var session = new Soup.Session();
		var message = new Soup.Message(type, FeedHQSecret.base_uri + path);

		string oldauth = "GoogleLogin auth=" + m_utils.getAccessToken();
		message.request_headers.append("Authorization", oldauth);
		var message_string_post = message_string + "&T=" + m_utils.getPostToken();
		if(message_string != null)
			message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, message_string_post.data);
		
		session.send_message(message);
		if((uint)message.status_code == 401){
			logger.print(LogMessage.DEBUG, "FeedHQ Post Token Expired");
			postToken();
		}
		
		return (string)message.response_body.data;
	}

}
