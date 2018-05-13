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

public class FeedReader.FeedlyConnection {

	private FeedlyUtils m_utils;
	private GLib.Settings m_settingsTweaks;
	private Soup.Session m_session;

	public FeedlyConnection(FeedlyUtils utils)
	{
		m_utils = utils;
		m_session = new Soup.Session();
		m_session.user_agent = Constants.USER_AGENT;
		m_settingsTweaks = new GLib.Settings("org.gnome.feedreader.tweaks");
	}

	public LoginResponse getToken()
	{
		var message = new Soup.Message("POST", FeedlySecret.base_uri+"/v3/auth/token");
		string message_string = "code=" + m_utils.getApiCode()
								+ "&client_id=" + FeedlySecret.apiClientId
								+ "&client_secret=" + FeedlySecret.apiClientSecret
								+ "&redirect_uri=" + FeedlySecret.apiRedirectUri
								+ "&grant_type=authorization_code"
								+ "&state=getting_token";

		message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, message_string.data);
		m_session.send_message(message);

		if(message.status_code != 200)
			return LoginResponse.NO_CONNECTION;

		try
		{
			var parser = new Json.Parser();
			parser.load_from_data ((string)message.response_body.flatten().data);
			var root = parser.get_root().get_object();

			if(root.has_member("access_token"))
			{
				string accessToken = root.get_string_member("access_token");
				int64 expires = (int)root.get_int_member("expires_in");
				string refreshToken = root.get_string_member("refresh_token");
				int64 now = (new DateTime.now_local()).to_unix();

				Logger.debug("access-token: " + accessToken);
				Logger.debug("expires in: " + expires.to_string());
				Logger.debug("refresh-token: " + refreshToken);
				Logger.debug("now: " + now.to_string());

				m_utils.setAccessToken(accessToken);
				m_utils.setExpiration((int)(now + expires));
				m_utils.setRefreshToken(refreshToken);
				return LoginResponse.SUCCESS;
			}
			else if(root.has_member("errorCode"))
			{
				Logger.error("Feedly: getToken response - " + root.get_string_member("errorMessage"));
				return LoginResponse.UNKNOWN_ERROR;
			}
		}
		catch(Error e)
		{
			Logger.error("Could not load response to Message from feedly - %s".printf(e.message));
		}

		return LoginResponse.UNKNOWN_ERROR;
	}


	public LoginResponse refreshToken()
	{
		var message = new Soup.Message("POST", FeedlySecret.base_uri+"/v3/auth/token");

		if(m_settingsTweaks.get_boolean("do-not-track"))
				message.request_headers.append("DNT", "1");

		string message_string = "refresh_token=" + m_utils.getRefreshToken()
								+ "&client_id=" + FeedlySecret.apiClientId
								+ "&client_secret=" + FeedlySecret.apiClientSecret
								+ "&grant_type=refresh_token";

		message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, message_string.data);
		m_session.send_message(message);

		if(message.status_code != 200)
			return LoginResponse.NO_CONNECTION;

		try
		{
			var parser = new Json.Parser();
			parser.load_from_data ((string)message.response_body.flatten().data);
			var root = parser.get_root().get_object();

			if(root.has_member("access_token"))
			{
				string accessToken = root.get_string_member("access_token");
				int64 expires = (int)root.get_int_member("expires_in");
				string refreshToken = root.get_string_member("refresh_token");
				int64 now = (new DateTime.now_local()).to_unix();

				Logger.debug("access-token: " + accessToken);
				Logger.debug("expires in: " + expires.to_string());
				Logger.debug("refresh-token: " + refreshToken);
				Logger.debug("now: " + now.to_string());

				m_utils.setAccessToken(accessToken);
				m_utils.setExpiration((int)(now + expires));
				m_utils.setRefreshToken(refreshToken);
				return LoginResponse.SUCCESS;
			}
			else if(root.has_member("errorCode"))
			{
				Logger.error("Feedly: refreshToken response - " + root.get_string_member("errorMessage"));
				return LoginResponse.UNKNOWN_ERROR;
			}
		}
		catch(Error e)
		{
			Logger.error("Could not load response to Message from feedly - %s".printf(e.message));
		}

		return LoginResponse.UNKNOWN_ERROR;
	}


	public Response send_get_request_to_feedly(string path)
	{
		return send_request(path, "GET");
	}

	public Response send_put_request_to_feedly(string path, Json.Node root)
	{
		if(!m_utils.accessTokenValid())
			refreshToken();

		var message = new Soup.Message("PUT", FeedlySecret.base_uri+path);

		if(m_settingsTweaks.get_boolean("do-not-track"))
				message.request_headers.append("DNT", "1");

		var gen = new Json.Generator();
		gen.set_root(root);
		message.request_headers.append("Authorization","OAuth %s".printf(m_utils.getAccessToken()));

		size_t length;
		string json;
		json = gen.to_data(out length);
		message.request_body.append_take(json.data);
		m_session.send_message(message);

		if(message.status_code != 200)
		{
			Logger.warning(@"FeedlyConnection: message unexpected response");
		}

		return Response() {
			status = message.status_code,
			data = (string)message.response_body.flatten().data
		};
	}

	public Response send_post_request_to_feedly(string path, Json.Node root)
	{
		if(!m_utils.accessTokenValid())
			refreshToken();

		var message = new Soup.Message("POST", FeedlySecret.base_uri+path);

		if(m_settingsTweaks.get_boolean("do-not-track"))
				message.request_headers.append("DNT", "1");

		var gen = new Json.Generator();
		gen.set_root(root);
		message.request_headers.append("Authorization","OAuth %s".printf(m_utils.getAccessToken()));

		size_t length;
		string json;
		json = gen.to_data(out length);
		Logger.debug(json);
		message.request_body.append_take(json.data);
		m_session.send_message(message);

		if(message.status_code != 200)
		{
			Logger.warning(@"FeedlyConnection: message unexpected response");
			Logger.debug("Status Code: " + message.status_code.to_string());
		}

		return Response() {
			status = message.status_code,
			data = (string)message.response_body.flatten().data
		};
	}

	public Response send_post_string_request_to_feedly(string path, string input, string type)
	{
		if(!m_utils.accessTokenValid())
			refreshToken();

		var message = new Soup.Message("POST", FeedlySecret.base_uri+path);

		if(m_settingsTweaks.get_boolean("do-not-track"))
				message.request_headers.append("DNT", "1");

		message.request_headers.append("Authorization","OAuth %s".printf(m_utils.getAccessToken()));
		message.request_headers.append("Content-Type", type);

		message.request_body.append_take(input.data);
		m_session.send_message(message);

		if(message.status_code != 200)
		{
			Logger.warning(@"FeedlyConnection: message unexpected response - $input");
		}

		return Response() {
			status = message.status_code,
			data = (string)message.response_body.flatten().data
		};
	}

	public Response send_delete_request_to_feedly(string path)
	{
		return send_request(path, "DELETE");
	}

	private Response send_request(string path, string type)
	{
		if(!m_utils.accessTokenValid())
			refreshToken();

		var message = new Soup.Message(type, FeedlySecret.base_uri+path);
		message.request_headers.append("Authorization", @"OAuth $(m_utils.getAccessToken())");

		if(m_settingsTweaks.get_boolean("do-not-track"))
			message.request_headers.append("DNT", "1");

		m_session.send_message(message);

		if(message.status_code != 200)
		{
			Logger.warning(@"FeedlyConnection: message unexpected response");
		}

		return Response() {
			status = message.status_code,
			data = (string)message.response_body.flatten().data
		};
	}
}
