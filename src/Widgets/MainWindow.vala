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

public class FeedReader.MainWindow : Gtk.ApplicationWindow
{
private SimpleHeader m_simpleHeader;
private Gtk.Overlay m_overlay;
private Gtk.Stack m_stack;
private Gtk.Label m_ErrorMessage;
private Gtk.InfoBar m_error_bar;
private Gtk.Button m_ignore_tls_errors;
private LoginPage m_login;
private SpringCleanPage m_SpringClean;
private Gtk.CssProvider m_cssProvider;
private uint m_stackTransitionTime = 100;

private static MainWindow? m_window = null;

public static MainWindow get_default()
{
	if(m_window == null)
		m_window = new MainWindow();

	return m_window;
}

private MainWindow()
{
	Object(application: FeedReaderApp.get_default(), title: _("FeedReader"), show_menubar: false);
	this.window_position = WindowPosition.CENTER;

	m_stack = new Gtk.Stack();
	m_stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
	m_stack.set_transition_duration(m_stackTransitionTime);

	m_overlay = new Gtk.Overlay();
	m_overlay.add(m_stack);

	setupCSS();
	setupLoginPage();
	setupResetPage();
	setupContentPage();
	setupSpringCleanPage();

	var shortcutsAction = new SimpleAction("shortcuts", null);
	shortcutsAction.activate.connect(showShortcutWindow);
	this.add_action(shortcutsAction);
	shortcutsAction.set_enabled(true);

	var reportBugAction = new SimpleAction("bugs", null);
	reportBugAction.activate.connect(() => {
			try{
			        Gtk.show_uri_on_window(this, "https://github.com/jangernert/FeedReader/issues", Gdk.CURRENT_TIME);
			}
			catch(GLib.Error e) {
			        Logger.debug("could not open the link in an external browser: %s".printf(e.message));
			}
		});
	this.add_action(reportBugAction);
	reportBugAction.set_enabled(true);

	var bountyAction = new SimpleAction("bounty", null);
	bountyAction.activate.connect(() => {
			try{
			        Gtk.show_uri_on_window(this, "https://www.bountysource.com/teams/jangernert-feedreader/issues", Gdk.CURRENT_TIME);
			}
			catch(GLib.Error e) {
			        Logger.debug("could not open the link in an external browser: %s".printf(e.message));
			}
		});
	this.add_action(bountyAction);
	bountyAction.set_enabled(true);

	var settingsAction = new SimpleAction("settings", null);
	settingsAction.activate.connect(() => {
			SettingsDialog.get_default().showDialog("ui");
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

	m_simpleHeader = new SimpleHeader();

	if(Settings.state().get_boolean("window-maximized"))
	{
		Logger.debug("MainWindow: maximize");
		this.maximize();
	}

	this.window_state_event.connect(onStateEvent);
	this.key_press_event.connect(shortcuts);
	this.add(m_overlay);
	this.set_events(Gdk.EventMask.KEY_PRESS_MASK);
	this.set_titlebar(m_simpleHeader);
	this.set_title("FeedReader");
	this.set_default_size(Settings.state().get_int("window-width"), Settings.state().get_int("window-height"));
	this.show_all();

	Logger.debug("MainWindow: determining state");
	if(FeedReaderBackend.get_default().isOnline())
	{
		loadContent();
	}
	else if(!DataBase.readOnly().isEmpty())
	{
		showOfflineContent();
	}
	else
	{
		showLogin();
	}
}

public override bool delete_event(Gdk.EventAny event)
{
	this.hide();
	return true;
}

private bool onStateEvent(Gdk.EventWindowState event)
{
	if(event.type == Gdk.EventType.WINDOW_STATE)
	{
		if(event.changed_mask == Gdk.WindowState.FULLSCREEN)
		{
			Logger.debug("MainWindow: fullscreen event");
			if(ColumnView.get_default().getSelectedArticle() == null)
				return true;

			if(ColumnView.get_default().isFullscreenVideo())
			{
				if((event.new_window_state & Gdk.WindowState.FULLSCREEN) != Gdk.WindowState.FULLSCREEN)
					ColumnView.get_default().exitFullscreenVideo();

				base.window_state_event(event);
				return true;
			}


			if((event.new_window_state & Gdk.WindowState.FULLSCREEN) == Gdk.WindowState.FULLSCREEN)
			{
				Logger.debug("MainWindow: fullscreen event");
				ColumnView.get_default().hidePane();
				ColumnView.get_default().enterFullscreenArticle();
			}
			else
			{
				ColumnView.get_default().showPane();
				ColumnView.get_default().leaveFullscreenArticle();
			}
		}
	}

	base.window_state_event(event);
	return false;
}

public void showOfflineContent()
{
	showContent();
	ColumnView.get_default().setOffline();
}

public void showContent(Gtk.StackTransitionType transition = Gtk.StackTransitionType.CROSSFADE, bool noNewFeedList = false)
{
	Logger.debug("MainWindow: show content");
	if(!noNewFeedList)
		ColumnView.get_default().newFeedList();
	m_stack.set_visible_child_full("content", transition);
	ColumnView.get_default().getHeader().setButtonsSensitive(true);

	if(!ColumnView.get_default().isFullscreen())
	{
		ColumnView.get_default().getHeader().show_all();
		this.set_titlebar(ColumnView.get_default().getHeader());
	}
}

private void showLogin(Gtk.StackTransitionType transition = Gtk.StackTransitionType.CROSSFADE)
{
	Logger.debug("MainWindow: show login");
	showErrorBar(LoginResponse.FIRST_TRY);
	m_login.reset();
	m_stack.set_visible_child_full("login", transition);
	ColumnView.get_default().getHeader().setButtonsSensitive(false);
	this.set_titlebar(m_simpleHeader);
}

private void showReset(Gtk.StackTransitionType transition = Gtk.StackTransitionType.CROSSFADE)
{
	Logger.debug("MainWindow: show reset");

	// kill playing media
	ColumnView.get_default().articleViewKillMedia();

	m_stack.set_visible_child_full("reset", transition);
	ColumnView.get_default().getHeader().setButtonsSensitive(false);
	this.set_titlebar(m_simpleHeader);
}

public void showSpringClean(Gtk.StackTransitionType transition = Gtk.StackTransitionType.CROSSFADE)
{
	Logger.debug("MainWindow: show springClean");
	m_stack.set_visible_child_full("springClean", transition);
	ColumnView.get_default().getHeader().setButtonsSensitive(false);
	this.set_titlebar(m_simpleHeader);
}

public InterfaceState getInterfaceState()
{
	int windowWidth = 0;
	int windowHeight = 0;
	this.get_size(out windowWidth, out windowHeight);

	var state = new InterfaceState();
	state.setWindowSize(windowHeight, windowWidth);
	state.setWindowMaximized(this.is_maximized);
	ColumnView.get_default().saveState(ref state);
	return state;
}

public void writeInterfaceState(bool shutdown = false)
{
	getInterfaceState().write(shutdown);
}

public void reloadCSS()
{
	Logger.debug("MainWindow: reloadCSS");
	removeProvider(m_cssProvider);
	setupCSS();
}

private void setupCSS()
{
	Logger.debug("MainWindow: setupCSS");
	string path = "/org/gnome/FeedReader/gtk-css/";

	addProvider(path + "basics.css");

	FeedListTheme theme = (FeedListTheme)Settings.general().get_enum("feedlist-theme");

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
	Gtk.CssProvider provider = new Gtk.CssProvider();
	provider.load_from_resource(path);
	weak Gdk.Display display = Gdk.Display.get_default();
	weak Gdk.Screen screen = display.get_default_screen();
	Gtk.StyleContext.add_provider_for_screen(screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
	return provider;
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
	m_ignore_tls_errors.set_tooltip_text(_("Ignore all TLS errors from now on"));
	m_ignore_tls_errors.set_visible(false);

	m_error_bar.response.connect((response_id) => {
			switch(response_id)
			{
			case Gtk.ResponseType.CLOSE:
				m_error_bar.set_visible(false);
				break;
			case Gtk.ResponseType.APPLY:
				Settings.tweaks().set_boolean("ignore-tls-errors", true);
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

	m_login.submit_data.connect(() => {
			Settings.state().set_strv("expanded-categories", Utils.getDefaultExpandedCategories());
			Settings.state().set_string("feedlist-selected-row", "feed -4");
			showContent(Gtk.StackTransitionType.SLIDE_RIGHT);
			ColumnView.get_default().setOnline();
		});
	m_login.loginError.connect((errorCode) => {
			showErrorBar(errorCode);
		});
	m_stack.add_named(loginBox, "login");
	m_error_bar.set_visible(false);
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
	m_stack.add_named(ColumnView.get_default(), "content");
}

private void showErrorBar(int ErrorCode)
{
	Logger.debug("MainWindow: show error bar - errorCode = " + ErrorCode.to_string());
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
	case LoginResponse.INVALID_URL:
	case LoginResponse.MISSING_URL:
		m_ErrorMessage.set_label(_("Please enter a valid URL"));
		break;
	case LoginResponse.ALL_EMPTY:
		m_ErrorMessage.set_label(_("Please enter your Login details"));
		break;
	case LoginResponse.UNKNOWN_ERROR:
		m_ErrorMessage.set_label(_("Sorry, something went wrong."));
		break;
	case LoginResponse.API_ERROR:
		m_ErrorMessage.set_label(_("The server reported an API-error."));
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
		Logger.debug("MainWindow: dont show error bar");
		m_error_bar.set_visible(false);
		return;
	}

	Logger.debug("MainWindow: show error bar");
	m_error_bar.set_visible(true);
	m_ErrorMessage.show();
}

private void loadContent()
{
	Logger.debug("MainWindow: load content");
	m_stack.set_transition_duration(0);
	showContent(Gtk.StackTransitionType.NONE);
	m_stack.set_transition_duration(m_stackTransitionTime);
}

private void markSelectedRead()
{
	ColumnView.get_default().markAllArticlesAsRead();
	string[] selectedRow = ColumnView.get_default().getSelectedFeedListRow().split(" ", 2);

	if(selectedRow[0] == "feed")
	{
		if(selectedRow[1] == FeedID.ALL.to_string())
		{
			var categories = DataBase.readOnly().read_categories();
			foreach(Category cat in categories)
			{
				FeedReaderBackend.get_default().markFeedAsRead(cat.getCatID(), true);
				Logger.debug("MainWindow: mark all articles as read cat: %s".printf(cat.getTitle()));
			}

			var feeds = DataBase.readOnly().read_feeds_without_cat();
			foreach(Feed feed in feeds)
			{
				FeedReaderBackend.get_default().markFeedAsRead(feed.getFeedID(), false);
				Logger.debug("MainWindow: mark all articles as read feed: %s".printf(feed.getTitle()));
			}
		}
		else
		{
			FeedReaderBackend.get_default().markFeedAsRead(selectedRow[1], false);
		}
	}
	else if(selectedRow[0] == "cat")
	{
		FeedReaderBackend.get_default().markFeedAsRead(selectedRow[1], true);
	}
}


private bool checkShortcut(Gdk.EventKey event, string gsettingKey)
{
	uint? key;
	Gdk.ModifierType? mod;
	string setting = Settings.keybindings().get_string(gsettingKey);
	Gtk.accelerator_parse(setting, out key, out mod);

	if(key != null && Gdk.keyval_to_lower(event.keyval) == key)
	{
		if(mod == null || mod == 0)
		{
			if(event.state == 16
			   || event.state == 0)
				return true;
		}
		else if(mod in event.state)
		{
			return true;
		}
	}

	return false;
}

private bool shortcuts(Gdk.EventKey event)
{
	if(m_stack.get_visible_child_name() != "content")
		return false;

	if(ColumnView.get_default().searchFocused())
		return false;

	if(checkShortcut(event, "articlelist-prev"))
	{
		Logger.debug("shortcut: articlelist prev");
		ColumnView.get_default().ArticleListPREV();
		return true;
	}

	if(checkShortcut(event, "articlelist-next"))
	{
		Logger.debug("shortcut: articlelist next");
		ColumnView.get_default().ArticleListNEXT();
		return true;
	}

	if(checkShortcut(event, "feedlist-prev"))
	{
		Logger.debug("shortcut: feedlist prev");
		ColumnView.get_default().FeedListPREV();
		return true;
	}

	if(checkShortcut(event, "feedlist-next"))
	{
		Logger.debug("shortcut: feedlist next");
		ColumnView.get_default().FeedListNEXT();
		return true;
	}

	if(event.keyval == Gdk.Key.Left || event.keyval == Gdk.Key.Right)
	{
		if(ColumnView.get_default().isFullscreen())
		{
			if(event.keyval == Gdk.Key.Left)
				ColumnView.get_default().ArticleListPREV();
			else
				ColumnView.get_default().ArticleListNEXT();

			return true;
		}
		else
			return false;
	}

	if(checkShortcut(event, "articleview-up"))
	{
		event.keyval = Gdk.Key.Up;
		ColumnView.get_default().ArticleViewSendEvent(event);
		return true;
	}

	if(checkShortcut(event, "articleview-down"))
	{
		event.keyval = Gdk.Key.Down;
		ColumnView.get_default().ArticleViewSendEvent(event);
		return true;
	}

	if(checkShortcut(event, "articlelist-toggle-read"))
	{
		Logger.debug("shortcut: toggle read");
		ColumnView.get_default().toggleReadSelectedArticle();
		return true;
	}

	if(checkShortcut(event, "articlelist-toggle-marked"))
	{
		Logger.debug("shortcut: toggle marked");
		ColumnView.get_default().toggleMarkedSelectedArticle();
		return true;
	}

	if(checkShortcut(event, "articlelist-open-url"))
	{
		Logger.debug("shortcut: open in browser");
		ColumnView.get_default().openSelectedArticle();
		return true;
	}

	if(checkShortcut(event, "feedlist-mark-read"))
	{
		Logger.debug("shortcut: mark all as read");
		markSelectedRead();
		return true;
	}

	if(checkShortcut(event, "global-sync"))
	{
		Logger.debug("shortcut: sync");
		var app = FeedReaderApp.get_default();
		app.sync();
		return true;
	}

	if(checkShortcut(event, "articlelist-center-selected"))
	{
		Logger.debug("shortcut: scroll to selcted row");
		ColumnView.get_default().centerSelectedRow();
		return true;
	}

	if(checkShortcut(event, "global-search"))
	{
		Logger.debug("shortcut: focus search");
		ColumnView.get_default().getHeader().focusSearch();
		return true;
	}

	if(checkShortcut(event, "global-quit"))
	{
		Logger.debug("shortcut: quit");
		FeedReaderApp.get_default().activate_action("quit", null);
		return true;
	}

	if(event.keyval == Gdk.Key.Escape && ColumnView.get_default().isFullscreen())
	{
		this.unfullscreen();
		ColumnView.get_default().showPane();
		ColumnView.get_default().leaveFullscreenArticle();
		return true;
	}

	if(checkShortcut(event, "global-help"))
	{
		Logger.debug("shortcut: showShortcutWindow");
		showShortcutWindow();
		return true;
	}

	return false;
}

private void showShortcutWindow()
{
	new ShortcutsWindow(this);
}

public SimpleHeader getSimpleHeader()
{
	return m_simpleHeader;
}

public InAppNotification showNotification(string message, string buttonText = "undo")
{
	var notification = new InAppNotification(message, buttonText);
	m_overlay.add_overlay(notification);
	this.show_all();
	return notification;
}

}
