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

public class FeedReader.TheOldReaderConnection {
	private string m_api_code;
	private string m_api_username;

	public TheOldReaderConnection()
	{
		m_api_username = theoldreader_utils.getUser();
		m_api_code = theoldreader_utils.getAccessToken();
	}

	public int getToken()
	{
		var session = new Soup.Session();
		var message = new Soup.Message("POST", "https://theoldreader.com/accounts/ClientLogin/");
		var pwSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
							                      "Username", Secret.SchemaAttributeType.STRING);
		var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
		attributes["Username"] = m_api_username;

		string passwd = "";
		try{
			passwd = Secret.password_lookupv_sync(pwSchema, attributes, null);
		}
		catch(GLib.Error e){
			logger.print(LogMessage.ERROR, e.message);
		}

		string message_string = "Email=" + m_api_username + "&Passwd=" + passwd + "&service=reader&accountType=HOSTED_OR_GOOGLE&client=FeedReader";
		message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, message_string.data);
		session.send_message(message);

		try{
			var regex = new Regex(".*\\w\\s.*\\w\\sAuth=");
			string response = (string)message.response_body.flatten().data;
			logger.print(LogMessage.ERROR, "Could not load response to Message from oldreader - %s".printf(response));
			if(regex.match(response))
			{
				string split = regex.replace( response, -1,0,"");
				settings_theoldreader.set_string("access-token",split.strip());
				m_api_code = theoldreader_utils.getAccessToken();
				return LoginResponse.SUCCESS;
			}
			else
			{
				logger.print(LogMessage.DEBUG, response);
				return LoginResponse.WRONG_LOGIN;
			}
		}
		catch (Error e){
			logger.print(LogMessage.ERROR, "Could not load response to Message from oldreader - %s".printf(e.message));
		}

		return LoginResponse.UNKNOWN_ERROR;
	}

	public string send_get_request(string path)
	{
		var session = new Soup.Session();
		var message = new Soup.Message("GET", TheOldReaderSecret.base_uri+path);
		logger.print(LogMessage.DEBUG, "Get theoldreader" + TheOldReaderSecret.base_uri+path);
		string oldauth = "GoogleLogin auth=" + theoldreader_utils.getAccessToken();
		message.request_headers.append("Authorization", oldauth) ;
		session.send_message(message);
		return (string)message.response_body.data;
	}

	public string send_post_request(string path, string? message_string = null)
	{
		var session = new Soup.Session();
		logger.print(LogMessage.DEBUG, "post request " + path + " : " + message_string);
		var message = new Soup.Message("POST", TheOldReaderSecret.base_uri+path);
		string oldauth = "GoogleLogin auth=" + theoldreader_utils.getAccessToken();
		message.request_headers.append("Authorization", oldauth) ;
		if(message_string != null)
			message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, message_string.data);
		session.send_message(message);
		logger.print(LogMessage.DEBUG, "post reposne" + (string)message.response_body.data);
		return (string)message.response_body.data;
	}

}
