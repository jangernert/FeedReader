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

public class FeedReader.InoReaderAPI : GLib.Object {

	private InoReaderConnection m_connection;

	private string m_inoreader;
	private string m_userID;

	public InoReaderAPI ()
	{
		m_connection = new InoReaderConnection();
	}


	public LoginResponse login()
	{
		m_connection.getToken();
		if(getUserID())
		{
			logger.print(LogMessage.DEBUG, "inoreader: login success");
			return LoginResponse.SUCCESS;
		}
		return LoginResponse.UNKNOWN_ERROR;
	}
	private bool getUserID()
	{
		string response = m_connection.send_request("user-info");
		var parser = new Json.Parser();
		parser.load_from_data (response, -1);
		var root = parser.get_root().get_object();

		if(root.has_member("userId"))
		{
			m_userID = root.get_string_member("userId");
			logger.print(LogMessage.INFO, "Inoreader: userID = " + m_userID);

			if(root.has_member("userEmail"))
			{
				settings_inoreader.set_string("inoreader-api-username", root.get_string_member("userEmail"));
			}
			return true;
		}

		return false;
	}

	public void getCategories(Gee.LinkedList<category> categories)
	{
		string response = m_connection.send_request("subscription/list");

		var parser = new Json.Parser();
		parser.load_from_data (response, -1);
		var root = parser.get_root().get_object();

	}

}
