public class ttrss_message : GLib.Object {

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
		m_contenttype = "application/x-www-form-urlencoded";
		m_parser = new Json.Parser ();
		
		m_message_soup = new Soup.Message ("POST", destination);
	}


	public void add_int(string type, int val)
	{
		m_message_string.append(",\"" + type + "\":" + val.to_string());
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
	
	public int send()
	{
		m_message_string.overwrite(0, "{").append("}");
		m_message_soup.set_request(m_contenttype, Soup.MemoryUse.COPY, m_message_string.str.data);
		m_session.send_message(m_message_soup);
		
		try{
			m_parser.load_from_data((string)m_message_soup.response_body.flatten().data);
		}
		catch (Error e) {
			error("Could not load response to Message to ttrss\n");
			error(e.message);
			return ERR_NO_RESPONSE;
		}
		
		m_root_object = m_parser.get_root().get_object();
		
		if(m_root_object.has_member("error"))
		{
			if(m_root_object.get_string_member("error") == "NOT_LOGGED_IN")
			{
				error("invalid ttrss session id\n");
				return ERR_INVALID_SESSIONID;
			}
		}
		
		if(m_root_object.has_member("status"))
		{
			if(m_root_object.get_int_member("status") == 1)
			{
				error("ttrss api error\n");
				return ERR_TTRSS_API;
			}
			else if(m_root_object.get_int_member("status") == 0)
			{
				return NO_ERROR;
			}
		}
		
		error("unknown error while sending ttrss message\n");
		return ERR_UNKNOWN;
	}
	
	public Json.Object get_response_object()
	{
		if(m_root_object.has_member("content"))
		{
			return m_root_object.get_object_member("content");
		}
		return null;
	}
	
	public Json.Array get_response_array()
	{
		if(m_root_object.has_member("content"))
		{
			return m_root_object.get_array_member("content");
		}
		return null;
	}
}
