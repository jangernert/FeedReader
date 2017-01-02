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
	private Gtk.Button m_print_button;
	private UpdateButton m_media_button;
	private HoverButton m_mark_button;
	private HoverButton m_read_button;
	private Gtk.Button m_fullscreen_button;
	private ModeButton m_modeButton;
	private UpdateButton m_refresh_button;
	private Gtk.SearchEntry m_search;
	private ArticleListState m_state;
	private Gtk.HeaderBar m_header_left;
	private Gtk.HeaderBar m_header_right;
	private Gtk.Label m_syncProgressText;
	private Gtk.Popover m_syncPopover;
	private SharePopover? m_sharePopover = null;
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
		var fs_icon = new Gtk.Image.from_icon_name("view-fullscreen-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		m_state = (ArticleListState)Settings.state().get_enum("show-articles");


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

		m_fullscreen_button = new Gtk.Button();
		m_fullscreen_button.add(fs_icon);
		m_fullscreen_button.set_relief(Gtk.ReliefStyle.NONE);
		m_fullscreen_button.set_focus_on_click(false);
		m_fullscreen_button.set_tooltip_text(_("Read article fullscreen"));
		m_fullscreen_button.sensitive = false;
		m_fullscreen_button.clicked.connect(() => {
			var window = MainWindow.get_default();
			window.fullscreen();
			ColumnView.get_default().enterFullscreen(false);
		});


		m_header_left = new Gtk.HeaderBar ();
		m_header_left.show_close_button = true;
		m_header_left.get_style_context().add_class("header_right");
		m_header_left.get_style_context().add_class("titlebar");
		m_header_left.set_size_request(500, 0);


		m_header_right = new Gtk.HeaderBar ();
		m_header_right.show_close_button = true;
		m_header_right.get_style_context().add_class("header_left");
		m_header_right.get_style_context().add_class("titlebar");
		m_header_right.set_title("FeedReader");
		m_header_right.set_size_request(450, 0);

		Gtk.Settings.get_default().notify["gtk-decoration-layout"].connect(set_window_buttons);
		realize.connect(set_window_buttons);
		set_window_buttons();

		m_modeButton = new ModeButton();
		m_modeButton.append_text(_("All"), _("Show all articles"));
		m_modeButton.append_text(_("Unread"), _("Show only unread articles"));
		m_modeButton.append_text(_("Starred"), _("Show only starred articles"));
		m_modeButton.set_active(m_state, true);

		m_tag_button = new Gtk.Button();
		m_tag_button.add(tag_icon);
		m_tag_button.set_relief(Gtk.ReliefStyle.NONE);
		m_tag_button.set_focus_on_click(false);
		m_tag_button.set_tooltip_text(_("Tag Article"));
		m_tag_button.sensitive = false;
		m_tag_button.clicked.connect(() => {
			new TagPopover(m_tag_button);
		});


		m_print_button = new Gtk.Button.from_icon_name("document-save-symbolic");
		m_print_button.set_relief(Gtk.ReliefStyle.NONE);
		m_print_button.set_focus_on_click(false);
		m_print_button.set_tooltip_text(_("Save Article as PDF"));
		m_print_button.sensitive = false;
		m_print_button.clicked.connect(() => {
			UtilsUI.printDialog();
		});


		m_share_button = new Gtk.Button();
		m_share_button.add(share_icon);
		m_share_button.set_relief(Gtk.ReliefStyle.NONE);
		m_share_button.set_focus_on_click(false);
		m_share_button.set_tooltip_text(_("Share Article"));
		m_share_button.sensitive = false;

		var shareSpinner = new Gtk.Spinner();
		var shareStack = new Gtk.Stack();
		shareStack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		shareStack.set_transition_duration(100);
		shareStack.add_named(m_share_button, "button");
		shareStack.add_named(shareSpinner, "spinner");
		shareStack.set_visible_child_name("button");

		m_share_button.clicked.connect(() => {
			m_sharePopover = new SharePopover(m_share_button);
			m_sharePopover.showSettings.connect((panel) => {
				showSettings(panel);
			});
			m_sharePopover.startShare.connect(() => {
				shareStack.set_visible_child_name("spinner");
				shareSpinner.start();
			});
			m_sharePopover.shareDone.connect(() => {
				shareStack.set_visible_child_name("button");
				shareSpinner.stop();
			});
			m_sharePopover.closed.connect(() => {
				m_sharePopover = null;
			});
		});

		m_media_button = new UpdateButton.from_icon_name("mail-attachment-symbolic", _("Attachments"));
		m_media_button.no_show_all = true;
		m_media_button.clicked.connect(() => {
			var pop = new MediaPopover(m_media_button);
			pop.play.connect((url) => {
				m_media_button.updating(true);
				var media = new MediaPlayer(url);
				media.loaded.connect(() => {
					m_media_button.updating(false);
				});
				ColumnView.get_default().ArticleViewAddMedia(media);
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



		m_refresh_button = new UpdateButton.from_icon_name("feed-refresh-symbolic", _("Update Feeds"));
		m_refresh_button.clicked.connect(() => {
			if(!m_refresh_button.getStatus())
				refresh();
			else
				m_syncPopover.show_all();
		});
		m_syncProgressText = new Gtk.Label(_("Waiting for next update information"));
		m_syncProgressText.margin = 20;
		m_syncPopover = new Gtk.Popover(m_refresh_button);
		m_syncPopover.add(m_syncProgressText);



		m_search = new Gtk.SearchEntry();
		m_search.placeholder_text = _("Search Articles");
		m_search.search_changed.connect(() => {
			search_term(m_search.text);
		});

		if(Settings.tweaks().get_boolean("restore-searchterm"))
			m_search.text = Settings.state().get_string("search-term");

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


		m_header_left.pack_end(m_search);
		m_header_left.pack_start(m_modeButton);
		m_header_left.pack_start(m_refresh_button);

		m_header_right.pack_start(m_fullscreen_button);
		m_header_right.pack_start(m_mark_button);
		m_header_right.pack_start(m_read_button);
		m_header_right.pack_end(shareStack);
		m_header_right.pack_end(m_tag_button);
		m_header_right.pack_end(m_print_button);
		m_header_right.pack_end(m_media_button);


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
		Logger.debug("HeaderBar: showArticleButtons %s".printf(sensitive ? "true" : "false"));
		m_mark_button.sensitive = show;
		m_read_button.sensitive = show;
		m_fullscreen_button.sensitive = show;
		m_media_button.visible = show;
		m_share_button.sensitive = (show && FeedReaderApp.get_default().isOnline());
		m_print_button.sensitive = show;

		try
		{
			if(DBusConnection.get_default().supportTags()
			&& UtilsUI.canManipulateContent())
			{
				m_tag_button.sensitive = (show && FeedReaderApp.get_default().isOnline());
			}
		}
		catch(GLib.Error e)
		{
			Logger.error("readerHeaderbar.showArticleButtons: %s".printf(e.message));
		}

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

	public void focusSearch()
	{
		m_search.grab_focus();
	}

	public void setOffline()
	{
		try
		{
			m_share_button.sensitive = false;
			if(UtilsUI.canManipulateContent()
			&& DBusConnection.get_default().supportTags())
				m_tag_button.sensitive = false;
		}
		catch(GLib.Error e)
		{
			Logger.error("Headerbar.setOffline: %s".printf(e.message));
		}
	}

	public void setOnline()
	{
		try
		{
			if(m_mark_button.sensitive)
			{
				m_share_button.sensitive = true;
				if(UtilsUI.canManipulateContent()
				&& DBusConnection.get_default().supportTags())
					m_tag_button.sensitive = true;
			}
		}
		catch(GLib.Error e)
		{
			Logger.error("Headerbar.setOnline: %s".printf(e.message));
		}

	}

	public void showMediaButton(bool show)
	{
		m_media_button.visible = show;
	}

	public void updateSyncProgress(string progress)
	{
		m_syncProgressText.set_text(progress);
	}

	public bool sharePopoverShown()
	{
		if(m_sharePopover != null)
			return true;

		return false;
	}

	public void refreshSahrePopover()
	{
		m_sharePopover.refreshList();
	}
}
