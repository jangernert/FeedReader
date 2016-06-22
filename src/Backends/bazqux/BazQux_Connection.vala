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

public class FeedReader.BazQuxConnection {
	private string m_api_code;
	private string m_api_username;

	public BazQuxConnection()
	{
		m_api_username = bazqux_utils.getUser();
		m_api_code = bazqux_utils.getAccessToken();
	}

	public int getToken()
	{
		var session = new Soup.Session();
		var message = new Soup.Message("POST", "https://bazqux.com/accounts/ClientLogin");
		string passwd = bazqux_utils.getPasswd();

		string message_string = "Email=" + m_api_username + "&Passwd=" + passwd;
		message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, message_string.data);
		session.send_message(message);

		try{
			var regex = new Regex(".*\\w\\s.*\\w\\sAuth=");
			string response = (string)message.response_body.flatten().data;
			logger.print(LogMessage.ERROR, "Could not load response to Message from feedhq - %s".printf(response));
			if(regex.match(response))
			{
				string split = regex.replace( response, -1,0,"");
				settings_bazqux.set_string("access-token",split.strip());
				m_api_code = bazqux_utils.getAccessToken();
				return LoginResponse.SUCCESS;
			}
			else
			{
				logger.print(LogMessage.DEBUG, response);
				return LoginResponse.WRONG_LOGIN;
			}
		}
		catch (Error e){
			logger.print(LogMessage.ERROR, "Could not load response to Message from feedhq - %s".printf(e.message));
		}

		return LoginResponse.UNKNOWN_ERROR;
	}

	public string send_get_request(string path)
	{
		var session = new Soup.Session();
		var message = new Soup.Message("GET", BazQuxSecret.base_uri+path);
		string oldauth = "GoogleLogin auth=" + bazqux_utils.getAccessToken();
		message.request_headers.append("Authorization", oldauth) ;
		session.send_message(message);
		return (string)message.response_body.data;
	}

	public string send_post_request(string path, string? message_string = null)
	{
		var session = new Soup.Session();
		var message = new Soup.Message("POST", BazQuxSecret.base_uri+path);
		string oldauth = "GoogleLogin auth=" + bazqux_utils.getAccessToken();
		message.request_headers.append("Authorization", oldauth) ;
		if(message_string != null)
			message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, message_string.data);
		session.send_message(message);
		return (string)message.response_body.data;
	}
}
