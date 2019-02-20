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

public class FeedReader.ttrssMessage : GLib.Object {
	
	private Soup.Session m_session;
	private Soup.Message m_message_soup;
	private Json.Object m_request_object = new Json.Object();
	private const string m_contenttype = "application/x-www-form-urlencoded";
	private Json.Object m_response_object;
	
	public ttrssMessage(Soup.Session session, string destination)
	{
		m_session = session;
		
		m_message_soup = new Soup.Message("POST", destination);
		
		if(m_message_soup == null)
		{
			Logger.error(@"ttrssMessage: can't parse URL $destination");
		}
	}
	
	public void add_int(string type, int val)
	{
		m_request_object.set_int_member(type, val);
	}
	
	public void add_comma_separated_int_array(string type, Gee.List<int> values)
	{
		var strings = new Gee.ArrayList<string>();
		foreach(int value in values)
		{
			strings.add(value.to_string());
		}
		m_request_object.set_string_member(type, StringUtils.join(strings, ","));
	}
	
	public void add_bool(string type, bool val)
	{
		m_request_object.set_boolean_member(type, val);
	}
	
	public void add_string(string type, string val)
	{
		m_request_object.set_string_member(type, val);
	}
	
	private static string object_to_string(Json.Object obj)
	{
		var root = new Json.Node(Json.NodeType.OBJECT);
		root.set_object(obj);
		
		var gen = new Json.Generator();
		gen.set_root(root);
		return gen.to_data(null);
	}
	
	public ConnectionError send(bool ping = false)
	{
		var error = send_impl(ping);
		if(error != ConnectionError.SUCCESS)
		{
			logError("Error response from TT-RSS API");
		}
		
		return error;
	}
	
	public ConnectionError send_impl(bool ping)
	{
		if(m_message_soup == null)
		{
			Logger.error(@"ttrssMessage: can't send message");
			return ConnectionError.UNKNOWN;
		}
		
		var settingsTweaks = new GLib.Settings("org.gnome.feedreader.tweaks");
		
		var data = object_to_string(m_request_object);
		m_message_soup.set_request(m_contenttype, Soup.MemoryUse.COPY, data.data);
		
		if(settingsTweaks.get_boolean("do-not-track"))
		{
			m_message_soup.request_headers.append("DNT", "1");
		}
		
		var status_code = m_session.send_message(m_message_soup);
		
		if(status_code == 401)         // unauthorized
		
		{
			return ConnectionError.UNAUTHORIZED;
		}
		
		if(m_message_soup.tls_errors != 0 && !settingsTweaks.get_boolean("ignore-tls-errors"))
		{
			Logger.info("TLS errors: " + Utils.printTlsCertificateFlags(m_message_soup.tls_errors));
			return ConnectionError.CA_ERROR;
		}
		
		if(m_message_soup.status_code != 200)
		{
			Logger.error("TTRSS Message: No response - status code: %s".printf(Soup.Status.get_phrase(m_message_soup.status_code)));
			return ConnectionError.NO_RESPONSE;
		}
		
		if(ping)
		{
			Logger.debug("TTRSS Message: ping successful");
			return ConnectionError.SUCCESS;
		}
		
		var parser = new Json.Parser();
		try
		{
			parser.load_from_data((string)m_message_soup.response_body.flatten().data);
		}
		catch(Error e)
		{
			Logger.error("Could not load response from Message to ttrss");
			Logger.error(e.message);
			return ConnectionError.NO_RESPONSE;
		}
		
		m_response_object = parser.get_root().get_object();
		
		if(m_response_object.has_member("error"))
		{
			parseError(m_response_object);
		}
		
		
		var status = UntypedJson.Object.get_int_member(m_response_object, "status");
		if (status == 0)
		{
			return ConnectionError.SUCCESS;
		}
		else if (status == 1)
		{
			if(m_response_object.has_member("content"))
			{
				var content = m_response_object.get_object_member("content");
				if(content.has_member("error"))
				{
					parseError(content);
				}
			}
			
			return apiError();
		}
		
		logError("unknown error while sending ttrss message");
		return ConnectionError.UNKNOWN;
	}
	
	public Json.Object? get_response_object()
	{
		if(m_response_object.has_member("content"))
		{
			return m_response_object.get_object_member("content");
		}
		return null;
	}
	
	public int64? get_response_int()
	{
		return UntypedJson.Object.get_int_member(m_response_object, "content");
	}
	
	public string? get_response_string()
	{
		return UntypedJson.Object.get_string_member(m_response_object, "content");
	}
	
	public Json.Array? get_response_array()
	{
		if(m_response_object.has_member("content"))
		{
			return m_response_object.get_array_member("content");
		}
		return null;
	}
	
	public uint getStatusCode()
	{
		return m_message_soup.status_code;
	}
	
	private void logError(string prefix)
	{
		var url = m_message_soup.get_uri().to_string(false);
		var obj = m_request_object;
		if(obj.has_member("password"))
		{
			obj = new Json.Object();
			m_request_object.foreach_member((_, name, member) =>
				{
					if(name == "password")
					{
						obj.set_string_member("password", "[redacted]");
					}
					else
					{
						obj.set_member(name, member);
					}
				});
			}
			var request = object_to_string(obj);
			var response = (string)m_message_soup.response_body.flatten().data;
			Logger.error(@"$prefix\nURL: $url\nRequest object: $request\nResponse: $response");
		}
		
		private ConnectionError parseError(Json.Object err)
		{
			string error = err.get_string_member("error");
			if(error == "NOT_LOGGED_IN")
			{
				Logger.error("invalid ttrss session id");
				return ConnectionError.INVALID_SESSIONID;
			}
			else if(error == "API_DISABLED")
			{
				Logger.error("ttrss api is disabled: please enable it first");
				return ConnectionError.API_DISABLED;
			}
			
			return apiError();
		}
		
		private ConnectionError apiError()
		{
			logError("TT-RSS API error");
			return ConnectionError.API_ERROR;
		}
	}
