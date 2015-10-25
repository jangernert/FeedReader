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

public class FeedReader.category : GLib.Object {

	private string m_categorieID;
	private string m_title;
	private uint m_unread_count;
	private int m_orderID;
	private string m_parent;
	private int m_level;

	public category (string categorieID, string title, uint unread_count, int orderID, string parent, int level) {
		m_categorieID = categorieID;
		m_title = title;
		m_unread_count = unread_count;
		m_orderID = orderID;
		m_parent = parent;
		m_level = level;
	}

	public string getCatID()
	{
		return m_categorieID;
	}

	public string getTitle()
	{
		return m_title;
	}

	public uint getUnreadCount()
	{
		return m_unread_count;
	}

	public int getOrderID()
	{
		return m_orderID;
	}

	public string getParent()
	{
		return m_parent;
	}

	public int getLevel()
	{
		return m_level;
	}

	public void print()
	{
		logger.print(LogMessage.DEBUG, "\ntitle: %s\nid: %s\nunread: %u".printf(m_title, m_categorieID, m_unread_count));
	}
}
