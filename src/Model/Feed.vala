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

	public bool isUncategorized()
	{
		if(m_catIDs.length == 0)
			return true;

		if(m_catIDs.length == 1 && m_catIDs[0].contains("global.must"))
			return true;

		return false;
	}
}
