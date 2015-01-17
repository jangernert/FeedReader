
public class TagRow : baseRow {

	private bool m_exits;
	private string m_catID;
	private string m_color;
	public string m_name { get; private set; }
	public string m_tagID { get; private set; }
	

	public TagRow (string name, string tagID, string color)
	{
		this.get_style_context().add_class("feed-list-row");
		m_exits = true;
		m_color = color;
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
		
		m_label = new Gtk.Label(m_name);
		m_label.set_use_markup (true);
		m_label.set_size_request (0, rowhight);
		m_label.set_ellipsize (Pango.EllipsizeMode.END);
		m_label.set_alignment(0, 0.5f);
	
		m_spacer = new Gtk.Label("");
		m_spacer.set_size_request(24, rowhight);

		m_box.pack_start(m_spacer, false, false, 0);
		m_box.pack_start(m_icon, false, false, 8);
		m_box.pack_start(m_label, true, true, 0);
		m_revealer.add(m_box);
		m_revealer.set_reveal_child(false);
		m_isRevealed = false;
		this.add(m_revealer);
		this.show_all();
	}
	
	private Gdk.Pixbuf drawIcon()
	{
		int size = 64;
		string[] color = m_color.split (",");
		Cairo.ImageSurface surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, size, size);
		Cairo.Context context = new Cairo.Context (surface);

		context.set_line_width (0);
		context.arc (size/2, size/2, 28, 0, 2*Math.PI);

		context.set_fill_rule (Cairo.FillRule.EVEN_ODD);
		context.set_source_rgb (double.parse(color[0]), double.parse(color[1]), double.parse(color[2]));
		context.fill_preserve ();
	
		context.arc (size/2, size/2, 22, 0, 2*Math.PI);
		context.set_source_rgb (double.parse(color[3]), double.parse(color[4]), double.parse(color[5]));
		context.fill_preserve ();
	
		return Gdk.pixbuf_get_from_surface(surface, 0, 0, size, size);
	}

	public void update(string name)
	{
		m_label.set_text(name.replace("&","&amp;"));
		m_label.set_use_markup (true);
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

