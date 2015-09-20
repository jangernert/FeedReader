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

public class FeedReader.ttrss_message : GLib.Object {

	private Soup.Session m_session;
	private Soup.Message m_message_soup;
	private GLib.StringBuilder m_message_string;
	private string m_contenttype;
	private Json.Parser m_parser;
	private Json.Object m_root_object;



	public ttrss_message(string destination)
	{
		m_message_string = new GLib.StringBuilder();
		m_session = new Soup.Session();
		//m_session.ssl_strict = false;
		m_contenttype = "application/x-www-form-urlencoded";
		m_parser = new Json.Parser();

		m_message_soup = new Soup.Message("POST", destination);
	}


	public void add_int(string type, int val)
	{
		m_message_string.append(",\"" + type + "\":" + val.to_string());
	}

	public void add_int_array(string type, string values)
	{
		m_message_string.append(",\"" + type + "\":" + values);
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
		m_message_string.append(",\"" + type + "\":\"" + val + "\"");
	}

	public ConnectionError send()
	{
		m_message_string.overwrite(0, "{").append("}");
		m_message_soup.set_request(m_contenttype, Soup.MemoryUse.COPY, m_message_string.str.data);
		var status = m_session.send_message(m_message_soup);

		if(Utils.CaErrorOccoured(m_message_soup.tls_errors))
		{
			logger.print(LogMessage.INFO, "TLS errors: " + Utils.printTlsCertificateFlags(m_message_soup.tls_errors));
			return ConnectionError.CA_ERROR;
		}


		if((string)m_message_soup.response_body.flatten().data == null
		|| (string)m_message_soup.response_body.flatten().data == "")
			return ConnectionError.NO_RESPONSE;

		try{
			m_parser.load_from_data((string)m_message_soup.response_body.flatten().data);
		}
		catch (Error e) {
			logger.print(LogMessage.ERROR, "Could not load response from Message to ttrss");
			logger.print(LogMessage.ERROR, e.message);
			return ConnectionError.NO_RESPONSE;
		}

		m_root_object = m_parser.get_root().get_object();


		if(m_root_object.has_member("error"))
		{
			string error = m_root_object.get_string_member("error");
			if(error == "NOT_LOGGED_IN")
			{
				logger.print(LogMessage.ERROR, "invalid ttrss session id");
				return ConnectionError.INVALID_SESSIONID;
			}
			else if(error == "API_DISABLED")
			{
				logger.print(LogMessage.ERROR, "ttrss api is disabled: please enable it first");
				return ConnectionError.TTRSS_API_DISABLED;
			}
		}

		if(m_root_object.has_member("status"))
		{
			if(m_root_object.get_int_member("status") == 1)
			{
				if(m_root_object.has_member("content"))
				{
					var content = m_root_object.get_object_member("content");
					if(content.has_member("error"))
					{
						string error = content.get_string_member("error");
						if(error == "NOT_LOGGED_IN")
						{
							logger.print(LogMessage.ERROR, "invalid ttrss session id");
							return ConnectionError.INVALID_SESSIONID;
						}
						else if(error == "API_DISABLED")
						{
							logger.print(LogMessage.ERROR, "ttrss api is disabled: please enable it first");
							return ConnectionError.TTRSS_API_DISABLED;
						}
					}
				}

				logger.print(LogMessage.ERROR, "ttrss api error");
				printResponse();
				return ConnectionError.TTRSS_API;
			}
			else if(m_root_object.get_int_member("status") == 0)
			{
				return ConnectionError.SUCCESS;
			}
		}

		logger.print(LogMessage.ERROR, "unknown error while sending ttrss message");
		return ConnectionError.UNKNOWN;
	}

	public Json.Object get_response_object()
	{
		if(m_root_object.has_member("content"))
		{
			return m_root_object.get_object_member("content");
		}
		return null;
	}

	public int64 get_response_int()
	{
		if(m_root_object.has_member("content"))
		{
			return m_root_object.get_int_member("content");
		}
		return -99;
	}


	public Json.Array get_response_array()
	{
		if(m_root_object.has_member("content"))
		{
			return m_root_object.get_array_member("content");
		}
		return null;
	}

	public void printMessage()
	{
		logger.print(LogMessage.DEBUG, m_message_string.str);
	}

	public void printResponse()
	{
		logger.print(LogMessage.DEBUG, (string)m_message_soup.response_body.flatten().data);
	}
}
