public class tag : GLib.Object {

	public string m_tagID { get; private set; }
	public string m_title { get; private set; }
	public int m_unread { get; private set; }
	public string m_color { get; private set; }
	
	public tag (string tagID, string title, string color) {
		m_tagID = tagID;
		m_title = title;
		m_color = color;
	}
}
