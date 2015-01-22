/**
 * Representation of a connection to Feedly
 */
public class FeedlyConnection {
	private string m_access_token;
	private string m_refresh_token;
	private string m_apiCode;

	public FeedlyConnection () {
		m_access_token = settings_feedly.get_string("feedly-access-token");
	}
    
	public int getToken()
	{
		var parser = new Json.Parser();
		var session = new Soup.Session();
		var message = new Soup.Message("POST", base_uri+"/v3/auth/token");
		
		m_apiCode = settings_feedly.get_string("feedly-api-code");
		
		string message_string = "code=" + m_apiCode + "&client_id=" + apiClientId + "&client_secret=" + apiClientSecret + "&redirect_uri=" + apiRedirectUri + "&grant_type=authorization_code&state=getting_token";
		
		message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, message_string.data);
		session.send_message(message);
		
		try{
			parser.load_from_data ((string)message.response_body.flatten().data);
		}
		catch (Error e) {
			error("Could not load response to Message to ttrss\n" + e.message + "\n");
		}
		
		var root = parser.get_root().get_object();
		
		if(root.has_member("access_token"))
		{
			m_access_token = root.get_string_member("access_token");
			m_refresh_token = root.get_string_member("refresh_token");
			settings_feedly.set_string("feedly-access-token", m_access_token);
			settings_feedly.set_string("feedly-refresh-token", m_refresh_token);
			return LOGIN_SUCCESS;
		}
		else if(root.has_member("errorCode"))
		{
			print(root.get_string_member("errorMessage") + "\n");
			refreshToken();
			return LOGIN_UNKNOWN_ERROR;
		}
		return LOGIN_UNKNOWN_ERROR;
	}
	
	
	public int refreshToken()
	{
		var parser = new Json.Parser();
		var session = new Soup.Session();
		var message = new Soup.Message("POST", base_uri+"/v3/auth/token");
		
		m_refresh_token = settings_feedly.get_string("feedly-refresh-token");
		string message_string = "refresh_token=" + m_refresh_token + "&client_id=" + apiClientId + "&client_secret=" + apiClientSecret + "&grant_type=refresh_token";
		
		message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.COPY, message_string.data);
		session.send_message(message);
		
		try{
			parser.load_from_data ((string)message.response_body.flatten().data);
		}
		catch (Error e) {
			error("Could not load response to Message to ttrss\n" + e.message + "\n");
		}
		var root = parser.get_root().get_object();
		
		if(root.has_member("access_token"))
		{
			m_access_token = root.get_string_member("access_token");
			m_refresh_token = root.get_string_member("refresh_token");
			settings_feedly.set_string("feedly-access-token", m_access_token);
			settings_feedly.set_string("feedly-refresh-token", m_refresh_token);
			return LOGIN_SUCCESS;
		}
		else if(root.has_member("errorCode"))
		{
			print(root.get_string_member("errorMessage") + "\n");
			return LOGIN_UNKNOWN_ERROR;
		}
		return LOGIN_UNKNOWN_ERROR;
	}
	

	public string send_get_request_to_feedly(string path) {
		return send_request(path, "GET");
	}

	public string send_post_request_to_feedly(string path, Json.Node root) {
		var session = new Soup.Session();
		var message = new Soup.Message("POST", base_uri+path);
		
		var gen = new Json.Generator();
		gen.set_root(root);
		message.request_headers.append("Authorization","OAuth %s".printf(m_access_token));
		
		size_t length;
		string json;
		json = gen.to_data(out length);
		message.request_body.append(Soup.MemoryUse.COPY, json.data);
		session.send_message(message);
		return (string)message.response_body.flatten().data;
	}
    
	public string send_post_string_request_to_feedly(string path, string input, string type){
		var session = new Soup.Session();
		var message = new Soup.Message("POST", base_uri+path);
        
		message.request_headers.append("Authorization","OAuth %s".printf(m_access_token));
		message.request_headers.append("Content-Type", type);

		message.request_body.append(Soup.MemoryUse.COPY, input.data);
		session.send_message(message);
		
		return (string)message.response_body.flatten().data;
    }

	public string send_delete_request_to_feedly (string path) {
		return send_request (path, "DELETE");
	}

	private string send_request(string path, string type) {
		var session = new Soup.Session();
		var message = new Soup.Message(type, base_uri+path);
		message.request_headers.append("Authorization","OAuth %s".printf(m_access_token));
		session.send_message(message);
		return (string)message.response_body.data;
	}
}
