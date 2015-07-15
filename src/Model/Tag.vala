public class FeedReader.tag : GLib.Object {

	private string m_tagID;
	private string m_title;
	private int m_color;

	public tag (string tagID, string title, int color) {
		m_tagID = tagID;
		m_title = title;
		m_color = color;
	}

	public string getTagID()
	{
		return m_tagID;
	}

	public string getTitle()
	{
		return m_title;
	}

	public int getColor()
	{
		return m_color;
	}
}
