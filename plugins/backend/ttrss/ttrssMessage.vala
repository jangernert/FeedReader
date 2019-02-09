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
		Logger.error(@"ttrssMessage: can't parse URL $destination");
}

public void add_int(string type, int val)
{
	m_request_object.set_int_member(type, val);
}

public void add_int_array(string type, Gee.List<int> values)
{
	var array = new Json.Array.sized(values.size);
	foreach(var value in values)
	{
		array.add_int_element(value);
	}
	m_request_object.set_array_member(type, array);
}

public void add_bool(string type, bool val)
{
	m_request_object.set_boolean_member(type, val);
}

public void add_string(string type, string val)
{
	m_request_object.set_string_member(type, val);
}

private string request_object_to_string()
{
	var root = new Json.Node(Json.NodeType.OBJECT);
	root.set_object(m_request_object);

	var gen = new Json.Generator();
	gen.set_root(root);
	return gen.to_data(null);
}

public ConnectionError send(bool ping = false)
{
	var error = send_impl(ping);
	if(error != ConnectionError.SUCCESS)
	{
		printMessage();
		printResponse();
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

	var data = request_object_to_string();
	m_message_soup.set_request(m_contenttype, Soup.MemoryUse.COPY, data.data);

	if(settingsTweaks.get_boolean("do-not-track"))
		m_message_soup.request_headers.append("DNT", "1");

	var status = m_session.send_message(m_message_soup);

	if(status == 401)         // unauthorized
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
		parseError(m_response_object);


	if(m_response_object.has_member("status"))
	{
		if(m_response_object.get_int_member("status") == 1)
		{
			if(m_response_object.has_member("content"))
			{
				var content = m_response_object.get_object_member("content");
				if(content.has_member("error"))
					parseError(content);
			}

			return ApiError();
		}
		else if(m_response_object.get_int_member("status") == 0)
		{
			return ConnectionError.SUCCESS;
		}
	}

	Logger.error("unknown error while sending ttrss message");
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
	if(m_response_object.has_member("content"))
	{
		return m_response_object.get_int_member("content");
	}
	return null;
}

public string? get_response_string()
{
	if(m_response_object.has_member("content"))
	{
		return m_response_object.get_string_member("content");
	}
	return null;
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

public void printMessage()
{
	var msg = request_object_to_string();
	if (!msg.contains("password"))
		Logger.debug(msg);
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
