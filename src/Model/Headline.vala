public class headline : GLib.Object {

	public string m_articleID { get; private set; }
	public string m_title { get; private set; }
	public string m_url { get; private set; }
	public string m_feedID { get; private set; }
	public int m_unread { get; private set; }
	public int m_marked { get; private set; }
	

	
	public headline (string articleID, string title, string url, string feedID, int unread, int marked) {
		m_articleID = articleID;
		m_title = title;
		m_url = url;
		m_feedID = feedID;
		m_unread = unread;
		m_marked = marked;
	}
}
