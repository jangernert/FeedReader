public class FeedReader.readerHeaderbar : Gtk.Paned {

	private Gtk.ToggleButton m_only_unread_button;
	private Gtk.ToggleButton m_only_marked_button;
	private UpdateButton m_refresh_button;
	private Gtk.SearchEntry m_search;
	private bool m_only_unread { get; private set; }
	private bool m_only_marked { get; private set; }
	private Gtk.HeaderBar m_header_left;
    private Gtk.HeaderBar m_header_right;
	public signal void refresh();
	public signal void change_unread(bool only_unread);
	public signal void change_marked(bool only_marked);
	public signal void search_term(string searchTerm);


	public readerHeaderbar () {
		var only_unread_icon = new Gtk.Image.from_icon_name("object-inverse", Gtk.IconSize.LARGE_TOOLBAR);
		var only_marked_icon = new Gtk.Image.from_icon_name("help-about", Gtk.IconSize.LARGE_TOOLBAR);

		m_header_left = new Gtk.HeaderBar ();
        m_header_left.show_close_button = true;
        m_header_left.set_decoration_layout("close:");
        m_header_left.get_style_context().add_class("header_right");
        m_header_left.get_style_context().add_class("titlebar");
        m_header_left.set_size_request(601, 0);


        m_header_right = new Gtk.HeaderBar ();
        m_header_right.show_close_button = true;
        m_header_right.set_decoration_layout(":maximize");
        m_header_right.get_style_context().add_class("header_left");
        m_header_right.get_style_context().add_class("titlebar");
        m_header_right.set_title("FeedReader");
		m_header_right.set_size_request(600, 0);


		m_only_unread = settings_state.get_boolean("only-unread");
		m_only_marked = settings_state.get_boolean("only-marked");

		m_only_unread_button = new Gtk.ToggleButton();
		m_only_unread_button.add(only_unread_icon);
		m_only_unread_button.set_active(m_only_unread);
		m_only_unread_button.set_focus_on_click(false);
		m_only_unread_button.set_tooltip_text(_("only show unread articles"));

		m_only_marked_button = new Gtk.ToggleButton();
		m_only_marked_button.add(only_marked_icon);
		m_only_marked_button.set_active(m_only_marked);
		m_only_marked_button.set_focus_on_click(false);
		m_only_marked_button.set_tooltip_text(_("only show marked articles"));


		m_only_unread_button.toggled.connect (() => {
			if (m_only_unread_button.active) {
				m_only_unread = true;

			} else {
				m_only_unread = false;
			}
			change_unread(m_only_unread);
		});

		m_only_marked_button.toggled.connect (() => {
			if (m_only_marked_button.active) {
				m_only_marked = true;

			} else {
				m_only_marked = false;
			}
			change_marked(m_only_marked);
		});

		m_refresh_button = new UpdateButton("view-refresh");
		m_refresh_button.clicked.connect(() => {
			refresh();
		});

		m_search = new Gtk.SearchEntry();
		m_search.placeholder_text = _("Search Aritlces");
		m_search.text = settings_state.get_string("search-term");
		m_search.search_changed.connect(() => {
			search_term(m_search.text);
		});

		var menumodel = new GLib.Menu ();
		var changeAccount = new MenuItem ("Change Account", "win.reset");
		menumodel.insert_item(0, changeAccount);

		var menubutton = new Gtk.MenuButton();
		menubutton.image = new Gtk.Image.from_icon_name("emblem-system-symbolic", Gtk.IconSize.MENU);
		menubutton.set_size_request(32, 32);
		menubutton.set_use_popover(true);
		menubutton.set_menu_model(menumodel);

		m_header_left.pack_end(menubutton);
		m_header_left.pack_end(m_search);
		m_header_left.pack_start(m_only_unread_button);
		m_header_left.pack_start(m_only_marked_button);
		m_header_left.pack_start(m_refresh_button);

		this.pack1(m_header_left, true, false);
		this.pack2(m_header_right, true, false);
		this.get_style_context().add_class("headerbar_pane");
		this.set_position(settings_state.get_int("feeds-and-articles-width"));
	}

	public void setRefreshButton(bool status)
	{
		m_refresh_button.updating(status);
	}

	public void setButtonsSensitive(bool sensitive)
	{
		logger.print(LogMessage.DEBUG, "HeaderBar: updatebutton status %s".printf(sensitive ? "true" : "false"));
		m_only_unread_button.sensitive = sensitive;
		m_only_marked_button.sensitive = sensitive;
		m_refresh_button.setSensitive(sensitive);
		m_search.sensitive = sensitive;
	}

	public bool currentlyUpdating()
	{
		return m_refresh_button.getStatus();
	}

	public string getSearchTerm()
	{
		return m_search.text;
	}

	public bool getOnlyUnread()
	{
		return m_only_unread;
	}

	public bool getOnlyMarked()
	{
		return m_only_marked;
	}

}
