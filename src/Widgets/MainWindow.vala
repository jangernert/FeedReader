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

using GLib;
using Gtk;

public class FeedReader.readerUI : Gtk.ApplicationWindow
{
	private readerHeaderbar m_headerbar;
	private SimpleHeader m_simpleHeader;
	private Gtk.Stack m_stack;
	private Gtk.Label m_ErrorMessage;
	private Gtk.InfoBar m_error_bar;
	private Gtk.Button m_ignore_tls_errors;
	private ContentPage m_content;
	private LoginPage m_login;
	private SpringCleanPage m_SpringClean;
	Gtk.CssProvider m_cssProvider;

	public readerUI(FeedApp app)
	{
		Object (application: app, title: _("FeedReader"));
		this.window_position = WindowPosition.CENTER;

		m_stack = new Gtk.Stack();
		m_stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		m_stack.set_transition_duration(100);

		setupCSS();
		setupLoginPage();
		setupResetPage();
		setupContentPage();
		setupSpringCleanPage();
		onClose();

		var shortcutsAction = new SimpleAction("shortcuts", null);
		shortcutsAction.activate.connect(showShortcutWindow);
		this.add_action(shortcutsAction);
		shortcutsAction.set_enabled(true);

		var reportBugAction = new SimpleAction("bugs", null);
		reportBugAction.activate.connect(() => {
			try{
				Gtk.show_uri(Gdk.Screen.get_default(), "https://github.com/jangernert/FeedReader/issues", Gdk.CURRENT_TIME);
			}
			catch(GLib.Error e){
				logger.print(LogMessage.DEBUG, "could not open the link in an external browser: %s".printf(e.message));
			}
		});
		this.add_action(reportBugAction);
		reportBugAction.set_enabled(true);

		var bountyAction = new SimpleAction("bounty", null);
		bountyAction.activate.connect(() => {
			try{
				Gtk.show_uri(Gdk.Screen.get_default(), "https://www.bountysource.com/teams/feedreader-gtk/issues?tracker_ids=16778038", Gdk.CURRENT_TIME);
			}
			catch(GLib.Error e){
				logger.print(LogMessage.DEBUG, "could not open the link in an external browser: %s".printf(e.message));
			}
		});
		this.add_action(bountyAction);
		bountyAction.set_enabled(true);

		var settingsAction = new SimpleAction("settings", null);
		settingsAction.activate.connect(() => {
			showSettings("ui");
		});
		this.add_action(settingsAction);
		settingsAction.set_enabled(true);

		var login_action = new SimpleAction("reset", null);
		login_action.activate.connect(() => {
			showReset(Gtk.StackTransitionType.SLIDE_RIGHT);
		});
		this.add_action(login_action);
		login_action.set_enabled(true);

		var about_action = new SimpleAction("about", null);
		about_action.activate.connect(() => {
			Gtk.AboutDialog dialog = new Gtk.AboutDialog();
			dialog.set_transient_for(this);
			dialog.set_modal(true);
			dialog.artists = AboutInfo.artists;
			dialog.authors = AboutInfo.authors;
			dialog.documenters = null;
			dialog.translator_credits = AboutInfo.translators;

			dialog.program_name = AboutInfo.programmName;
			dialog.comments = AboutInfo.comments;
			dialog.copyright = AboutInfo.copyright;
			dialog.version = AboutInfo.version;
			dialog.logo_icon_name = AboutInfo.iconName;
			dialog.license_type = Gtk.License.GPL_3_0;
			dialog.wrap_license = true;

			dialog.website = AboutInfo.website;
			dialog.website_label = AboutInfo.websiteLabel;

			dialog.response.connect((response_id) => {
				if (response_id == Gtk.ResponseType.CANCEL || response_id == Gtk.ResponseType.DELETE_EVENT)
				{
					dialog.hide_on_delete();
				}
			});

			dialog.present();
		});
		this.add_action(about_action);
		about_action.set_enabled(true);

		m_headerbar = new readerHeaderbar();
		m_headerbar.refresh.connect(() => {
			m_content.syncStarted();
			app.sync.begin((obj, res) => {
				app.sync.end(res);
			});
		});

		m_headerbar.change_state.connect((state, transition) => {
			m_content.setArticleListState(state);
			m_content.clearArticleView();
			m_content.newArticleList(transition);
		});

		m_headerbar.search_term.connect((searchTerm) => {
			m_content.setSearchTerm(searchTerm);
			m_content.clearArticleView();
			m_content.newArticleList();
		});

		m_headerbar.showSettings.connect((panel) => {
			showSettings(panel);
		});

		m_headerbar.notify["position"].connect(() => {
        	m_content.setArticleListPosition(m_headerbar.get_position());
        });

		m_headerbar.toggledMarked.connect(() => {
			m_content.toggleMarkedSelectedArticle();
		});

		m_headerbar.toggledRead.connect(() => {
			m_content.toggleReadSelectedArticle();
		});

		m_simpleHeader = new SimpleHeader();

		m_content.showArticleButtons.connect((show) => {
			m_headerbar.showArticleButtons(show);
		});


		if(settings_state.get_boolean("window-maximized"))
		{
			logger.print(LogMessage.DEBUG, "MainWindow: maximize");
			this.maximize();
		}

		this.window_state_event.connect(onStateEvent);

		this.key_press_event.connect(shortcuts);
		this.add(m_stack);
		this.set_events(Gdk.EventMask.KEY_PRESS_MASK);
		this.set_titlebar(m_simpleHeader);
		this.set_title ("FeedReader");
		this.set_default_size(settings_state.get_int("window-width"), settings_state.get_int("window-height"));
		this.show_all();

		logger.print(LogMessage.DEBUG, "MainWindow: determining state");
		try
		{
			if(feedDaemon_interface.isOnline() && !settings_state.get_boolean("spring-cleaning"))
			{
				loadContent();
			}
			else
			{
				if(settings_state.get_boolean("spring-cleaning"))
				{
					showSpringClean();
				}
				else if(!dataBase.isEmpty())
				{
					showOfflineContent();
				}
				else
				{
					showLogin();
				}
			}
		}
		catch(GLib.Error e)
		{
			logger.print(LogMessage.ERROR, "MainWindow.constructor: %s".printf(e.message));
		}
	}

	private bool onStateEvent(Gdk.EventWindowState event)
	{
		base.window_state_event(event);

		if(event.type == Gdk.EventType.WINDOW_STATE)
		{
			if(event.changed_mask == Gdk.WindowState.FULLSCREEN)
			{
				if(m_content.getSelectedArticle() == ""
				|| m_content.getSelectedArticle() == "empty")
					return true;

				if(m_content.isFullscreenVideo())
					return true;

				if((event.new_window_state & Gdk.WindowState.FULLSCREEN) == Gdk.WindowState.FULLSCREEN)
					m_content.enterFullscreen(false);
				else
					m_content.leaveFullscreen(false);
			}
		}
		return false;
	}

	private void showSettings(string panel)
	{
		var settings = new SettingsDialog(this, panel);

		settings.newFeedList.connect(m_content.newFeedList);
		settings.newArticleList.connect(m_content.newArticleList);
		settings.reloadArticleView.connect(m_content.reloadArticleView);
		settings.reloadCSS.connect(reloadCSS);
	}

	public void setRefreshButton(bool refreshing)
	{
		m_headerbar.setRefreshButton(refreshing);
	}

	public void showOfflineContent()
	{
		showContent();
		m_content.setOffline();
	}

	public void showContent(Gtk.StackTransitionType transition = Gtk.StackTransitionType.CROSSFADE, bool noNewFeedList = false)
	{
		logger.print(LogMessage.DEBUG, "MainWindow: show content");
		if(!noNewFeedList)
			m_content.newFeedList();
		m_stack.set_visible_child_full("content", transition);
		m_headerbar.setButtonsSensitive(true);
		m_content.updateAccountInfo();

		if(!m_content.isFullscreen())
		{
			m_headerbar.show_all();
			this.set_titlebar(m_headerbar);
		}
	}

	private void showLogin(Gtk.StackTransitionType transition = Gtk.StackTransitionType.CROSSFADE)
	{
		logger.print(LogMessage.DEBUG, "MainWindow: show login");
		showErrorBar(LoginResponse.FIRST_TRY);
		m_login.reset();
		m_stack.set_visible_child_full("login", transition);
		m_headerbar.setButtonsSensitive(false);
		this.set_titlebar(m_simpleHeader);
	}

	private void showReset(Gtk.StackTransitionType transition = Gtk.StackTransitionType.CROSSFADE)
	{
		logger.print(LogMessage.DEBUG, "MainWindow: show reset");
		m_stack.set_visible_child_full("reset", transition);
		m_headerbar.setButtonsSensitive(false);
		this.set_titlebar(m_simpleHeader);
	}

	public void showSpringClean(Gtk.StackTransitionType transition = Gtk.StackTransitionType.CROSSFADE)
	{
		logger.print(LogMessage.DEBUG, "MainWindow: show springClean");
		m_stack.set_visible_child_full("springClean", transition);
		m_headerbar.setButtonsSensitive(false);
		this.set_titlebar(m_simpleHeader);
	}

	private void onClose()
	{
		this.delete_event.connect(() => {
			int windowWidth = 0;
			int windowHeight = 0;
			this.get_size(out windowWidth, out windowHeight);
			settings_state.set_int("window-width", windowWidth);
			settings_state.set_int("window-height", windowHeight);
			settings_state.set_boolean("window-maximized", this.is_maximized);

			return false;
		});

		this.destroy.connect(() => {
			if(settings_state.get_boolean("spring-cleaning"))
				return;

			int offset = 0;
			double scrollPos = 0.0;
			m_content.getArticleListState(out scrollPos, out offset);

			settings_state.set_strv("expanded-categories", m_content.getExpandedCategories());
			settings_state.set_double("feed-row-scrollpos",  m_content.getFeedListScrollPos());
			settings_state.set_string("feedlist-selected-row", m_content.getSelectedFeedListRow());
			settings_state.set_int("feed-row-width", m_content.getFeedListWidth());
			settings_state.set_int("feeds-and-articles-width", m_content.getArticlePlusFeedListWidth());
			settings_state.set_int("articlelist-row-offset", offset);
			settings_state.set_double("articlelist-scrollpos",  scrollPos);
			settings_state.set_string("articlelist-selected-row", m_content.getSelectedArticle());
			settings_state.set_enum("show-articles", m_headerbar.getArticleListState());
			settings_state.set_boolean("no-animations", true);
			settings_state.set_string("search-term", m_headerbar.getSearchTerm());
			settings_state.set_int("articleview-scrollpos", m_content.getArticleViewScrollPos());
			settings_state.set_int("articlelist-new-rows", 0);
		});
	}

	public InterfaceState getInterfaceState()
	{
		int windowWidth = 0;
		int windowHeight = 0;
		this.get_size(out windowWidth, out windowHeight);

		int offset = 0;
		double scrollPos = 0.0;
		m_content.getArticleListState(out scrollPos, out offset);

		var state = new InterfaceState();
		state.setWindowSize(windowHeight, windowWidth);
		state.setFeedsAndArticleWidth(m_content.getArticlePlusFeedListWidth());
		state.setFeedListWidth(m_content.getFeedListWidth());
		state.setFeedListScrollPos(m_content.getFeedListScrollPos());
		state.setArticleViewScrollPos(m_content.getArticleViewScrollPos());
		state.setArticleListScrollPos(scrollPos);
		state.setArticleListRowOffset(offset);
		state.setArticleListSelectedRow(m_content.getSelectedArticle());
		state.setArticleListNewRowCount(0);
		state.setWindowMaximized(this.is_maximized);
		state.setSearchTerm(m_headerbar.getSearchTerm());
		state.setFeedListSelectedRow(m_content.getSelectedFeedListRow());
		state.setExpandedCategories(m_content.getExpandedCategories());
		state.setArticleListState(m_headerbar.getArticleListState());

		return state;
	}

	public void writeInterfaceState()
	{
		getInterfaceState().write();
	}

	private void reloadCSS()
	{
		logger.print(LogMessage.DEBUG, "MainWindow: reloadCSS");
		removeProvider(m_cssProvider);
		setupCSS();
	}

	private void setupCSS()
	{
		logger.print(LogMessage.DEBUG, "MainWindow: setupCSS");
		string path = InstallPrefix + "/share/FeedReader/gtk-css/";

		addProvider(path + "basics.css");

		FeedListTheme theme = (FeedListTheme)settings_general.get_enum("feedlist-theme");

		switch(theme)
		{
			case FeedListTheme.GTK:
				m_cssProvider = addProvider(path + "gtk.css");
				break;

			case FeedListTheme.DARK:
				m_cssProvider = addProvider(path + "dark.css");
				break;

			case FeedListTheme.ELEMENTARY:
				m_cssProvider = addProvider(path + "elementary.css");
				break;
		}
	}

	private Gtk.CssProvider? addProvider(string path)
	{
		try
		{
    		Gtk.CssProvider provider = new Gtk.CssProvider();
			provider.load_from_path(path);
			weak Gdk.Display display = Gdk.Display.get_default();
            weak Gdk.Screen screen = display.get_default_screen();
			Gtk.StyleContext.add_provider_for_screen(screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			return provider;
		}
		catch (Error e)
		{
			logger.print(LogMessage.WARNING, e.message);
		}

		return null;
	}

	private void removeProvider(Gtk.CssProvider provider)
	{
		weak Gdk.Display display = Gdk.Display.get_default();
        weak Gdk.Screen screen = display.get_default_screen();
		Gtk.StyleContext.remove_provider_for_screen(screen, provider);
	}

	private void setupLoginPage()
	{
		m_error_bar = new Gtk.InfoBar();
		m_error_bar.no_show_all = true;
		var error_content = m_error_bar.get_content_area();
		m_ErrorMessage = new Gtk.Label("");
		error_content.add(m_ErrorMessage);
		m_error_bar.set_message_type(Gtk.MessageType.WARNING);
		m_error_bar.set_show_close_button(true);

		m_ignore_tls_errors = m_error_bar.add_button("Ignore", Gtk.ResponseType.APPLY);
		m_ignore_tls_errors.get_style_context().add_class(Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
		m_ignore_tls_errors.set_tooltip_text(_("Ignore all tls errors from now on"));
		m_ignore_tls_errors.set_visible(false);

		m_error_bar.response.connect((response_id) => {
			switch(response_id)
			{
				case Gtk.ResponseType.CLOSE:
					m_error_bar.set_visible(false);
					break;
				case Gtk.ResponseType.APPLY:
					settings_tweaks.set_boolean("ignore-tls-errors", true);
					m_ignore_tls_errors.set_visible(false);
					m_error_bar.set_visible(false);
					m_login.writeLoginData();
					break;
			}
		});

		m_login = new LoginPage();

		var loginBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

		loginBox.pack_start(m_error_bar, false, false, 0);
		loginBox.pack_start(m_login, true, true, 0);

		m_login.submit_data.connect(login);
		m_login.loginError.connect((errorCode) => {
			showErrorBar(errorCode);
		});
		m_stack.add_named(loginBox, "login");
		m_error_bar.set_visible(false);
	}

	private void login()
	{
		settings_state.set_strv("expanded-categories", Utils.getDefaultExpandedCategories());
		settings_state.set_string("feedlist-selected-row", "feed -4");
		try
		{
			if(dataBase.isEmpty())
				feedDaemon_interface.startInitSync();
			else
				feedDaemon_interface.startSync();
		}
		catch(GLib.Error e)
		{
			logger.print(LogMessage.ERROR, "MainWindow.login: %s".printf(e.message));
		}
		showContent(Gtk.StackTransitionType.SLIDE_RIGHT);
	}

	private void setupResetPage()
	{
		var reset = new ResetPage();
		m_stack.add_named(reset, "reset");
		reset.cancel.connect(() => {
			showContent(Gtk.StackTransitionType.SLIDE_RIGHT);
		});
		reset.reset.connect(() => {
			showLogin(Gtk.StackTransitionType.SLIDE_LEFT);
		});
	}

	private void setupSpringCleanPage()
	{
		m_SpringClean = new SpringCleanPage();
		m_stack.add_named(m_SpringClean, "springClean");
	}

	private void setupContentPage()
	{
		m_content = new ContentPage();
		m_stack.add_named(m_content, "content");

		m_content.panedPosChange.connect((pos) => {
        	m_headerbar.set_position(pos);
        });
	}

	private void showErrorBar(int ErrorCode)
	{
		logger.print(LogMessage.DEBUG, "MainWindow: show error bar - errorCode = " + ErrorCode.to_string());
		switch(ErrorCode)
		{
			case LoginResponse.NO_BACKEND:
				m_ErrorMessage.set_label(_("Please select a service first"));
				break;
			case LoginResponse.MISSING_USER:
				m_ErrorMessage.set_label(_("Please enter a valid username"));
				break;
			case LoginResponse.MISSING_PASSWD:
				m_ErrorMessage.set_label(_("Please enter a valid password"));
				break;
			case LoginResponse.MISSING_URL:
				m_ErrorMessage.set_label(_("Please enter a valid URL"));
				break;
			case LoginResponse.ALL_EMPTY:
				m_ErrorMessage.set_label(_("Please enter your Login details"));
				break;
			case LoginResponse.UNKNOWN_ERROR:
				m_ErrorMessage.set_label(_("Sorry, something went wrong."));
				break;
			case LoginResponse.WRONG_LOGIN:
				m_ErrorMessage.set_label(_("Either your username or the password are not correct."));
				break;
			case LoginResponse.NO_CONNECTION:
				m_ErrorMessage.set_label(_("No connection to the server. Check your internet connection and the server URL!"));
				break;
			case LoginResponse.NO_API_ACCESS:
				m_ErrorMessage.set_label(_("API access is disabled on the server. Please enable it first!"));
				break;
			case LoginResponse.UNAUTHORIZED:
				m_ErrorMessage.set_label(_("Not authorized to access URL"));
				m_login.showHtAccess();
				break;
			case LoginResponse.CA_ERROR:
				m_ErrorMessage.set_label(_("No valid CA certificate available!"));
				m_ignore_tls_errors.set_visible(true);
				break;
			case LoginResponse.PLUGIN_NEEDED:
				m_ErrorMessage.set_label(_("Please install the \"api_feedreader\"-plugin on your tt-rss instance!"));
				m_ignore_tls_errors.set_visible(true);
				break;
			case LoginResponse.SUCCESS:
			case LoginResponse.FIRST_TRY:
			default:
				logger.print(LogMessage.DEBUG, "MainWindow: dont show error bar");
				m_error_bar.set_visible(false);
				return;
		}

		logger.print(LogMessage.DEBUG, "MainWindow: show error bar");
		m_error_bar.set_visible(true);
		m_ErrorMessage.show();
	}

	private void loadContent()
	{
		logger.print(LogMessage.DEBUG, "MainWindow: load content");
		dataBase.updateBadge.connect(() => {
			try
			{
				feedDaemon_interface.updateBadge();
			}
			catch(Error e)
			{
				logger.print(LogMessage.ERROR, "MainWindow.loadContent: %s".printf(e.message));
			}

		});

		showContent(Gtk.StackTransitionType.NONE);
	}

	private void markSelectedRead()
	{
		try
		{
			m_content.markAllArticlesAsRead();
			string[] selectedRow = m_content.getSelectedFeedListRow().split(" ", 2);

			if(selectedRow[0] == "feed")
			{
				if(selectedRow[1] == FeedID.ALL.to_string())
				{
					var categories = dataBase.read_categories();
					foreach(category cat in categories)
					{
						feedDaemon_interface.markFeedAsRead(cat.getCatID(), true);
						logger.print(LogMessage.DEBUG, "MainWindow: mark all articles as read cat: %s".printf(cat.getTitle()));
					}

					var feeds = dataBase.read_feeds_without_cat();
					foreach(feed Feed in feeds)
					{
						feedDaemon_interface.markFeedAsRead(Feed.getFeedID(), false);
						logger.print(LogMessage.DEBUG, "MainWindow: mark all articles as read feed: %s".printf(Feed.getTitle()));
					}
				}
				else
				{
					feedDaemon_interface.markFeedAsRead(selectedRow[1], false);
				}
			}
			else if(selectedRow[0] == "cat")
			{
				feedDaemon_interface.markFeedAsRead(selectedRow[1], true);
			}
		}
		catch(GLib.Error e)
		{
			logger.print(LogMessage.ERROR, "MainWindow.markSelectedRead: %s".printf(e.message));
		}
	}


	private bool checkShortcut(Gdk.EventKey event, string gsettingKey)
	{
		uint? key;
		Gdk.ModifierType? mod;
		string setting = settings_keybindings.get_string(gsettingKey);
		Gtk.accelerator_parse(setting, out key, out mod);

		if(key != null && Gdk.keyval_to_lower(event.keyval) == key)
		{
			if(mod == null && event.state == 0)
			{
				return true;
			}
			else
			{
				if((event.state & mod) == mod)
					return true;
			}
		}

		return false;
	}

	private bool shortcuts(Gdk.EventKey event)
	{
		if(m_stack.get_visible_child_name() != "content")
			return false;

		if(m_headerbar.searchFocused())
			return false;

		if(checkShortcut(event, "articlelist-prev"))
		{
			logger.print(LogMessage.DEBUG, "shortcut: down");
			m_content.ArticleListPREV();
			return true;
		}

		if(checkShortcut(event, "articlelist-next"))
		{
			logger.print(LogMessage.DEBUG, "shortcut: up");
			m_content.ArticleListNEXT();
			return true;
		}

		if(event.keyval == Gdk.Key.Left || event.keyval == Gdk.Key.Right)
		{
			if(m_content.isFullscreen())
			{
				if(event.keyval == Gdk.Key.Left)
					m_content.ArticleListPREV();
				else
					m_content.ArticleListNEXT();

				return true;
			}
			else
				return false;
		}

		if(checkShortcut(event, "articlelist-toggle-read"))
		{
			logger.print(LogMessage.DEBUG, "shortcut: toggle read");
			m_content.toggleReadSelectedArticle();
			m_headerbar.toggleRead();
			return true;
		}

		if(checkShortcut(event, "articlelist-toggle-marked"))
		{
			logger.print(LogMessage.DEBUG, "shortcut: toggle marked");
			m_content.toggleMarkedSelectedArticle();
			m_headerbar.toggleMarked();
			return true;
		}

		if(checkShortcut(event, "articlelist-open-url"))
		{
			logger.print(LogMessage.DEBUG, "shortcut: open in browser");
			m_content.openSelectedArticle();
			return true;
		}

		if(checkShortcut(event, "feedlist-mark-read"))
		{
			logger.print(LogMessage.DEBUG, "shortcut: mark all as read");
			markSelectedRead();
			m_headerbar.setRead(false);
			return true;
		}

		if(checkShortcut(event, "global-sync"))
		{
			logger.print(LogMessage.DEBUG, "shortcut: sync");
			var window = ((FeedApp)GLib.Application.get_default());
			window.sync.begin((obj, res) => {
				window.sync.end(res);
			});
			return true;
		}

		if(checkShortcut(event, "articlelist-center-selected"))
		{
			logger.print(LogMessage.DEBUG, "shortcut: scroll to selcted row");
			m_content.centerSelectedRow();
			return true;
		}

		if(checkShortcut(event, "global-search"))
		{
			logger.print(LogMessage.DEBUG, "shortcut: focus search");
			m_headerbar.focusSearch();
			return true;
		}

		if(checkShortcut(event, "global-quit"))
		{
			logger.print(LogMessage.DEBUG, "shortcut: quit");
			this.close();
			return true;
		}

		if(event.keyval == Gdk.Key.Escape && m_content.isFullscreen())
		{
			this.unfullscreen();
			m_content.leaveFullscreen(false);
			return true;
		}

		if(event.keyval == Gdk.Key.F1)
		{
			logger.print(LogMessage.DEBUG, "shortcut: showShortcutWindow");
			showShortcutWindow();
			return true;
		}

		return false;
	}

	private void showShortcutWindow()
	{
		new ShortcutsWindow(this);
	}


	public bool searchFocused()
	{
		return m_headerbar.searchFocused();
	}

	public ContentPage getContent()
	{
		return m_content;
	}

	public readerHeaderbar getHeaderBar()
	{
		return m_headerbar;
	}

	public SimpleHeader getSimpleHeader()
	{
		return m_simpleHeader;
	}

	public void setOffline()
	{
		m_content.setOffline();
		m_headerbar.setOffline();
	}

	public void setOnline()
	{
		m_content.setOnline();
		m_headerbar.setOnline();
	}

}
