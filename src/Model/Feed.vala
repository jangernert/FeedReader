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

public class FeedReader.feed : GLib.Object {

	private string m_feedID;
	private string m_title;
	private string m_url;
	private bool m_hasIcon;
	private uint m_unread;
	private string[] m_catIDs;

	public feed (string feedID, string title, string url, bool hasIcon, uint unread, string[] catIDs) {
		m_feedID = feedID;
		m_title = title;
		m_url = url;
		m_unread = unread;
		m_catIDs = catIDs;
		m_hasIcon = hasIcon;
	}

	public string getFeedID()
	{
		return m_feedID;
	}

	public string getTitle()
	{
		return m_title;
	}

	public string getURL()
	{
		return m_url;
	}

	public bool hasIcon()
	{
		return m_hasIcon;
	}

	public uint getUnread()
	{
		return m_unread;
	}

	public string[] getCatIDs()
	{
		return m_catIDs;
	}

	public string getCatString()
	{
		string catIDs = "";
		foreach(string id in m_catIDs)
		{
			catIDs += id + ",";
		}

		return catIDs;
	}

	public bool hasCat(string catID)
	{
		foreach(string cat in m_catIDs)
		{
			if(cat == catID)
				return true;
		}

		return false;
	}

	public bool isUncategorized()
	{
		if(m_catIDs.length == 0)
			return true;

		if(m_catIDs.length == 1 && m_catIDs[0].contains("global.must"))
			return true;

		return false;
	}

	public void print()
	{
		logger.print(LogMessage.DEBUG, "\ntitle: %s\nid: %s\nurl: %s\nunread: %u".printf(m_title, m_feedID, m_url, m_unread));
	}
}
