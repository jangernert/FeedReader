//	This file is part of FeedReader.
//
//	FeedReader is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	FeedReader is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with FeedReader.  If not, see <http://www.gnu.org/licenses/>.

public class FeedReader.readerHeaderbar : Gtk.Paned {

	private Gtk.Button m_share_button;
	private Gtk.Button m_tag_button;
	private HoverButton m_mark_button;
	private HoverButton m_read_button;
	private ModeButton m_modeButton;
	private UpdateButton m_refresh_button;
	private Gtk.SearchEntry m_search;
	private ArticleListState m_state;
	private Gtk.HeaderBar m_header_left;
	private Gtk.HeaderBar m_header_right;
	private TagPopover m_pop;
	public signal void refresh();
	public signal void change_state(ArticleListState state, Gtk.StackTransitionType transition);
	public signal void search_term(string searchTerm);
	public signal void showSettings(string panel);
	public signal void toggledMarked();
	public signal void toggledRead();


	public readerHeaderbar () {
		var share_icon = new Gtk.Image.from_icon_name("feed-share-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		var tag_icon = new Gtk.Image.from_icon_name("feed-tag-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		var marked_icon = new Gtk.Image.from_icon_name("feed-marked-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		var unmarked_icon = new Gtk.Image.from_icon_name("feed-unmarked-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		var read_icon = new Gtk.Image.from_icon_name("feed-read-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		var unread_icon = new Gtk.Image.from_icon_name("feed-unread-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		m_state = (ArticleListState)settings_state.get_enum("show-articles");


		m_mark_button = new HoverButton(unmarked_icon, marked_icon, false);
		m_mark_button.sensitive = false;
		m_mark_button.set_tooltip_text(_("Mark article (un)starred"));
		m_mark_button.clicked.connect(() => {
			toggledMarked();
		});
		m_read_button = new HoverButton(read_icon, unread_icon, false);
		m_read_button.sensitive = false;
		m_read_button.set_tooltip_text(_("Mark article (un)read"));
		m_read_button.clicked.connect(() => {
			toggledRead();
		});


		m_header_left = new Gtk.HeaderBar ();
		m_header_left.show_close_button = true;
		m_header_left.get_style_context().add_class("header_right");
		m_header_left.get_style_context().add_class("titlebar");
		m_header_left.set_size_request(601, 0);


		m_header_right = new Gtk.HeaderBar ();
		m_header_right.show_close_button = true;
		m_header_right.get_style_context().add_class("header_left");
		m_header_right.get_style_context().add_class("titlebar");
		m_header_right.set_title("FeedReader");
		m_header_right.set_size_request(600, 0);

		Gtk.Settings.get_default().notify["gtk-decoration-layout"].connect(set_window_buttons);
		realize.connect(set_window_buttons);
		set_window_buttons();

		m_modeButton = new ModeButton();
		m_modeButton.append_text("All", _("Show all articles"));
		m_modeButton.append_text("Unread", _("Show only unread articles"));
		m_modeButton.append_text("Starred", _("Show only starred articles"));
		m_modeButton.set_active(m_state);

		m_tag_button = new Gtk.Button();
		m_tag_button.add(tag_icon);
		m_tag_button.set_relief(Gtk.ReliefStyle.NONE);
		m_tag_button.set_focus_on_click(false);
		m_tag_button.set_tooltip_text(_("Tag Article"));
		m_tag_button.sensitive = false;
		m_tag_button.clicked.connect(() => {
			m_pop = new TagPopover(m_tag_button);
		});

		m_share_button = new Gtk.Button();
		m_share_button.add(share_icon);
		m_share_button.set_relief(Gtk.ReliefStyle.NONE);
		m_share_button.set_focus_on_click(false);
		m_share_button.set_tooltip_text(_("Share Article"));
		m_share_button.sensitive = false;
		m_share_button.clicked.connect(() => {
			var pop = new SharePopover(m_share_button);
			pop.showSettings.connect((panel) => {
				showSettings(panel);
			});
		});

		m_modeButton.mode_changed.connect(() => {
			var transition = Gtk.StackTransitionType.CROSSFADE;
			if(m_state == ArticleListState.ALL
			|| (ArticleListState)m_modeButton.selected == ArticleListState.MARKED)
			{
				transition = Gtk.StackTransitionType.SLIDE_LEFT;
			}
			else if(m_state == ArticleListState.MARKED
			|| (ArticleListState)m_modeButton.selected == ArticleListState.ALL)
			{
				transition = Gtk.StackTransitionType.SLIDE_RIGHT;
			}

			m_state = (ArticleListState)m_modeButton.selected;
			change_state(m_state, transition);
		});



		m_refresh_button = new UpdateButton("feed-refresh");
		m_refresh_button.clicked.connect(() => {
			refresh();
		});

		m_search = new Gtk.SearchEntry();
		m_search.placeholder_text = _("Search Articles");
		m_search.text = settings_state.get_string("search-term");
		m_search.search_changed.connect(() => {
			search_term(m_search.text);
		});

		string session = GLib.Environment.get_variable("DESKTOP_SESSION");
		if(session != "gnome")
		{
			var menumodel = new GLib.Menu();
			menumodel.append(Menu.settings, "win.settings");
			menumodel.append(Menu.reset, "win.reset");

			if(session != "pantheon")
			{
				menumodel.append(Menu.about, "win.about");
			}

			var menubutton = new Gtk.MenuButton();
			menubutton.image = new Gtk.Image.from_icon_name("emblem-system-symbolic", Gtk.IconSize.MENU);
			menubutton.set_size_request(32, 32);
			menubutton.set_use_popover(true);
			menubutton.set_menu_model(menumodel);
			menubutton.set_tooltip_text(_("Settings"));
			m_header_left.pack_end(menubutton);
		}


		m_header_left.pack_end(m_search);
		m_header_left.pack_start(m_modeButton);
		m_header_left.pack_start(m_refresh_button);

		m_header_right.pack_start(m_mark_button);
		m_header_right.pack_start(m_read_button);
		m_header_right.pack_end(m_share_button);
		m_header_right.pack_end(m_tag_button);

		this.pack1(m_header_left, true, false);
		this.pack2(m_header_right, true, false);
		this.get_style_context().add_class("headerbar_pane");
		this.set_position(settings_state.get_int("feeds-and-articles-width"));
	}

	private void set_window_buttons()
	{
        string[] buttons = Gtk.Settings.get_default().gtk_decoration_layout.split(":");
        if (buttons.length < 2) {
			buttons = {buttons[0], ""};
			logger.print(LogMessage.WARNING, "gtk_decoration_layout in unexpected format");
        }

		logger.print(LogMessage.DEBUG, buttons[0]);
		logger.print(LogMessage.DEBUG, buttons[1]);

		m_header_left.set_decoration_layout(buttons[0] + ":");
		m_header_right.set_decoration_layout(":" + buttons[1]);
    }

	public void setRefreshButton(bool status)
	{
		m_refresh_button.updating(status);
	}

	public void setButtonsSensitive(bool sensitive)
	{
		logger.print(LogMessage.DEBUG, "HeaderBar: updatebutton status %s".printf(sensitive ? "true" : "false"));
		m_modeButton.sensitive = sensitive;
		m_refresh_button.setSensitive(sensitive);
		m_search.sensitive = sensitive;
	}

	public void showArticleButtons(bool show)
	{
		m_share_button.sensitive = show;
		m_mark_button.sensitive = show;
		m_read_button.sensitive = show;

		if(feedDaemon_interface.supportTags())
		{
			m_tag_button.sensitive = show;
		}
	}

	public bool currentlyUpdating()
	{
		return m_refresh_button.getStatus();
	}

	public string getSearchTerm()
	{
		return m_search.text;
	}

	public ArticleListState getArticleListState()
	{
		return m_state;
	}

	public bool searchFocused()
	{
		return m_search.has_focus;
	}

	public bool tagEntryFocused()
	{
		if(m_pop == null)
			return false;

		return m_pop.entryFocused();
	}

	public void setMarked(bool marked)
	{
		m_mark_button.setActive(marked);
	}

	public void toggleMarked()
	{
		m_mark_button.toggle();
	}

	public void setRead(bool read)
	{
		m_read_button.setActive(read);
	}

	public void toggleRead()
	{
		m_read_button.toggle();
	}

}
