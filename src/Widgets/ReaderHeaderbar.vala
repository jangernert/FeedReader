public class FeedReader.readerHeaderbar : Gtk.HeaderBar {
	
	private Gtk.ToggleButton m_only_unread_button;
	private Gtk.ToggleButton m_only_marked_button;
	private UpdateButton m_refresh_button;
	private Gtk.SearchEntry m_search;
	private bool m_only_unread { get; private set; }
	private bool m_only_marked { get; private set; }
	public signal void refresh();
	public signal void change_unread(bool only_unread);
	public signal void change_marked(bool only_marked);
	public signal void search_term(string searchTerm);


	public readerHeaderbar () {
		var only_unread_icon = new Gtk.Image.from_icon_name("object-inverse", Gtk.IconSize.LARGE_TOOLBAR);
		var only_marked_icon = new Gtk.Image.from_icon_name("help-about", Gtk.IconSize.LARGE_TOOLBAR);


		m_only_unread = settings_state.get_boolean("only-unread");
		m_only_marked = settings_state.get_boolean("only-marked");
		
		m_only_unread_button = new Gtk.ToggleButton();
		m_only_unread_button.add(only_unread_icon);
		m_only_unread_button.set_active(m_only_unread);

		m_only_marked_button = new Gtk.ToggleButton();
		m_only_marked_button.add(only_marked_icon);
		m_only_marked_button.set_active(m_only_marked);

		
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
		m_search.placeholder_text = _("Search Aritlces...");
		m_search.text = settings_state.get_string("search-term");
		m_search.search_changed.connect(() => {
			search_term(m_search.text);
		});
		
		var menumodel = new GLib.Menu ();
		var changeAccount = new MenuItem ("Change Account", "win.reset");
		menumodel.insert_item(0, changeAccount);
		var about = new MenuItem ("About", "win.about");
		menumodel.insert_item(1, about);

		var menubutton = new Gtk.MenuButton();
		menubutton.image = new Gtk.Image.from_icon_name("emblem-system-symbolic", Gtk.IconSize.MENU);
		menubutton.set_size_request(32, 32);
		menubutton.set_use_popover(true);
		menubutton.set_menu_model(menumodel);
		
		this.show_close_button = true;
		this.pack_end(menubutton);
		this.pack_end(m_search);
		this.pack_start(m_only_unread_button);
		this.pack_start(m_only_marked_button);
		this.pack_start(m_refresh_button);
	}

	public void setRefreshButton(bool status)
	{
		m_refresh_button.updating(status);
	}
	
	public void setButtonsSensitive(bool sensitive)
	{
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

