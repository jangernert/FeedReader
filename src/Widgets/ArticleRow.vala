public class FeedReader.articleRow : Gtk.ListBoxRow {

	private Gtk.Box m_box;
	private Gtk.Label m_label;
	private ArticleStatus m_is_unread;
	private ArticleStatus m_marked;
	private Gtk.Revealer m_revealer;
	private string m_url;
	private string m_name;
	private GLib.DateTime m_date;
	private Gtk.Image m_icon;
	private Gtk.EventBox m_unread_eventbox;
	private Gtk.EventBox m_marked_eventbox;
	private Gtk.Stack m_unread_stack;
	private Gtk.Stack m_marked_stack;
	private bool m_just_clicked;
	private bool m_updated;
	private bool m_hovering_unread;
	private bool m_hovering_marked;
	private string m_articleID { get; private set; }
	public string m_feedID { get; private set; }
	public int m_sortID { get; private set; }

	public articleRow(string aritcleName, ArticleStatus unread, string iconname, string url, string feedID, string articleID, ArticleStatus marked, int sortID, string preview, GLib.DateTime date)
	{
		m_hovering_unread = false;
		m_hovering_marked = false;
		m_updated = false;
		m_sortID = sortID;
		m_marked = marked;
		m_name = aritcleName;
		m_articleID = articleID;
		m_feedID = feedID;
		m_url = url;
		m_is_unread = unread;
		m_date = date;

		m_unread_stack = new Gtk.Stack();
		m_marked_stack = new Gtk.Stack();

		m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		m_box.set_size_request(0, 100);

		int spacing = 8;
		string icon_path = GLib.Environment.get_home_dir() + "/.local/share/feedreader/data/feed_icons/";

		string feed_icon_name = icon_path + iconname.replace("/", "_").replace(".", "_") + ".ico";
		Gdk.Pixbuf tmp_icon;
		try{
			if(FileUtils.test(feed_icon_name, GLib.FileTest.EXISTS))
			{
				tmp_icon = new Gdk.Pixbuf.from_file(feed_icon_name);
			}
			else
			{
				tmp_icon = new Gdk.Pixbuf.from_file("/usr/share/FeedReader/rss24.png");
			}
			Utils.scale_pixbuf(ref tmp_icon, 24);
			m_icon = new Gtk.Image.from_pixbuf(tmp_icon);
			spacing = 0;
		}catch(GLib.Error e){}


		this.enter_notify_event.connect(() => {
			stdout.printf("%s\n", m_name);
			return false;
		});


		m_label = new Gtk.Label(aritcleName);
		m_label.set_line_wrap_mode(Pango.WrapMode.WORD);
		m_label.set_line_wrap(true);
		m_label.set_lines(2);
		if(m_is_unread == ArticleStatus.UNREAD)
			m_label.get_style_context().add_class("headline-unread-label");
		else
			m_label.get_style_context().add_class("headline-read-label");
		m_label.set_ellipsize (Pango.EllipsizeMode.END);
		m_label.set_alignment(0, 0.5f);

		m_just_clicked = false;

		var icon_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		icon_box.set_size_request(24, 0);

		var marked_icon = new Gtk.Image.from_icon_name("starred", Gtk.IconSize.SMALL_TOOLBAR);
		var unread_icon = new Gtk.Image.from_icon_name("mail-unread", Gtk.IconSize.SMALL_TOOLBAR);
		var unmarked_icon = new Gtk.Image.from_icon_name("non-starred", Gtk.IconSize.SMALL_TOOLBAR);
		var read_icon = new Gtk.Image.from_icon_name("user-offline", Gtk.IconSize.SMALL_TOOLBAR);

		m_unread_stack.add_named(unread_icon, "unread");
		m_unread_stack.add_named(read_icon, "read");
		m_marked_stack.add_named(marked_icon, "marked");
		m_marked_stack.add_named(unmarked_icon, "unmarked");

		m_unread_eventbox = new Gtk.EventBox();
		m_unread_eventbox.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		m_unread_eventbox.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
		m_unread_eventbox.set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
		m_unread_eventbox.set_size_request(16, 16);
		m_unread_eventbox.add(m_unread_stack);
		m_unread_eventbox.show_all();
		if(m_is_unread == ArticleStatus.UNREAD)
			m_unread_stack.set_visible_child_name("unread");
		else if(m_is_unread == ArticleStatus.READ)
			m_unread_stack.set_visible_child_name("read");

		m_unread_eventbox.enter_notify_event.connect(() => {unreadIconEnter(); return true;});
		m_unread_eventbox.leave_notify_event.connect(() => {unreadIconLeave(); return true;});
		m_unread_eventbox.button_press_event.connect(() => {unreadIconClicked(); return true;});


		m_marked_eventbox = new Gtk.EventBox();
		m_marked_eventbox.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		m_marked_eventbox.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
		m_marked_eventbox.set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
		m_marked_eventbox.set_size_request(16, 16);
		m_marked_eventbox.add(m_marked_stack);
		m_marked_eventbox.show_all();
		if(m_marked == ArticleStatus.MARKED)
			m_marked_stack.set_visible_child_name("marked");
		else if(m_marked == ArticleStatus.UNMARKED)
			m_marked_stack.set_visible_child_name("unmarked");

		m_marked_eventbox.enter_notify_event.connect(markedIconEnter);
		m_marked_eventbox.leave_notify_event.connect(markedIconLeave);
		m_marked_eventbox.button_press_event.connect(markedIconClicked);



		icon_box.pack_start(m_icon, true, true, 0);
		icon_box.pack_end(m_unread_eventbox, false, false, 10);
		icon_box.pack_end(m_marked_eventbox, false, false, 0);


		var body_label = new Gtk.Label(preview);
		body_label.opacity = 0.7;
		body_label.get_style_context().add_class("preview");
		body_label.set_alignment(0, 0);
		body_label.set_ellipsize (Pango.EllipsizeMode.END);
		body_label.set_line_wrap_mode(Pango.WrapMode.WORD_CHAR);
		body_label.set_line_wrap(true);
		body_label.set_lines(3);


		var text_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		text_box.margin_end = 15;
		text_box.pack_start(m_label, true, true, 6);
		text_box.pack_end(body_label, true, true, 6);

		m_box.pack_start(icon_box, false, false, 8);
		m_box.pack_start(text_box, true, true, 0);

		var seperator_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		var separator = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
		separator.set_size_request(0, 2);
		seperator_box.pack_start(m_box, true, true, 0);
		seperator_box.pack_start(separator, false, false, 0);

		m_revealer = new Gtk.Revealer();
		m_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
		m_revealer.add(seperator_box);
		m_revealer.set_reveal_child(false);
		this.add(m_revealer);
		this.show_all();
	}


	private void unreadIconClicked()
	{
		if(m_just_clicked)
			unreadIconEnter();
		m_just_clicked = true;
		toggleUnread();
	}

	public void toggleUnread()
	{
		switch(m_is_unread)
		{
			case ArticleStatus.READ:
				updateUnread(ArticleStatus.UNREAD);
				break;
			case ArticleStatus.UNREAD:
				updateUnread(ArticleStatus.READ);
				break;
		}


		feedDaemon_interface.changeArticle(m_articleID, m_is_unread);
	}

	private void unreadIconEnter()
	{
		m_hovering_unread = true;
		if(m_is_unread == ArticleStatus.READ){
			m_unread_stack.set_visible_child_name("unread");
		}
		else if(m_is_unread == ArticleStatus.UNREAD){
			m_unread_stack.set_visible_child_name("read");
		}
		this.show_all();
	}


	public void unreadIconLeave()
	{
		m_hovering_unread = false;
		if(!m_just_clicked){
			if(m_is_unread == ArticleStatus.READ){
				m_unread_stack.set_visible_child_name("read");
			}
			else{
				m_unread_stack.set_visible_child_name("unread");
			}
		}
		m_just_clicked = false;
		this.show_all();
	}

	public void updateUnread(ArticleStatus unread)
	{
		if(m_is_unread != unread)
		{
			m_is_unread = unread;
			if(m_is_unread == ArticleStatus.UNREAD)
			{
				m_label.get_style_context().remove_class("headline-read-label");
				m_label.get_style_context().add_class("headline-unread-label");
				if(!isHoveringUnread())
				{
					m_unread_stack.set_visible_child_name("unread");
				}
			}
			else
			{
				m_label.get_style_context().remove_class("headline-unread-label");
				m_label.get_style_context().add_class("headline-read-label");
				if(!isHoveringUnread())
				{
					m_unread_stack.set_visible_child_name("read");
				}
			}
		}
	}

	public void removeUnreadIcon()
	{
		m_unread_stack.set_visible_child_name("read");
		this.show_all();
	}


	private bool markedIconClicked()
	{
		m_just_clicked = true;
		toggleMarked();
		return true;
	}

	public void toggleMarked()
	{
		switch(m_marked)
		{
			case ArticleStatus.MARKED:
				updateMarked(ArticleStatus.UNMARKED);
				break;

			case ArticleStatus.UNMARKED:
				updateMarked(ArticleStatus.MARKED);
				break;
		}

		feedDaemon_interface.changeArticle(m_articleID, m_marked);
	}

	private bool markedIconEnter()
	{
		m_hovering_marked = true;
		if(m_marked == ArticleStatus.UNMARKED){
			m_marked_stack.set_visible_child_name("marked");
		}
		else if (m_marked == ArticleStatus.MARKED){
			m_marked_stack.set_visible_child_name("unmarked");
		}
		this.show_all();
		return true;
	}


	private bool markedIconLeave()
	{
		m_hovering_marked = false;
		if(!m_just_clicked){
			if(m_marked == ArticleStatus.UNMARKED){
				m_marked_stack.set_visible_child_name("unmarked");
			}
			else if(m_marked == ArticleStatus.MARKED){
				m_marked_stack.set_visible_child_name("marked");
			}
			this.show_all();
		}
		m_just_clicked = false;
		return true;
	}

	public void updateMarked(ArticleStatus marked)
	{
		if(m_marked != marked)
		{
			m_marked = marked;
			switch(m_marked)
			{
				case ArticleStatus.MARKED:
					if(!isHoveringMarked())
					{
						m_marked_stack.set_visible_child_name("marked");
					}
					break;

				case ArticleStatus.UNMARKED:
					if(!isHoveringMarked())
					{
						m_marked_stack.set_visible_child_name("unmarked");
					}
					break;
			}
		}
	}

	public bool isUnread()
	{
		if(m_is_unread == ArticleStatus.UNREAD)
			return true;

		return false;
	}

	public bool isMarked()
	{
		if(m_marked == ArticleStatus.MARKED)
			return true;

		return false;
	}

	public string getName()
	{
		return m_name;
	}

	public string getID()
	{
		return m_articleID;
	}

	public GLib.DateTime getDate()
	{
		return m_date;
	}

	public string getDateStr()
	{
		return m_date.format("%Y-%m-%d %H:%M:%S");
	}

	public bool getUpdated()
	{
		return m_updated;
	}

	public void setUpdated(bool updated)
	{
		m_updated = updated;
	}

	public bool isHoveringUnread()
	{
		return m_hovering_unread;
	}

	public bool isHoveringMarked()
	{
		return m_hovering_marked;
	}

	public string getURL()
	{
		return m_url;
	}

	public void reveal(bool reveal, uint duration = 500)
	{
		m_revealer.set_transition_duration(duration);
		m_revealer.set_reveal_child(reveal);
	}

}
