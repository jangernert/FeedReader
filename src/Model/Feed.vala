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

public class FeedReader.Feed : GLib.Object {

	private string m_feedID;
	private string m_title;
	private string m_url;
	private string? m_xmlURL;
	private uint m_unread;
	private Gee.List<string> m_catIDs;
	private string? m_iconURL;

	public Feed(string feedID, string title, string url, uint unread, Gee.List<string>? catIDs = null, string? iconURL = null, string? xmlURL = null)
	{
		m_feedID = feedID;
		m_title = Utils.UTF8fix(title);
		m_url = url;
		m_unread = unread;
		m_catIDs = catIDs == null ? Gee.List.empty<string>() : catIDs;
		m_iconURL = iconURL == "" ? null : iconURL;
		m_xmlURL = xmlURL;
	}

	public string getFeedID()
	{
		return m_feedID;
	}

	public string getTitle()
	{
		return m_title;
	}

	public void setTitle(string title)
	{
		m_title = title;
	}

	public string getURL()
	{
		return m_url;
	}

	public void setURL(string url)
	{
		m_url = url;
	}

	public uint getUnread()
	{
		return m_unread;
	}

	public Gee.List<string> getCatIDs()
	{
		return m_catIDs;
	}

	public string getCatString()
	{
		return StringUtils.join(m_catIDs, ",");
	}

	public bool hasCat(string catID)
	{
		return m_catIDs.contains(catID);
	}

	public void addCat(string catID)
	{
		m_catIDs.add(catID);
	}

	public void setCats(Gee.List<string> catIDs)
	{
		m_catIDs = catIDs;
	}

	public bool isUncategorized()
	{
		if(m_catIDs.size == 0)
			return true;

		if(m_catIDs.size == 1 && m_catIDs[0].contains("global.must"))
			return true;

		return false;
	}

	public string? getIconURL()
	{
		return m_iconURL;
	}

	public void setIconURL(string? url)
	{
		m_iconURL = url;
	}

	public string? getXmlUrl()
	{
		return m_xmlURL;
	}

	public void print()
	{
		Logger.debug("\ntitle: %s\nid: %s\nurl: %s\nunread: %u".printf(m_title, m_feedID, m_url, m_unread));
	}
}
