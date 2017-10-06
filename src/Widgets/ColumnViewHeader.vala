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

public class FeedReader.ColumnViewHeader : Gtk.Paned {

	private ModeButton m_modeButton;
	private UpdateButton m_refresh_button;
	private Gtk.SearchEntry m_search;
	private ArticleListState m_state;
	private Gtk.HeaderBar m_header_left;
	private ArticleViewHeader m_header_right;
	public signal void refresh();
	public signal void cancel();
	public signal void change_state(ArticleListState state, Gtk.StackTransitionType transition);
	public signal void search_term(string searchTerm);
	public signal void toggledMarked();
	public signal void toggledRead();


	public ColumnViewHeader()
	{
		m_state = (ArticleListState)Settings.state().get_enum("show-articles");

		m_modeButton = new ModeButton();
		m_modeButton.append_text(_("All"), _("Show all articles"));
		m_modeButton.append_text(_("Unread"), _("Show only unread articles"));
		m_modeButton.append_text(_("Starred"), _("Show only starred articles"));
		m_modeButton.set_active(m_state, true);

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

		bool updating = Settings.state().get_boolean("currently-updating");
		m_refresh_button = new UpdateButton.from_icon_name("feed-refresh-symbolic", _("Update feeds"), true, true);
		m_refresh_button.updating(updating);
		m_refresh_button.clicked.connect(() => {
			if(!m_refresh_button.getStatus())
				refresh();
			else
			{
				cancel();
				m_refresh_button.setSensitive(false);
			}
		});



		m_search = new Gtk.SearchEntry();
		m_search.placeholder_text = _("Search Articles");
		if(Settings.tweaks().get_boolean("restore-searchterm"))
			m_search.text = Settings.state().get_string("search-term");

		// connect after 160ms because Gtk.SearchEntry fires search_changed with 150ms delay
		// with the timeout the signal should not trigger a newList() when restoring the state at startup
		GLib.Timeout.add(160, () => {
			m_search.search_changed.connect(() => {
				search_term(m_search.text);
			});
			return false;
		});

		m_header_left = new Gtk.HeaderBar();
		m_header_left.show_close_button = true;
		m_header_left.get_style_context().add_class("header_right");
		m_header_left.get_style_context().add_class("titlebar");
		m_header_left.set_size_request(500, 0);

		if(GLib.Environment.get_variable("XDG_CURRENT_DESKTOP").down() != "gnome")
		{
			var menubutton = new Gtk.MenuButton();
			menubutton.image = new Gtk.Image.from_icon_name("emblem-system-symbolic", Gtk.IconSize.MENU);
			menubutton.set_size_request(32, 32);
			menubutton.set_use_popover(true);
			menubutton.set_menu_model(UtilsUI.getMenu());
			menubutton.set_tooltip_text(_("Settings"));
			m_header_left.pack_end(menubutton);
		}
		else if(GLib.Environment.get_variable("XDG_CURRENT_DESKTOP").down() == "gnome")
		{
			FeedReaderApp.get_default().app_menu = UtilsUI.getMenu();
		}


		m_header_left.pack_end(m_search);
		m_header_left.pack_start(m_modeButton);
		m_header_left.pack_start(m_refresh_button);

		m_header_right = new ArticleViewHeader("view-fullscreen-symbolic", _("Read article fullscreen"));
		m_header_right.show_close_button = true;
		m_header_right.get_style_context().add_class("header_left");
		m_header_right.get_style_context().add_class("titlebar");
		this.clearTitle();
		m_header_right.set_size_request(450, 0);
		m_header_right.toggledMarked.connect(() => {
			toggledMarked();
		});
		m_header_right.toggledRead.connect(() => {
			toggledRead();
		});
		m_header_right.fsClick.connect(() => {
			ColumnView.get_default().hidePane();
			ColumnView.get_default().enterFullscreenArticle();
			MainWindow.get_default().fullscreen();
		});

		Gtk.Settings.get_default().notify["gtk-decoration-layout"].connect(set_window_buttons);
		realize.connect(set_window_buttons);
		set_window_buttons();


		this.pack1(m_header_left, true, false);
		this.pack2(m_header_right, true, false);
		this.get_style_context().add_class("headerbar_pane");
		this.set_position(Settings.state().get_int("feeds-and-articles-width"));
	}

	private void set_window_buttons()
	{
		string[] buttons = Gtk.Settings.get_default().gtk_decoration_layout.split(":");
		if (buttons.length < 2) {
			buttons = {buttons[0], ""};
			Logger.warning("gtk_decoration_layout in unexpected format");
		}

		m_header_left.set_decoration_layout(buttons[0] + ":");
		m_header_right.set_decoration_layout(":" + buttons[1]);
	}

	public void setRefreshButton(bool status)
	{
		m_refresh_button.updating(status, false);
	}

	public void setButtonsSensitive(bool sensitive)
	{
		Logger.debug("HeaderBar: setButtonsSensitive %s".printf(sensitive ? "true" : "false"));
		m_modeButton.sensitive = sensitive;
		m_refresh_button.setSensitive(sensitive);
		m_search.sensitive = sensitive;
	}

	public void showArticleButtons(bool show)
	{
		m_header_right.showArticleButtons(show);
	}

	public bool searchFocused()
	{
		return m_search.has_focus;
	}

	public void setMarked(bool marked)
	{
		m_header_right.setMarked(marked);
	}

	public void toggleMarked()
	{
		m_header_right.toggleMarked();
	}

	public void setRead(bool read)
	{
		m_header_right.setRead(read);
	}

	public void toggleRead()
	{
		m_header_right.toggleRead();
	}

	public void focusSearch()
	{
		m_search.grab_focus();
	}

	public void setOffline()
	{
		m_header_right.setOffline();
	}

	public void setOnline()
	{
		m_header_right.setOnline();
	}

	public void showMediaButton(bool show)
	{
		m_header_right.showMediaButton(show);
	}

	public void updateSyncProgress(string progress)
	{
		m_refresh_button.setProgress(progress);
	}

	public void refreshSahrePopover()
	{
		m_header_right.refreshSahrePopover();
	}

	public void saveState(ref InterfaceState state)
	{
		state.setSearchTerm(m_search.text);
		state.setArticleListState(m_state);
	}
	public void setTitle(string title)
	{
		m_header_right.set_title(title);
	}
	public void clearTitle()
	{
		m_header_right.set_title("FeedReader");
	}

}
