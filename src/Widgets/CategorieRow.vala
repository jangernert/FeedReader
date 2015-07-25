public class FeedReader.categorieRow : Gtk.ListBoxRow {

	private Gtk.Box m_box;
	private string m_name;
	private Gtk.Label m_label;
	private Gtk.EventBox m_eventbox;
	private Gtk.EventBox m_unreadBox;
	private Gtk.Revealer m_revealer;
	private Gtk.Label m_unread;
	private uint m_unread_count;
	private string m_categorieID;
	private string m_parentID;
	private int m_orderID;
	private int m_level;
	private bool m_exists;
	private Gtk.Image m_icon;
	private Gtk.Image m_icon_expanded;
	private Gtk.Image m_icon_expanded_hover;
	private Gtk.Image m_icon_collapsed;
	private Gtk.Image m_icon_collapsed_hover;
	private Gtk.Stack m_stack;
	private bool m_collapsed;
	private bool m_hovered;
	private bool m_unreadHovered;
	private Gtk.Stack m_unreadStack;
	public signal void collapse(bool collapse, string catID);
	public signal void setAsRead(FeedListType type, string id);

	public categorieRow (string name, string categorieID, int orderID, uint unread_count, string parentID, int level, bool expanded) {

		this.get_style_context().add_class("feed-list-row");
		m_level = level;
		m_parentID = parentID;
		m_orderID = orderID;
		m_collapsed = !expanded;
		m_name = name;
		m_exists = true;
		m_categorieID = categorieID;
		m_unread_count = unread_count;
		m_hovered = false;
		m_unreadHovered = false;
		var rowhight = 30;
		m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);


		m_icon_expanded = new Gtk.Image.from_file("/usr/share/FeedReader/arrow-down.svg");
		m_icon_expanded_hover = new Gtk.Image.from_file("/usr/share/FeedReader/arrow-down-hover.svg");
		m_icon_collapsed = new Gtk.Image.from_file("/usr/share/FeedReader/arrow-left.svg");
		m_icon_collapsed_hover = new Gtk.Image.from_file("/usr/share/FeedReader/arrow-left-hover.svg");

		m_stack = new Gtk.Stack();
		m_stack.set_transition_type(Gtk.StackTransitionType.NONE);
		m_stack.set_transition_duration(0);
		m_stack.add_named(m_icon_expanded, "expanded");
		m_stack.add_named(m_icon_expanded_hover, "expanded_hover");
		m_stack.add_named(m_icon_collapsed, "collapsed");
		m_stack.add_named(m_icon_collapsed_hover, "collapsed_hover");

		m_eventbox = new Gtk.EventBox();
		m_eventbox.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		m_eventbox.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
		m_eventbox.set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
		m_eventbox.margin_start = (level-1) * 24;
		m_eventbox.add(m_stack);
		m_eventbox.button_press_event.connect(onClick);
		m_eventbox.enter_notify_event.connect(onEnter);
		m_eventbox.leave_notify_event.connect(onLeave);

		m_label = new Gtk.Label(m_name);
		m_label.set_size_request (0, rowhight);
		m_label.set_ellipsize (Pango.EllipsizeMode.END);
		m_label.set_alignment(0, 0.5f);


		m_unread = new Gtk.Label("");
		m_unread.set_size_request (0, rowhight);
		m_unread.set_alignment(0.8f, 0.5f);
		m_unread.get_style_context().add_class("unread-count");

		m_unreadStack = new Gtk.Stack();
		m_unreadStack.set_transition_type(Gtk.StackTransitionType.NONE);
		m_unreadStack.set_transition_duration(0);
		m_unreadStack.add_named(m_unread, "unreadCount");
		m_unreadStack.add_named(new Gtk.Label(""), "nothing");
		m_unreadStack.add_named(new Gtk.Image.from_icon_name("selection-remove", Gtk.IconSize.LARGE_TOOLBAR), "mark");

		m_unreadBox = new Gtk.EventBox();
		m_unreadBox.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		m_unreadBox.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
		m_unreadBox.set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
		m_unreadBox.add(m_unreadStack);
		m_unreadBox.button_press_event.connect(onUnreadClick);
		m_unreadBox.enter_notify_event.connect(onUnreadEnter);
		m_unreadBox.leave_notify_event.connect(onUnreadLeave);

		m_box.pack_start(m_eventbox, false, false, 8);
		m_box.pack_start(m_label, true, true, 0);
		m_box.pack_end(m_unreadBox, false, false, 8);
		m_revealer = new Gtk.Revealer();
		m_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
		m_revealer.add(m_box);
		m_revealer.set_reveal_child(false);
		this.add(m_revealer);
		this.show_all();

		set_unread_count(m_unread_count);

		if(m_collapsed)
			m_stack.set_visible_child_name("collapsed");
		else
			m_stack.set_visible_child_name("expanded");
	}

	private bool onUnreadClick(Gdk.EventButton event)
	{
		if(m_unreadHovered && m_unread_count > 0)
		{
			setAsRead(FeedListType.CATEGORY, m_categorieID);
		}
		return true;
	}

	private bool onUnreadEnter(Gdk.EventCrossing event)
	{
		m_unreadHovered = true;
		if(m_unread_count > 0)
		{
			m_unreadStack.set_visible_child_name("mark");
		}
		return true;
	}

	private bool onUnreadLeave(Gdk.EventCrossing event)
	{
		m_unreadHovered = false;
		if(m_unread_count > 0)
		{
			m_unreadStack.set_visible_child_name("unreadCount");
		}
		else
		{
			m_unreadStack.set_visible_child_name("nothing");
		}
		return true;
	}

	private bool onClick(Gdk.EventButton event)
	{
		switch(event.type)
		{
			case Gdk.EventType.BUTTON_RELEASE:
			case Gdk.EventType.@2BUTTON_PRESS:
			case Gdk.EventType.@3BUTTON_PRESS:
				return false;
		}
		expand_collapse();
		return true;
	}

	public bool expand_collapse()
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
		return true;
	}

	private bool onEnter(Gdk.EventCrossing event)
	{
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

	private bool onLeave(Gdk.EventCrossing event)
	{
		if(event.detail != Gdk.NotifyType.VIRTUAL && event.mode != Gdk.CrossingMode.NORMAL)
			return false;

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

	public void set_unread_count(uint unread_count)
	{
		m_unread_count = unread_count;

		if(m_unread_count > 0 && !m_unreadHovered)
		{
			m_unreadStack.set_visible_child_name("unreadCount");
			m_unread.set_text(m_unread_count.to_string());
		}
		else if(!m_unreadHovered)
		{
			m_unreadStack.set_visible_child_name("nothing");
		}
		else
		{
			m_unreadStack.set_visible_child_name("mark");
		}
	}

	public void upUnread()
	{
		set_unread_count(m_unread_count+1);
	}

	public void downUnread()
	{
		if(m_unread_count > 0)
			set_unread_count(m_unread_count-1);
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

	public uint getUnreadCount()
	{
		return m_unread_count;
	}

	public bool isRevealed()
	{
		return m_revealer.get_reveal_child();
	}

	public void reveal(bool reveal, uint duration = 500)
	{
		if(settings_state.get_boolean("no-animations"))
		{
			m_revealer.set_transition_type(Gtk.RevealerTransitionType.NONE);
			m_revealer.set_transition_duration(0);
			m_revealer.set_reveal_child(reveal);
			m_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
			m_revealer.set_transition_duration(500);
		}
		else
		{
			m_revealer.set_transition_duration(duration);
			m_revealer.set_reveal_child(reveal);
		}
	}

}
