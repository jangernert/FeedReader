public class FeedReader.feed : GLib.Object {

	private string m_feedID;
	private string m_title;
	private string m_url;
	private bool m_hasIcon;
	private uint m_unread;
	private string m_categorieID;

	public feed (string feedID, string title, string url, bool hasIcon, uint unread, string categorieID) {
		m_feedID = feedID;
		m_title = title;
		m_url = url;
		m_unread = unread;
		m_categorieID = categorieID;
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

	public string getCatID()
	{
		return m_categorieID;
	}
}
