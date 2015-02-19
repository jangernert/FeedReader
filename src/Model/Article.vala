public class FeedReader.article : GLib.Object {

	public string m_articleID { get; private set; }
	public string m_title { get; private set; }
	public string m_url { get; private set; }
	public string m_html { get; private set; }
	public string m_preview { get; private set; }
	public string m_feedID { get; private set; }
	public string m_tags { get; private set; }
	public string m_author { get; private set; }
	public int m_unread { get; private set; }
	public int m_marked { get; private set; }
	private int m_sortID { get; private set; }
	

	
	public article (string articleID, string title, string url, string feedID, int unread, int marked, string html, string preview, string author, int sortID, string tags) {
		m_articleID = articleID;
		m_title = title;
		m_url = url;
		m_html = html;
		m_preview = preview;
		m_feedID = feedID;
		m_author = author;
		m_unread = unread;
		m_marked = marked;
		m_sortID = sortID;
		m_tags = tags;
	}
	
	public string getAuthor()
	{
		return m_author;
	}
	
	public int getSortID()
	{
		return m_sortID;
	}
	
	public void setAuthor(string author)
	{
		m_author = author;
	}
}
