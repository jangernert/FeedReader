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

public class FeedReader.OwnCloudNewsMessage : GLib.Object {

	private Soup.Session m_session;
	private Soup.Message m_message_soup;
	private GLib.StringBuilder m_message_string;
	private string m_contenttype;
	private Json.Parser m_parser;
	private Json.Object m_root_object;
	private string m_method;
	private string m_destination;
	private OwncloudNewsUtils m_utils;

	public OwnCloudNewsMessage(Soup.Session session, string destination, string username, string password, string method)
	{
		m_utils = new OwncloudNewsUtils();
		m_message_string = new GLib.StringBuilder();
		m_method = method;
		m_session = session;
		m_destination = destination;

		if(method == "GET")
			m_contenttype = "application/x-www-form-urlencoded";
		else
			m_contenttype = "application/json";

		m_parser = new Json.Parser();
		m_message_soup = new Soup.Message(m_method, m_destination);

		string credentials = username + ":" + password;
		string base64 = GLib.Base64.encode(credentials.data);
		m_message_soup.request_headers.append("Authorization","Basic %s".printf(base64));
	}

	public void add_int(string type, int val)
	{
		if(m_method == "GET")
		{
			if(m_message_string.len > 0)
				m_message_string.append("&");

			m_message_string.append(type + "=" + val.to_string());
		}
		else
			m_message_string.append(",\"" + type + "\":" + val.to_string());
	}

	public void add_int_array(string type, string values)
	{
		if(m_method == "GET")
			Logger.warning("OwnCloudNewsMessage.add_int_array: this should not happen");
		else
			m_message_string.append(",\"" + type + "\":[" + values + "]");
	}

	public void add_bool(string type, bool val)
	{
		if(m_method == "GET")
		{
			if(m_message_string.len > 0)
				m_message_string.append("&");

			m_message_string.append(type + "=" + (val ? "true" : "false"));
		}
		else
			m_message_string.append(",\"" + type + "\":" + (val ? "true" : "false"));
	}

	public void add_string(string type, string val)
	{
		if(m_method == "GET")
		{
			if(m_message_string.len > 0)
				m_message_string.append("&");

			m_message_string.append(type + "=" + val);
		}
		else
			m_message_string.append(",\"" + type + "\":\"" + val + "\"");
	}

	public ConnectionError send(bool ping = false)
	{
		var settingsTweaks = new GLib.Settings("org.gnome.feedreader.tweaks");

		if(m_method == "GET")
		{
			string destination = m_destination;
			if(m_message_string.len > 0)
				destination += "?" + m_message_string.str;
			m_message_soup.set_uri(new Soup.URI(destination));
			Logger.debug(destination);
		}
		else
		{
			m_message_string.overwrite(0, "{").append("}");
			m_message_soup.set_request(m_contenttype, Soup.MemoryUse.COPY, m_message_string.str.data);
		}

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
			Logger.error("ownCloud Message: No response - status code: %u %s".printf(m_message_soup.status_code, Soup.Status.get_phrase(m_message_soup.status_code)));
			return ConnectionError.NO_RESPONSE;
		}

		if(ping)
		{
			Logger.debug("ownCloud Message: ping successfull");
			return ConnectionError.SUCCESS;
		}

		try
		{
			m_parser.load_from_data((string)m_message_soup.response_body.flatten().data);
		}
		catch(Error e)
		{
			Logger.error("Could not load response from Message to owncloud");
			printMessage();
			Logger.error(e.message);
			return ConnectionError.UNKNOWN;
		}

		m_root_object = m_parser.get_root().get_object();
		return ConnectionError.SUCCESS;
	}

	public uint getStatusCode()
	{
		return m_message_soup.status_code;
	}

	public Json.Object? get_response_object()
	{
		return m_root_object;
	}

	public string getMessage()
	{
		return m_message_string.str;
	}

	public void printMessage()
	{
		Logger.debug(m_message_string.str);
	}

	public void printResponse()
	{
		Logger.debug((string)m_message_soup.response_body.flatten().data);
	}
}
