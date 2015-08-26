public class FeedReader.ShareRow : Gtk.ListBoxRow {

	private string m_name;
    private Gtk.Label m_label;
    private Gtk.Box m_box;
    private OAuth m_type;

	public ShareRow(string serviceName, OAuth type)
	{
		m_name = serviceName;
        m_type = type;

        m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);
        m_box.margin = 3;
        string iconName = "";

        switch (m_type)
        {
            case OAuth.READABILITY:
                iconName = "feed-share-readability";
                break;

            case OAuth.INSTAPAPER:
                iconName = "feed-share-instapaper";
                break;

            case OAuth.POCKET:
                iconName = "feed-share-pocket";
                break;

			case OAuth.EVERNOTE:
	            iconName = "feed-share-evernote";
	            break;
        }
        var icon = new Gtk.Image.from_icon_name(iconName, Gtk.IconSize.DND);

        m_label = new Gtk.Label(serviceName);
        m_label.set_line_wrap_mode(Pango.WrapMode.WORD);
        m_label.set_ellipsize(Pango.EllipsizeMode.END);
        m_label.set_alignment(0.5f, 0.5f);

        m_box.pack_start(icon, false, false, 8);
        m_box.pack_start(m_label, true, true, 0);

		this.add(m_box);
		this.show_all();
	}

    public OAuth getType()
    {
        return m_type;
    }

}
