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
	private GLib.DateTime m_date;



	public article (string articleID, string title, string url, string feedID, int unread, int marked, string html, string preview, string author, string date, int sortID, string tags) {
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


		string year = date.substring(0, date.index_of_nth_char(4));
		string month = date.substring(date.index_of_nth_char(5), date.index_of_nth_char(7) - date.index_of_nth_char(5));
		string day = date.substring(date.index_of_nth_char(8), date.index_of_nth_char(10) - date.index_of_nth_char(8));
		string hour = date.substring(date.index_of_nth_char(11), date.index_of_nth_char(13) - date.index_of_nth_char(11));
		string min = date.substring(date.index_of_nth_char(14), date.index_of_nth_char(16) - date.index_of_nth_char(14));
		string sec = date.substring(date.index_of_nth_char(17), date.index_of_nth_char(19) - date.index_of_nth_char(17));



		m_date = new GLib.DateTime(new TimeZone.local(), int.parse(year), int.parse(month), int.parse(day), int.parse(hour), int.parse(min), int.parse(sec));
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

	public GLib.DateTime getDate()
	{
		return m_date;
	}

	public string getDateStr()
	{
		return m_date.format("%Y-%m-%d %H:%M:%S");
	}
}
