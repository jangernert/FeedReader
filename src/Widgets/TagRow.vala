
public class TagRow : baseRow {

	private bool m_exits;
	private string m_catID;
	public string m_name { get; private set; }
	public string m_tagID { get; private set; }
	

	public TagRow (string name, string tagID, string unread_count)
	{
		this.get_style_context().add_class("feed-list-row");
		m_exits = true;
		m_name = name.replace("&","&amp;");
		m_tagID = tagID;
		m_catID = CAT_TAGS;	
			
		var rowhight = 30;
		m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		try{
			Gdk.Pixbuf tmp_icon = drawIcon();
			scale_pixbuf(ref tmp_icon, 24);
			m_icon = new Gtk.Image.from_pixbuf(tmp_icon);
		}catch(GLib.Error e){}

		m_revealer = new Gtk.Revealer();
		m_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
		m_revealer.set_transition_duration(500);
		
		m_unread_count = unread_count;
		m_label = new Gtk.Label(m_name);
		m_label.set_use_markup (true);
		m_label.set_size_request (0, rowhight);
		m_label.set_ellipsize (Pango.EllipsizeMode.END);
		m_label.set_alignment(0, 0.5f);
			
		m_unread = new Gtk.Label(null);
		set_unread_count(unread_count);
		m_unread.set_use_markup (true);
		m_unread.set_size_request (0, rowhight);
		m_unread.set_alignment(0.8f, 0.5f);
		
		m_spacer = new Gtk.Label("");
		m_spacer.set_size_request(24, rowhight);

		m_box.pack_start(m_spacer, false, false, 0);
		m_box.pack_start(m_icon, false, false, 8);
		m_box.pack_start(m_label, true, true, 0);
		m_box.pack_end (m_unread, false, false, 8);
		m_revealer.add(m_box);
		m_revealer.set_reveal_child(false);
		m_isRevealed = false;
		this.add(m_revealer);
		this.show_all();
	}
	
	private Gdk.Pixbuf drawIcon()
	{
		int size = 64;
		Cairo.ImageSurface surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, size, size);
		Cairo.Context context = new Cairo.Context (surface);

		context.set_line_width (0);
		context.arc (size/2, size/2, 28, 0, 2*Math.PI);

		context.set_fill_rule (Cairo.FillRule.EVEN_ODD);
		context.set_source_rgb (0.9, 0.0, 0.0);
		context.fill_preserve ();
	
		context.arc (size/2, size/2, 22, 0, 2*Math.PI);
		context.set_source_rgb (1, 0.0, 0.0);
		context.fill_preserve ();
	
		return Gdk.pixbuf_get_from_surface(surface, 0, 0, size, size);
	}

	public void update(string name, string unread_count)
	{
		m_label.set_text(name.replace("&","&amp;"));
		m_label.set_use_markup (true);
		set_unread_count(unread_count);
	}
	
	public string getID()
	{
		return m_tagID;
	}

	public void setExits(bool subscribed)
	{
		m_exits = subscribed;
	}

	public bool stillExits()
	{
		return m_exits;
	}

}

