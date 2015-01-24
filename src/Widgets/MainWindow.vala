using GLib;
using Gtk;

public class readerUI : Gtk.ApplicationWindow 
{
	private readerHeaderbar m_headerbar;
	private Gtk.Paned m_pane_feedlist;
	private Gtk.Paned m_pane_articlelist;
	private Gtk.Stack m_stack;
	private articleView m_article_view;
	private articleList m_articleList;
	private feedList m_feedList;
	private Gtk.Label m_ErrorMessage;
	private Gtk.InfoBar m_error_bar;
	
	public readerUI(rssReaderApp app)
	{
		Object (application: app, title: _("FeedReader"));
		this.window_position = WindowPosition.CENTER;
		

		m_headerbar = new readerHeaderbar();
		m_headerbar.refresh.connect(app.sync);
		m_headerbar.change_unread.connect((only_unread) => {
			m_articleList.setOnlyUnread(only_unread);
			m_articleList.newHeadlineList(); 
		});

		m_headerbar.change_marked.connect((only_marked) => {
			m_articleList.setOnlyMarked(only_marked);
			m_articleList.newHeadlineList(); 
		});
		
		m_headerbar.search_term.connect((searchTerm) => {
			m_articleList.setSearchTerm(searchTerm);
			m_articleList.newHeadlineList();
		});
		
		
		var about_action = new SimpleAction (_("about"), null);
		about_action.activate.connect (this.about);
		add_action(about_action);

		var login_action = new SimpleAction (_("login"), null);
		login_action.activate.connect (() => {
			m_stack.set_visible_child_full("login", Gtk.StackTransitionType.SLIDE_RIGHT);
		});
		add_action(login_action);

		m_stack = new Gtk.Stack();
		m_stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		m_stack.set_transition_duration(100);
		

		setupLoginPage();
		setupArticlelist();
		setupFeedlist();
		onClose();
		
		m_stack.add_named(m_pane_feedlist, "content");
		m_article_view = new articleView();
		m_pane_articlelist.pack2(m_article_view, true, false);
		
		this.add(m_stack);
		this.set_events(Gdk.EventMask.KEY_PRESS_MASK);
		this.set_titlebar(m_headerbar);
		this.set_title ("FeedReader");
		this.set_default_size(1600, 900);
		this.show_all();
		
		if(feedDaemon_interface.isLoggedIn() == LOGIN_SUCCESS)
		{
			m_stack.set_visible_child_name("content");
			loadContent();
		}
		else
		{
			if(feedDaemon_interface.login(settings_general.get_enum("account-type")) == LOGIN_SUCCESS)
			{
				m_stack.set_visible_child_name("content");
				loadContent();
			}
			else
			{
				m_stack.set_visible_child_name("login");
			}
		}
		
		m_error_bar.hide();
	}

	public void setRefreshButton(bool refreshing)
	{
		m_headerbar.setRefreshButton(refreshing);
	}
	
	public bool currentlyUpdating()
	{
		return m_headerbar.currentlyUpdating();
	}
	
	private void onClose()
	{
		this.destroy.connect(() => {
			int only_unread = 0;
			if(m_headerbar.m_only_unread) only_unread = 1;
			int only_marked = 0;
			if(m_headerbar.m_only_marked) only_marked = 1;
			
			
			settings_state.set_strv("expanded-categories", m_feedList.getExpandedCategories());
			settings_state.set_double("feed-row-scrollpos",  m_feedList.getScrollPos());
			settings_state.set_int("feed-row-width", m_pane_feedlist.get_position());
			settings_state.set_int("article-row-width", m_pane_articlelist.get_position());
			settings_state.set_boolean("only-unread", m_headerbar.m_only_unread);
			settings_state.set_boolean("only-marked", m_headerbar.m_only_marked);
		});
	}
	
	private void setupLoginPage()
	{
		m_error_bar = new Gtk.InfoBar();
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
			m_stack.set_visible_child_full("WebLogin", Gtk.StackTransitionType.SLIDE_LEFT);
		});
		
		var loginBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		
		loginBox.pack_start(m_error_bar, false, false, 0);
		loginBox.pack_start(login, true, true, 0);
		
		login.submit_data.connect(loadContent);
		login.loginError.connect((errorCode) => {
			showErrorBar(errorCode);
		});
		WebLogin.success.connect(loadContent);
		m_stack.add_named(loginBox, "login");
		m_stack.add_named(WebLogin, "WebLogin");
	}
	
	private void showErrorBar(int ErrorCode)
	{
		switch(ErrorCode)
		{
			case LOGIN_SUCCESS:
			case LOGIN_FIRST_TRY:
				break;
			case LOGIN_NO_BACKEND:
				m_ErrorMessage.set_label(_("Please select a service first"));
				break;
			case LOGIN_MISSING_USER:
				m_ErrorMessage.set_label(_("Please enter a valid username"));
				break;
			case LOGIN_MISSING_PASSWD:
				m_ErrorMessage.set_label(_("Please enter a valid password"));
				break;
			case LOGIN_MISSING_URL:
				m_ErrorMessage.set_label(_("Please enter a valid URL"));
				break;
			case LOGIN_ALL_EMPTY:
				m_ErrorMessage.set_label(_("Please enter your Login details"));
				break;
			case LOGIN_UNKNOWN_ERROR:
				m_ErrorMessage.set_label(_("Sorry, something went wrong."));
				break;
		}
		
		m_error_bar.show();
	}
	
	
	private void setupFeedlist()
	{
		int feed_row_width = settings_state.get_int("feed-row-width");
		m_pane_feedlist = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);
		m_pane_feedlist.set_position(feed_row_width);
		m_feedList = new feedList();
		m_pane_feedlist.pack1(m_feedList, false, false);
		m_pane_feedlist.pack2(m_pane_articlelist, true, false);

		m_feedList.newFeedSelected.connect((feedID) => {
			m_articleList.setSelectedType(FEEDLIST_FEED);
			m_article_view.clearContent();
			m_articleList.setSelectedFeed(feedID);
			m_articleList.newHeadlineList();
		});
		
		m_feedList.newTagSelected.connect((tagID) => {
			m_articleList.setSelectedType(FEEDLIST_TAG);
			m_article_view.clearContent();
			m_articleList.setSelectedFeed(tagID);
			m_articleList.newHeadlineList();
		});

		m_feedList.newCategorieSelected.connect((categorieID) => {
			m_articleList.setSelectedType(FEEDLIST_CATEGORY);
			m_article_view.clearContent();
			m_articleList.setSelectedFeed(categorieID);
			m_articleList.newHeadlineList();
		});
	}

	private void setupArticlelist()
	{
		try {
    		Gtk.CssProvider provider = new Gtk.CssProvider ();
    		provider.load_from_file(GLib.File.new_for_path("/usr/share/FeedReader/FeedReader.css"));
                

			weak Gdk.Display display = Gdk.Display.get_default ();
            weak Gdk.Screen screen = display.get_default_screen ();
			Gtk.StyleContext.add_provider_for_screen (screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		} catch (Error e) {
			warning ("Error: %s", e.message);
		}

		
		int article_row_width = settings_state.get_int("article-row-width");
		m_pane_articlelist = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);
		m_pane_articlelist.set_size_request(500, 500);
		m_pane_articlelist.set_position(article_row_width);
		m_articleList = new articleList();
		m_pane_articlelist.pack1(m_articleList, false, false);
		m_articleList.setOnlyUnread(m_headerbar.m_only_unread);
		m_articleList.setOnlyMarked(m_headerbar.m_only_marked);
		

		m_articleList.row_activated.connect((row) => {
			if(row.isUnread()){
				feedDaemon_interface.changeUnread(row.m_articleID, STATUS_READ);
				row.updateUnread(STATUS_READ);
				row.removeUnreadIcon();
				
				dataBase.update_article.begin(row.m_articleID, "unread", STATUS_READ, (obj, res) => {
					dataBase.update_article.end(res);
				});
				dataBase.change_unread.begin(row.m_feedID, STATUS_READ, (obj, res) => {
					dataBase.change_unread.end(res);
					updateFeedList();
				});
			}
			m_article_view.fillContent(row.m_articleID);
		});

		m_articleList.updateFeedList.connect(() =>{
			updateFeedList();
		});

		m_articleList.load_more.connect(() => {
				m_articleList.createHeadlineList();
		});
	}
	
	private void loadContent()
	{
		print("load content\n");
		m_feedList.newFeedlist();
		m_articleList.newHeadlineList();
		dataBase.updateBadge.connect(() => {
			feedDaemon_interface.updateBadge();
		});
		
		m_stack.set_visible_child_full("content", Gtk.StackTransitionType.SLIDE_LEFT);
	}


	public void updateFeedList()
	{
		m_feedList.updateFeedList.begin((obj, res) => {
			m_feedList.updateFeedList.end(res);
		});
	}


	public void updateArticleList()
	{
		m_articleList.updateArticleList();
	}


	private void about() 
	{
		string[] authors = { "Jan Lukas Gernert", null };
		string[] documenters = { "nobody", null };
		Gtk.show_about_dialog (this,
                               "program-name", ("FeedReader"),
                               "version", "0.2",
                               "copyright", ("Copyright © 2014 Jan Lukas Gernert"),
                               "authors", authors,
		                       "comments", "Desktop Client for various RSS Services",
                               "documenters", documenters,
		                       "license_type", Gtk.License.GPL_3_0,
		                       "logo_icon_name", "internet-news-reader",
                               null);
	}


	 
}
