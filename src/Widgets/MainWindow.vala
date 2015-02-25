using GLib;
using Gtk;

public class FeedReader.readerUI : Gtk.ApplicationWindow 
{
	private readerHeaderbar m_headerbar;
	private Gtk.Stack m_stack;
	private Gtk.Label m_ErrorMessage;
	private Gtk.InfoBar m_error_bar;
	private ContentPage m_content;
	private InitSyncPage m_InitSync;
	private SimpleAction m_login_action;
	
	public readerUI(rssReaderApp app)
	{
		Object (application: app, title: _("FeedReader"));
		this.window_position = WindowPosition.CENTER;
		
		m_stack = new Gtk.Stack();
		m_stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		m_stack.set_transition_duration(100);
		
		
		setupLoginPage();
		setupInitSyncPage();
		setupResetPage();
		setupContentPage();
		onClose();
		
		m_headerbar = new readerHeaderbar();
		m_headerbar.refresh.connect(app.sync);
		m_headerbar.change_unread.connect((only_unread) => {
			m_content.setOnlyUnread(only_unread);
			m_content.clearArticleView();
			m_content.newHeadlineList();
		});

		m_headerbar.change_marked.connect((only_marked) => {
			m_content.setOnlyMarked(only_marked);
			m_content.clearArticleView();
			m_content.newHeadlineList(); 
		});
		
		m_headerbar.search_term.connect((searchTerm) => {
			m_content.setSearchTerm(searchTerm);
			m_content.clearArticleView();
			m_content.newHeadlineList();
		});
		
		
		var about_action = new SimpleAction (_("about"), null);
		about_action.activate.connect (this.about);
		add_action(about_action);

		m_login_action = new SimpleAction (_("reset"), null);
		m_login_action.activate.connect (() => {
			showReset(Gtk.StackTransitionType.SLIDE_RIGHT);
		});
		add_action(m_login_action);
		
		
		if(settings_state.get_boolean("window-maximized"))
		{
			logger.print(LogMessage.DEBUG, "MainWindow: maximize");
			this.maximize();
		}
		
		
		this.add(m_stack);
		this.set_events(Gdk.EventMask.KEY_PRESS_MASK);
		this.set_titlebar(m_headerbar);
		this.set_title ("FeedReader");
		this.set_default_size(settings_state.get_int("window-width"), settings_state.get_int("window-height"));
		this.show_all();
		
		if(feedDaemon_interface.isLoggedIn() == LoginResponse.SUCCESS)
		{
			loadContent();
		}
		else
		{
			if(feedDaemon_interface.login(settings_general.get_enum("account-type")) == LoginResponse.SUCCESS)
			{
				loadContent();
			}
			else
			{
				showLogin();
			}
		}
	}

	public void setRefreshButton(bool refreshing)
	{
		m_headerbar.setRefreshButton(refreshing);
	}
	
	public bool currentlyUpdating()
	{
		return m_headerbar.currentlyUpdating();
	}
	
	public void showContent(Gtk.StackTransitionType transition = Gtk.StackTransitionType.CROSSFADE)
	{
		if(m_stack.get_visible_child_name() == "initsync")
			m_content.newFeedList();
		
		logger.print(LogMessage.DEBUG, "MainWindow: show content");
		m_stack.set_visible_child_full("content", transition);
		
		if(!settings_state.get_boolean("currently-updating"))
			m_headerbar.setButtonsSensitive(true);
			
		m_login_action.set_enabled(true);
	}
	
	private void showLogin(Gtk.StackTransitionType transition = Gtk.StackTransitionType.CROSSFADE)
	{
		logger.print(LogMessage.DEBUG, "MainWindow: show login");
		showErrorBar(LoginResponse.FIRST_TRY);
		m_stack.set_visible_child_full("login", transition);
		m_headerbar.setButtonsSensitive(false);
		m_login_action.set_enabled(false);
	}
	
	private void showReset(Gtk.StackTransitionType transition = Gtk.StackTransitionType.CROSSFADE)
	{
		logger.print(LogMessage.DEBUG, "MainWindow: show reset");
		m_stack.set_visible_child_full("reset", transition);
		m_headerbar.setButtonsSensitive(false);
		m_login_action.set_enabled(false);
	}
	
	private void showWebLogin(Gtk.StackTransitionType transition = Gtk.StackTransitionType.CROSSFADE)
	{
		logger.print(LogMessage.DEBUG, "MainWindow: show weblogin");
		m_stack.set_visible_child_full("WebLogin", transition);
		m_headerbar.setButtonsSensitive(false);
		m_login_action.set_enabled(false);
	}
	
	private void showInitSync(Gtk.StackTransitionType transition = Gtk.StackTransitionType.CROSSFADE)
	{
		logger.print(LogMessage.DEBUG, "MainWindow: show initsync");
		m_stack.set_visible_child_full("initsync", transition);
		m_headerbar.setButtonsSensitive(false);
		m_login_action.set_enabled(false);
		m_InitSync.start();
	}
	
	private void onClose()
	{
		
		
		this.delete_event.connect(() => {
			int windowWidth = 0;
			int windowHeight = 0;
			this.get_size(out windowWidth, out windowHeight);
			logger.print(LogMessage.DEBUG, "width: %i".printf(windowWidth));
			logger.print(LogMessage.DEBUG, "height: %i".printf(windowHeight));
			settings_state.set_int("window-width", windowWidth);
			settings_state.set_int("window-height", windowHeight);
			settings_state.set_boolean("window-maximized", this.is_maximized);
			
			return false;
		});
		
		
		this.destroy.connect(() => {
			int only_unread = 0;
			if(m_headerbar.getOnlyUnread()) only_unread = 1;
			int only_marked = 0;
			if(m_headerbar.getOnlyMarked()) only_marked = 1;
			
			
			settings_state.set_strv("expanded-categories", m_content.getExpandedCategories());
			settings_state.set_double("feed-row-scrollpos",  m_content.getFeedListScrollPos());
			settings_state.set_string("feedlist-selected-row", m_content.getSelectedFeedListRow());
			settings_state.set_int("feed-row-width", m_content.getFeedListWidth());
			settings_state.set_int("article-row-width", m_content.getArticleListWidth());
			settings_state.set_int("articlelist-row-amount", m_content.getArticlesToLoad());
			settings_state.set_double("articlelist-scrollpos",  m_content.getArticleListScrollPos());
			settings_state.set_string("articlelist-selected-row", m_content.getSelectedArticle());
			settings_state.set_double("articleview-scrollpos",  m_content.getArticleViewScrollPos());
			settings_state.set_int("articlelist-new-rows", 0);
			settings_state.set_boolean("only-unread", m_headerbar.getOnlyUnread());
			settings_state.set_boolean("only-marked", m_headerbar.getOnlyMarked());
			settings_state.set_boolean("no-animations", true);
			settings_state.set_string("search-term", m_headerbar.getSearchTerm());
		});
	}
	
	private void setupLoginPage()
	{
		m_error_bar = new Gtk.InfoBar();
		m_error_bar.set_visible(false);
		var error_content = m_error_bar.get_content_area();
		m_ErrorMessage = new Gtk.Label("");
		error_content.add(m_ErrorMessage);
		m_error_bar.set_message_type(Gtk.MessageType.WARNING);		
		m_error_bar.set_show_close_button(true);
		
		m_error_bar.response.connect((response_id) => {
			if(response_id == Gtk.ResponseType.CLOSE) {
					m_error_bar.set_visible(false);
			}
		});
		
		var login = new LoginPage();
		var WebLogin = new WebLoginPage();
		login.loadLoginPage.connect((type) => {
			WebLogin.loadPage(type);
			showWebLogin(Gtk.StackTransitionType.SLIDE_LEFT);
		});
		
		var loginBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		
		loginBox.pack_start(m_error_bar, false, false, 0);
		loginBox.pack_start(login, true, true, 0);
		
		login.submit_data.connect(() => {
			settings_state.set_strv("expanded-categories", m_content.getDefaultExpandedCategories());
			settings_state.set_string("feedlist-selected-row", "feed -4");
			showInitSync();
		});
		login.loginError.connect((errorCode) => {
			showErrorBar(errorCode);
		});
		WebLogin.success.connect(loadContent);
		m_stack.add_named(loginBox, "login");
		m_stack.add_named(WebLogin, "WebLogin");
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
	
	private void setupInitSyncPage()
	{
		m_InitSync = new InitSyncPage();
		m_stack.add_named(m_InitSync, "initsync");
	}
	
	private void setupContentPage()
	{
		m_content = new ContentPage();
		m_stack.add_named(m_content, "content");
	}
	
	private void showErrorBar(int ErrorCode)
	{
		logger.print(LogMessage.DEBUG, "MainWindow: show error bar - errorCode = %i".printf(ErrorCode));
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
			case LoginResponse.SUCCESS:
			case LoginResponse.FIRST_TRY:
			default:
				logger.print(LogMessage.DEBUG, "MainWindow: dont show error bar");
				m_error_bar.set_visible(false);
				return;
		}
		
		logger.print(LogMessage.DEBUG, "MainWindow: show error bar");
		m_error_bar.set_visible(true);
	}
	
	private void loadContent()
	{
		logger.print(LogMessage.DEBUG, "MainWindow: load content");
		m_content.newFeedList();
		dataBase.updateBadge.connect(() => {
			feedDaemon_interface.updateBadge();
		});
		
		showContent(Gtk.StackTransitionType.NONE);
	}


	public void updateFeedList()
	{
		m_content.updateFeedList();
	}
	
	public void updateFeedListCountUnread(string feedID, bool increase)
	{
		m_content.updateFeedListCountUnread(feedID, increase);
	}

	public void updateArticleList()
	{
		m_content.updateArticleList();
	}


	private void about() 
	{
		Gtk.show_about_dialog (this,
                               "program-name", AboutInfo.programmName,
                               "version", AboutInfo.version,
                               "copyright", AboutInfo.copyright,
                               "authors", AboutInfo.authors,
		                       "comments", AboutInfo.comments,
                               "documenters", AboutInfo.documenters,
		                       "license_type", Gtk.License.GPL_3_0,
		                       "logo_icon_name", "internet-news-reader",
                               null);
	}


	 
}
