public class FeedReader.article : GLib.Object {

	private string m_articleID;
	public string m_title { get; private set; }
	public string m_url { get; private set; }
	private string m_html;
	private string m_preview;
	public string m_feedID { get; private set; }
	public string m_tags { get; private set; }
	private string m_author;
	public int m_unread { get; private set; }
	public int m_marked { get; private set; }
	private int m_sortID;
	private int m_date;



	public article (string articleID, string title, string url, string feedID, int unread, int marked, string html, string preview, string author, int date, int sortID, string tags) {
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
		m_date = date;
	}

	public string getArticleID()
	{
		return m_articleID;
	}

	public string getHTML()
	{
		return m_html;
	}

	public void setHTML(string html)
	{
		m_html = html;
	}

	public string getPreview()
	{
		return m_preview;
	}

	public void setPreview(string preview)
	{
		m_preview = preview;
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

	public int getDate()
	{
		return m_date;
	}
}
