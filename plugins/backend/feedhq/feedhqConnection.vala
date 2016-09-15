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
		var message = new Soup.Message("POST", "https://feedhq.org/accounts/ClientLogin/");
		string message_string = "Email=" + m_api_username + "&Passwd=" + m_passwd + "&service=reader&accountType=HOSTED_OR_GOOGLE&client=FeedReader";
		message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, message_string.data);
		session.send_message(message);
		string response = (string)message.response_body.flatten().data;
		try{

			var regex = new Regex(".*\\w\\s.*\\w\\sAuth=");
			if(regex.match(response))
			{
				logger.print(LogMessage.ERROR, "Regex FeedHQ - %s".printf(response));
				string split = regex.replace( response, -1,0,"");
				logger.print(LogMessage.ERROR, "authcode"+split);
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

		if(message_string != null)
			message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, message_string.data);


		session.send_message(message);
		logger.print(LogMessage.ERROR, FeedHQSecret.base_uri+path);
		logger.print(LogMessage.ERROR, message_string);
		logger.print(LogMessage.ERROR, (string)message.response_body.data);
		return (string)message.response_body.data;
	}

}
