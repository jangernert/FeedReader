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

public class FeedReader.ShareAccount : GLib.Object {

	private string m_id;
	private OAuth m_type;
	private string m_accountName;
	private string m_username;
	private string m_iconName;

	public ShareAccount(string id, OAuth type, string username, string iconName, string accountName)
	{
		m_id = id;
		m_type = type;
		m_username = username;
		m_iconName = iconName;
		m_accountName = accountName;
	}

	public string getID()
	{
		return m_id;
	}

	public OAuth getType()
	{
		return m_type;
	}

	public string getUsername()
	{
		return m_username;
	}

	public string getIconName()
	{
		return m_iconName;
	}

	public string getAccountName()
	{
		return m_accountName;
	}
}
