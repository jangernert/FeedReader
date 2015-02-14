public class FeedReader.category : GLib.Object {

	public string m_categorieID { get; private set; }
	public string m_title { get; private set; }
	public int m_unread_count { get; private set; }
	public int m_orderID { get; private set; }
	public string m_parent { get; private set; }
	public int m_level { get; private set; }

	public category (string categorieID, string title, int unread_count, int orderID, string parent, int level) {
		m_categorieID = categorieID;
		m_title = title;
		m_unread_count = unread_count;
		m_orderID = orderID;
		m_parent = parent;
		m_level = level;
	}
}
