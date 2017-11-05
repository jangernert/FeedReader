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
	private GLib.StringBuilder m_message_string;
	private string m_contenttype;
	private Json.Parser m_parser;
	private Json.Object m_root_object;

	public ttrssMessage(Soup.Session session, string destination)
	{
		m_message_string = new GLib.StringBuilder();
		m_session = session;
		m_contenttype = "application/x-www-form-urlencoded";
		m_parser = new Json.Parser();

		m_message_soup = new Soup.Message("POST", destination);

		if(m_message_soup == null)
			Logger.error(@"ttrssMessage: can't send message to $destination");
	}


	public void add_int(string type, int val)
	{
		m_message_string.append(",\"" + type + "\":" + val.to_string());
	}

	public void add_int_array(string type, string values)
	{
		m_message_string.append(",\"" + type + "\":\"" + values + "\"");
	}

	public void add_bool(string type, bool val)
	{
		m_message_string.append(",\"" + type + "\":");
		if(val)
			m_message_string.append("true");
		else
			m_message_string.append("false");
	}

	public void add_string(string type, string val)
	{
		m_message_string.append(",\"" + type + "\":\"" + val.replace("\"", "\\\"").replace("\\", "\\\\") + "\"");
	}

	public ConnectionError send(bool ping = false)
	{
		if(m_message_soup == null)
		{
			Logger.error(@"ttrssMessage: can't send message");
			return ConnectionError.UNKNOWN;
		}

		var settingsTweaks = new GLib.Settings("org.gnome.feedreader.tweaks");
		m_message_string.overwrite(0, "{").append("}");
		m_message_soup.set_request(m_contenttype, Soup.MemoryUse.COPY, m_message_string.str.data);

		if(settingsTweaks.get_boolean("do-not-track"))
				m_message_soup.request_headers.append("DNT", "1");

		var status = m_session.send_message(m_message_soup);

		if(status == 401) // unauthorized
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

		try
		{
			m_parser.load_from_data((string)m_message_soup.response_body.flatten().data);
		}
		catch(Error e)
		{
			Logger.error("Could not load response from Message to ttrss");
			Logger.error(e.message);
			return ConnectionError.NO_RESPONSE;
		}

		m_root_object = m_parser.get_root().get_object();


		if(m_root_object.has_member("error"))
			parseError(m_root_object);


		if(m_root_object.has_member("status"))
		{
			if(m_root_object.get_int_member("status") == 1)
			{
				if(m_root_object.has_member("content"))
				{
					var content = m_root_object.get_object_member("content");
					if(content.has_member("error"))
						parseError(content);
				}

				return ApiError();
			}
			else if(m_root_object.get_int_member("status") == 0)
			{
				return ConnectionError.SUCCESS;
			}
		}

		Logger.error("unknown error while sending ttrss message");
		return ConnectionError.UNKNOWN;
	}

	public Json.Object? get_response_object()
	{
		if(m_root_object.has_member("content"))
		{
			return m_root_object.get_object_member("content");
		}
		return null;
	}

	public int64? get_response_int()
	{
		if(m_root_object.has_member("content"))
		{
			return m_root_object.get_int_member("content");
		}
		return null;
	}

	public string? get_response_string()
	{
		if(m_root_object.has_member("content"))
		{
			return m_root_object.get_string_member("content");
		}
		return null;
	}


	public Json.Array? get_response_array()
	{
		if(m_root_object.has_member("content"))
		{
			return m_root_object.get_array_member("content");
		}
		return null;
	}

	public uint getStatusCode()
	{
		return m_message_soup.status_code;
	}

	public void printMessage()
	{
		Logger.debug(m_message_string.str);
	}

	public void printResponse()
	{
		Logger.debug((string)m_message_soup.response_body.flatten().data);
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

		return ApiError();
	}

	private ConnectionError ApiError()
	{
		Logger.error("ttrss api error");
		printMessage();
		printResponse();
		return ConnectionError.API_ERROR;
	}
}
