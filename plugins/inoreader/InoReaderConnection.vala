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

public class FeedReader.InoReaderConnection {
	private string m_api_username;
	private string m_api_code;
	private InoReaderUtils m_utils;

	public InoReaderConnection()
	{
		m_utils = new InoReaderUtils();
		m_api_username = m_utils.getUser();
		m_api_code = m_utils.getAccessToken();
	}

	public LoginResponse getToken()
	{
		logger.print(LogMessage.DEBUG, "InoReaderConnection: getToken()");

		var session = new Soup.Session();
		var message = new Soup.Message("POST", "https://www.inoreader.com/oauth2/token");
		string message_string = "code=" + m_utils.getApiCode()
								+ "&redirect_uri=" + InoReaderSecret.apiRedirectUri
								+ "&client_id=" + InoReaderSecret.apiClientId
								+ "&client_secret=" + InoReaderSecret.apiClientSecret
								+ "&scope="
								+ "&grant_type=authorization_code";
		message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, message_string.data);
		session.send_message(message);
		string response = (string)message.response_body.flatten().data;

		try
		{
			var parser = new Json.Parser();
			parser.load_from_data(response, -1);
			var root = parser.get_root().get_object();

			string accessToken = root.get_string_member("access_token");
			int64 expires = (int)root.get_int_member("expires_in");
			string refreshToken = root.get_string_member("refresh_token");
			int64 now = (new DateTime.now_local()).to_unix();

			logger.print(LogMessage.DEBUG, "access-token: " + accessToken);
			logger.print(LogMessage.DEBUG, "expires in: " + expires.to_string());
			logger.print(LogMessage.DEBUG, "refresh-token: " + refreshToken);
			logger.print(LogMessage.DEBUG, "now: " + now.to_string());

			m_utils.setAccessToken(accessToken);
			m_utils.setExpiration((int)(now + expires));
			m_utils.setRefreshToken(refreshToken);
		}
		catch(Error e)
		{
			logger.print(LogMessage.ERROR, "InoReaderConnection - getToken: Could not load message response");
			logger.print(LogMessage.ERROR, e.message);
			return LoginResponse.UNKNOWN_ERROR;
		}

		return LoginResponse.SUCCESS;
	}

	public LoginResponse refreshToken()
	{
		logger.print(LogMessage.DEBUG, "InoReaderConnection: refreshToken()");

		var session = new Soup.Session();
		var message = new Soup.Message("POST", "https://www.inoreader.com/oauth2/token");
		string message_string = "client_id=" + InoReaderSecret.apiClientId
								+ "&client_secret=" + InoReaderSecret.apiClientSecret
								+ "&grant_type=refresh_token"
								+ "&refresh_token=" + m_utils.getRefreshToken();

		message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, message_string.data);
		session.send_message(message);
		string response = (string)message.response_body.flatten().data;

		try
		{
			var parser = new Json.Parser();
			parser.load_from_data(response, -1);
			var root = parser.get_root().get_object();

			string accessToken = root.get_string_member("access_token");
			int64 expires = (int)root.get_int_member("expires_in");
			string refreshToken = root.get_string_member("refresh_token");
			int64 now = (new DateTime.now_local()).to_unix();

			logger.print(LogMessage.DEBUG, "access-token: " + accessToken);
			logger.print(LogMessage.DEBUG, "expires in: " + expires.to_string());
			logger.print(LogMessage.DEBUG, "refresh-token: " + refreshToken);
			logger.print(LogMessage.DEBUG, "now: " + now.to_string());

			m_utils.setAccessToken(accessToken);
			m_utils.setExpiration((int)(now + expires));
			m_utils.setRefreshToken(refreshToken);
		}
		catch(Error e)
		{
			logger.print(LogMessage.ERROR, "InoReaderConnection - getToken: Could not load message response");
			logger.print(LogMessage.ERROR, e.message);
			return LoginResponse.UNKNOWN_ERROR;
		}

		return LoginResponse.SUCCESS;
	}

	public string send_request(string path, string? message_string = null)
	{
		return send_post_request(path, "POST", message_string);
	}

	private string send_post_request(string path, string type, string? message_string = null)
	{
		if(!m_utils.accessTokenValid())
			refreshToken();

		var session = new Soup.Session();
		var message = new Soup.Message(type, InoReaderSecret.base_uri + path);

		string inoauth = "Bearer " + m_utils.getAccessToken();
		message.request_headers.append("Authorization", inoauth) ;

		if(message_string != null)
			message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, message_string.data);

		session.send_message(message);
		return (string)message.response_body.data;
	}

}
