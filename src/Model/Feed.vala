public class FeedReader.feed : GLib.Object {

	public string m_feedID { get; private set; }
	public string m_title { get; private set; }
	public string m_url { get; private set; }
	public bool m_hasIcon { get; private set; }
	public uint m_unread { get; private set; }
	public string m_categorieID { get; private set; }

	public feed (string feedID, string title, string url, bool hasIcon, uint unread, string categorieID) {
		m_feedID = feedID;
		m_title = title;
		m_url = url;
		m_unread = unread;
		m_categorieID = categorieID;
		m_hasIcon = hasIcon;
	}
}
