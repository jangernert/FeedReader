public class FeedReader.categorieRow : baseRow {

	private string m_name;
	private Gtk.EventBox m_eventbox;
	private string m_categorieID;
	private string m_parentID;
	private int m_orderID;
	private int m_level;
	private bool m_exists;
	private Gtk.Image m_icon_expanded;
	private Gtk.Image m_icon_expanded_hover;
	private Gtk.Image m_icon_collapsed;
	private Gtk.Image m_icon_collapsed_hover;
	private Gtk.Stack m_stack;
	private bool m_collapsed;
	private bool m_hovered;
	public signal void collapse(bool collapse, string catID);

	public categorieRow (string name, string categorieID, int orderID, uint unread_count, string parentID, int level, bool expanded) {
	
		this.get_style_context().add_class("feed-list-row");
		this.get_style_context().remove_class("button");
		m_level = level;
		m_parentID = parentID;
		m_orderID = orderID;
		m_collapsed = !expanded;
		m_name = name;
		m_exists = true;
		m_categorieID = categorieID;
		m_unread_count = unread_count;
		m_hovered = false;
		var rowhight = 30;
		m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		m_eventbox = new Gtk.EventBox();
		m_eventbox.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		m_eventbox.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
		m_eventbox.set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
		
		m_stack = new Gtk.Stack();
		m_stack.set_transition_type(Gtk.StackTransitionType.NONE);
		m_stack.set_transition_duration(0);

		m_icon_expanded = new Gtk.Image.from_file("/usr/share/FeedReader/arrow-down.svg");
		m_icon_expanded_hover = new Gtk.Image.from_file("/usr/share/FeedReader/arrow-down-hover.svg");
		m_icon_collapsed = new Gtk.Image.from_file("/usr/share/FeedReader/arrow-left.svg");
		m_icon_collapsed_hover = new Gtk.Image.from_file("/usr/share/FeedReader/arrow-left-hover.svg");
		
		m_stack.add_named(m_icon_expanded, "expanded");
		m_stack.add_named(m_icon_expanded_hover, "expanded_hover");
		m_stack.add_named(m_icon_collapsed, "collapsed");
		m_stack.add_named(m_icon_collapsed_hover, "collapsed_hover");
		
		m_eventbox.add(m_stack);

		m_label = new Gtk.Label(m_name);
		m_label.set_use_markup (true);
		m_label.set_size_request (0, rowhight);
		m_label.set_ellipsize (Pango.EllipsizeMode.END);
		m_label.set_alignment(0, 0.5f);
		
		int count = 0;

		m_eventbox.button_press_event.connect(() => {
			expand_collapse();
			return true;
		});
		
		m_eventbox.enter_notify_event.connect(onEnter);
		m_eventbox.leave_notify_event.connect(onLeave);

		m_revealer = new Gtk.Revealer();
		m_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
		m_revealer.set_transition_duration(500);

		m_spacer = new Gtk.Label("");
		m_spacer.set_size_request((level-1) * 24, rowhight);


		m_unread = new Gtk.Label("");
		m_unread.set_size_request (0, rowhight);
		m_unread.set_alignment(0.8f, 0.5f);
		set_unread_count(m_unread_count);
		
		m_box.pack_start(m_spacer, false, false, 0);
		m_box.pack_start(m_eventbox, false, false, 8);
		m_box.pack_start(m_label, true, true, 0);
		m_box.pack_end(m_unread, false, false, 8);
		m_revealer.add(m_box);
		m_revealer.set_reveal_child(false);
		this.add(m_revealer);
		this.show_all();
		
		if(m_collapsed)
			m_stack.set_visible_child_name("collapsed");
		else
			m_stack.set_visible_child_name("expanded");
	}

	public void expand_collapse()
	{
		if(m_collapsed)
		{
			m_collapsed = false;
			if(m_hovered)
			{
				m_stack.set_visible_child_name("expanded_hover");
			}
			else
			{
				m_stack.set_visible_child_name("expanded");
			}
		}
		else
		{
			m_collapsed = true;
			if(m_hovered)
			{
				m_stack.set_visible_child_name("collapsed_hover");
			}
			else
			{
				m_stack.set_visible_child_name("collapsed");
			}
		}
		
		collapse(m_collapsed, m_categorieID);
	}
	
	private bool onEnter()
	{
		print("enter\n");
		m_hovered = true;
		if(m_collapsed)
		{
			m_stack.set_visible_child_name("collapsed_hover");
		}
		else
		{
			m_stack.set_visible_child_name("expanded_hover");
		}
		this.show_all();
		return true;
	}
	
	private bool onLeave()
	{
		print("leave\n");
		m_hovered = false;
		if(m_collapsed)
		{
			m_stack.set_visible_child_name("collapsed");
		}
		else
		{
			m_stack.set_visible_child_name("expanded");
		}
		this.show_all();
		return true;
	}

	public string getID()
	{
		return m_categorieID;
	}
	
	public string getName()
	{
		return m_name;
	}

	public string getParent()
	{
		return m_parentID;
	}
	
	public int getOrder()
	{
		return m_orderID;
	}

	public int getLevel()
	{
		return m_level;
	}

	public void setExist(bool exists)
	{
		m_exists = exists;
	}

	public bool doesExist()
	{
		return m_exists;
	}

	public bool isExpanded()
	{
		return !m_collapsed;
	}

}

