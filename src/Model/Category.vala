public class FeedReader.category : GLib.Object {

	private string m_categorieID;
	private string m_title;
	private int m_unread_count;
	private int m_orderID;
	private string m_parent;
	private int m_level;

	public category (string categorieID, string title, int unread_count, int orderID, string parent, int level) {
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

	public int getUnreadCount()
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
}
