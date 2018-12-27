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

public class FeedReader.OldReaderConnection {
private string m_api_username;
private string m_api_code;
private string m_passwd;
private OldReaderUtils m_utils;
private Soup.Session m_session;

public OldReaderConnection(OldReaderUtils utils)
{
	m_utils = utils;
	m_api_username = m_utils.getUser();
	m_api_code = m_utils.getAccessToken();
	m_passwd = m_utils.getPasswd();
	m_session = new Soup.Session();
	m_session.user_agent = Constants.USER_AGENT;
}

public LoginResponse getToken()
{
	Logger.debug("OldReader Connection: getToken()");

	var message = new Soup.Message("POST", "https://theoldreader.com/accounts/ClientLogin/");
	string message_string = "Email=" + m_api_username
	                        + "&Passwd=" + m_passwd
	                        + "&service=reader"
	                        + "&accountType=HOSTED_OR_GOOGLE"
	                        + "&client=FeedReader";
	message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, message_string.data);
	m_session.send_message(message);

	if(message.status_code != 200)
		return LoginResponse.NO_CONNECTION;

	string response = (string)message.response_body.flatten().data;
	try
	{
		var regex = new Regex(".*\\w\\s.*\\w\\sAuth=");
		if(regex.match(response))
		{
			Logger.debug(@"Regex oldreader - $response");
			string split = regex.replace( response, -1,0,"");
			Logger.debug(@"authcode: $split");
			m_utils.setAccessToken(split.strip());
			return LoginResponse.SUCCESS;
		}
		else
		{
			Logger.debug(message_string);
			Logger.error(response);
			return LoginResponse.WRONG_LOGIN;
		}
	}
	catch(Error e)
	{
		Logger.error("OldReaderConnection - getToken: Could not load message response");
		Logger.error(e.message);
		return LoginResponse.UNKNOWN_ERROR;
	}
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
	var message = new Soup.Message(type, OldReaderSecret.base_uri + path);

	string oldauth = "GoogleLogin auth=" + m_utils.getAccessToken();
	message.request_headers.append("Authorization", oldauth);

	if(message_string != null)
		message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, message_string.data);

	m_session.send_message(message);

	if(message.status_code != 200)
	{
		Logger.warning("OldReaderConnection: unexpected response %u".printf(message.status_code));
	}

	return Response() {
		       status = message.status_code,
		       data = (string)message.response_body.flatten().data
	};
}

}
