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
	private string m_api_code;
	private string m_api_username;

	public FeedHQConnection()
	{
		m_api_username = feedhq_utils.getUser();
		m_api_code = feedhq_utils.getAccessToken();
	}

	public int getToken()
	{
		var session = new Soup.Session();
		var message = new Soup.Message("POST", "https://feedhq.org/accounts/ClientLogin");

		string passwd = feedhq_utils.getPasswd();
		string message_string = "Email=" + m_api_username + "&Passwd=" + passwd;

		message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, message_string.data);
		session.send_message(message);

		try{
			var regex = new Regex(".*\\w\\s.*\\w\\sAuth=");
			string response = (string)message.response_body.flatten().data;
			/*logger.print(LogMessage.ERROR, "Could not load response to Message from feedhq - %s".printf(response));*/
			if(regex.match(response))
			{
				string split = regex.replace( response, -1,0,"");
				settings_feedhq.set_string("access-token",split.strip());
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
		var message = new Soup.Message("GET", FeedHQSecret.base_uri+path);
		string oldauth = "GoogleLogin auth=" + feedhq_utils.getAccessToken();
		message.request_headers.append("Authorization", oldauth) ;
		session.send_message(message);
		logger.print(LogMessage.DEBUG, FeedHQSecret.base_uri+path);
		return (string)message.response_body.data;
	}

	public string send_post_request(string path, string? message_string = null)
	{
		var session = new Soup.Session();
		var message = new Soup.Message("POST", FeedHQSecret.base_uri+path);
		string oldauth = "GoogleLogin auth=" + feedhq_utils.getAccessToken();
		message.request_headers.append("Authorization", oldauth) ;
		string message_data = message_string;
		if(message_string != null){
			message_data += "&T=";
			message_data += feedhq_utils.getTempPostToken() ;
			message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, message_data.data);
		}
		session.send_message(message);
		logger.print(LogMessage.DEBUG, FeedHQSecret.base_uri+path);
		logger.print(LogMessage.DEBUG, message_data);
		logger.print(LogMessage.DEBUG, oldauth);
		logger.print(LogMessage.DEBUG, (string)message.response_body.data);
		if((string)message.response_body.data == "Invalid POST token" ){
			getTempPostToken();
			session.send_message(message);
		}
		return (string)message.response_body.data;
	}
	private void getTempPostToken()
	{
		var response = send_get_request("token");
		string temptoken = (string)response;
		settings_feedhq.set_string("access-post-token", temptoken);
	}
}
