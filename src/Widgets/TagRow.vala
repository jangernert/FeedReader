
public class TagRow : baseRow {

	private bool m_exits;
	private string m_catID;
	private int m_color;
	private ColorCircle m_circle;
	private ColorPopover m_pop;
	public string m_name { get; private set; }
	public string m_tagID { get; private set; }
	

	public TagRow (string name, string tagID, int color)
	{
		this.get_style_context().add_class("feed-list-row");
		m_exits = true;
		m_color = color;
		m_name = name.replace("&","&amp;");
		m_tagID = tagID;
		m_catID = CAT_TAGS;	
			
		var rowhight = 30;
		m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		
		m_circle = new ColorCircle(m_color);
		m_pop = new ColorPopover(m_circle);
		
		m_circle.clicked.connect((color) => {
			m_pop.show_all();
		});
		
		m_pop.newColorSelected.connect((color) => {
			m_circle.newColor(color);
			dataBase.update_tag_color(m_tagID, color);
		});

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
		m_box.pack_start(m_circle, false, false, 8);
		m_box.pack_start(m_label, true, true, 0);
		m_revealer.add(m_box);
		m_revealer.set_reveal_child(false);
		m_isRevealed = false;
		this.add(m_revealer);
		this.show_all();
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

