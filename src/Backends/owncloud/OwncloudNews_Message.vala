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

public class FeedReader.OwnCloudNews_Message : GLib.Object {

    private Soup.Session m_session;
	private Soup.Message m_message_soup;
	private string m_contenttype;
	private Json.Parser m_parser;
	private Json.Object m_root_object;
    private string m_method;

    public OwnCloudNews_Message(string destination, string username, string password, string method = "POST")
    {
        m_method = method;
		m_session = new Soup.Session();
		m_contenttype = "application/x-www-form-urlencoded";
		m_parser = new Json.Parser();
		m_message_soup = new Soup.Message(m_method, destination);

        string credentials = username + ":" + password;
        string base64 = GLib.Base64.encode(credentials.data);
        m_message_soup.request_headers.append("Authorization","Basic %s".printf(base64));
	}

    public ConnectionError send()
	{
		m_message_soup.set_request(m_contenttype, Soup.MemoryUse.COPY, "".data);
		m_session.send_message(m_message_soup);

		if((string)m_message_soup.response_body.flatten().data == null
		|| (string)m_message_soup.response_body.flatten().data == "")
        {
            logger.print(LogMessage.ERROR, "No response from Message to owncloud");
            return ConnectionError.NO_RESPONSE;
        }

		try{
			m_parser.load_from_data((string)m_message_soup.response_body.flatten().data);
		}
		catch (Error e) {
			logger.print(LogMessage.ERROR, "Could not load response from Message to owncloud");
			logger.print(LogMessage.ERROR, e.message);
			return ConnectionError.NO_RESPONSE;
		}

		m_root_object = m_parser.get_root().get_object();
		return ConnectionError.SUCCESS;
	}

    public Json.Object? get_response_object()
	{
		return m_root_object;
	}

	public void printResponse()
	{
		logger.print(LogMessage.DEBUG, (string)m_message_soup.response_body.flatten().data);
	}
}
