public class FeedReader.FeedRow : Gtk.ListBoxRow {

	private Gtk.Box m_box;
	private Gtk.Label m_label;
	private bool m_subscribed;
	private string m_catID;
	private int m_level;
	private Gtk.Revealer m_revealer;
	private Gtk.Image m_icon;
	private Gtk.Label m_unread;
	private uint m_unread_count;
	private Gtk.EventBox m_unreadBox;
	private bool m_unreadHovered;
	private Gtk.Stack m_unreadStack;
	private string m_name { get; private set; }
	private string m_feedID { get; private set; }
	public signal void setAsRead(FeedListType type, string id);


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
					Utils.scale_pixbuf(ref tmp_icon, 24);
					m_icon = new Gtk.Image.from_pixbuf(tmp_icon);
				}catch(GLib.Error e){}
			}
			else
			{
				m_icon = new Gtk.Image.from_file("/usr/share/FeedReader/icons/rss24.svg");
			}

			m_icon.margin_start = level * 24;

			m_unread_count = unread_count;
			m_label = new Gtk.Label(m_name);
			m_label.set_size_request (0, rowhight);
			m_label.set_ellipsize (Pango.EllipsizeMode.END);
			m_label.set_alignment(0, 0.5f);

			m_unread = new Gtk.Label(null);
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


			if(m_catID != CategoryID.TTRSS_SPECIAL)
			{
				if(!settings_general.get_boolean("only-feeds"))
				{
					m_box.get_style_context().add_class("feed-row");
				}
			}
			m_box.pack_start(m_icon, false, false, 8);
			m_box.pack_start(m_label, true, true, 0);
			m_box.pack_end (m_unreadBox, false, false, 8);

			m_revealer = new Gtk.Revealer();
			m_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
			m_revealer.add(m_box);
			m_revealer.set_reveal_child(false);
			this.add(m_revealer);
			this.show_all();

			set_unread_count(m_unread_count);
		}
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

	private bool onUnreadClick(Gdk.EventButton event)
	{
		if(m_unreadHovered && m_unread_count > 0)
		{
			setAsRead(FeedListType.FEED, m_feedID);
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

	public void upUnread()
	{
		set_unread_count(m_unread_count+1);
	}

	public void downUnread()
	{
		if(m_unread_count > 0)
			set_unread_count(m_unread_count-1);
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

	public string getCatID()
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
