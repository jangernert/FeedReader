public class FeedReader.FeedRow : baseRow {

	private bool m_subscribed;
	private string m_catID;
	private int m_level;
	private string m_name { get; private set; }
	private string m_feedID { get; private set; }


	public FeedRow (string text, uint unread_count, bool has_icon, string feedID, string catID, int level)
	{
		this.get_style_context().add_class("feed-list-row");
		m_level = level;
		m_catID = catID;
		m_subscribed = true;
		m_name = text.replace("&","&amp;");
		if(text != "")
		{
			m_feedID = feedID;

			var rowhight = 30;
			m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			string icon_path = GLib.Environment.get_home_dir() + "/.local/share/feedreader/data/feed_icons/";

			if(has_icon)
			{
				try{
					Gdk.Pixbuf tmp_icon = new Gdk.Pixbuf.from_file(icon_path + feedID.replace("/", "_").replace(".", "_") + ".ico");
					scale_pixbuf(ref tmp_icon, 24);
					m_icon = new Gtk.Image.from_pixbuf(tmp_icon);
				}catch(GLib.Error e){}
			}
			else
			{
				m_icon = new Gtk.Image.from_file("/usr/share/FeedReader/rss24.svg");
			}

			m_icon.margin_start = level * 24;

			m_unread_count = unread_count;
			m_label = new Gtk.Label(m_name);
			m_label.set_size_request (0, rowhight);
			m_label.set_ellipsize (Pango.EllipsizeMode.END);
			m_label.set_alignment(0, 0.5f);

			m_unread = new Gtk.Label(null);
			set_unread_count(m_unread_count);
			m_unread.set_size_request (0, rowhight);
			m_unread.set_alignment(0.8f, 0.5f);
			m_unread.get_style_context().add_class("unread-count");


			if(m_catID != CategoryID.TTRSS_SPECIAL)
			{
				if(!settings_general.get_boolean("only-feeds"))
				{
					m_box.get_style_context().add_class("feed-row");
				}
			}
			m_box.pack_start(m_icon, false, false, 8);
			m_box.pack_start(m_label, true, true, 0);
			m_box.pack_end (m_unread, false, false, 8);
			m_revealer.add(m_box);
			m_revealer.set_reveal_child(false);
			this.add(m_revealer);
			this.show_all();
		}
	}

	public void update(string text, uint unread_count)
	{
		m_label.set_text(text.replace("&","&amp;"));
		set_unread_count(unread_count);
	}

	public void setSubscribed(bool subscribed)
	{
		m_subscribed = subscribed;
	}

	public string getCategorie()
	{
		return m_catID;
	}

	public string getID()
	{
		return m_feedID;
	}

	public string getName()
	{
		return m_name;
	}

	public bool isSubscribed()
	{
		return m_subscribed;
	}

}
