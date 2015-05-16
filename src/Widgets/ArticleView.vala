public class FeedReader.articleView : Gtk.Stack {

	private WebKit.WebView m_view1;
	private WebKit.WebView m_view2;
	private WebKit.WebView m_currentView;
	private WebKit.FindController m_search1;
	private WebKit.FindController m_search2;
	private WebKit.FindController m_currentSearch;
	private bool m_open_external;
	private int m_load_ongoing;
	private string m_currentArticle;
	private bool m_firstTime;


	public articleView () {
		m_load_ongoing = 0;
		m_firstTime = true;

		m_view1 = new WebKit.WebView();
		m_view1.load_changed.connect(open_link);
		m_view1.context_menu.connect(() => { return true; });
		m_view2 = new WebKit.WebView();
		m_view2.load_changed.connect(open_link);
		m_view2.context_menu.connect(() => { return true; });
		m_search1 = m_view1.get_find_controller();
		m_search2 = m_view2.get_find_controller();

		m_currentView = m_view1;
		m_currentSearch = m_search1;

		var emptyView = new Gtk.Label(_("No Article selected."));
		emptyView.get_style_context().add_class("emptyView");

		this.add_named(emptyView, "empty");
		this.add_named(m_view1, "view1");
		this.add_named(m_view2, "view2");

		this.set_visible_child_name("empty");
		this.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		this.set_transition_duration(100);
		this.set_size_request(600, 0);
	}

	public void reload()
	{
		fillContent.begin(m_currentArticle, (obj, res) => {
			fillContent.end(res);
		});
	}

	public async void fillContent(string articleID)
	{
		SourceFunc callback = fillContent.callback;

		m_currentArticle = articleID;

		if(m_currentView == m_view1)
		{
			m_currentView = m_view2;
			m_currentSearch = m_search2;
		}
		else
		{
			m_currentView = m_view1;
			m_currentSearch = m_search1;
		}

		article Article = null;

		ThreadFunc<void*> run = () => {
			Article = dataBase.read_article(articleID);
			if(Article.getAuthor() == "")
				Article.setAuthor(_("not available"));

			Idle.add((owned) callback);
			return null;
		};
		new GLib.Thread<void*>("fillContent", run);
		yield;

		m_open_external = false;
		m_load_ongoing = 0;


		m_currentView.load_html(
			Utils.buildArticle(
					Article.getHTML(),
					Article.m_title,
					Article.m_url,
					Article.getAuthor(),
					Article.getDateNice(),
					Article.m_feedID
				)
			, null);
		this.show_all();

		if(m_currentView == m_view1)		 this.set_visible_child_full("view1", Gtk.StackTransitionType.CROSSFADE);
		else if(m_currentView == m_view2)   this.set_visible_child_full("view2", Gtk.StackTransitionType.CROSSFADE);
	}

	public void clearContent()
	{
		this.set_visible_child_name("empty");
		m_currentArticle = "";
	}

	public string getCurrentArticle()
	{
		return m_currentArticle;
	}

	public void open_link(WebKit.LoadEvent load_event)
	{
		logger.print(LogMessage.DEBUG, "ArticleView: load event");
		m_load_ongoing++;

		switch (load_event)
		{
			case WebKit.LoadEvent.STARTED:
				if(m_open_external)
				{
					string url = m_currentView.get_uri();
					logger.print(LogMessage.DEBUG, "ArticleView: open external url: %s".printf(url));

					try{
						Gtk.show_uri(Gdk.Screen.get_default(), url, Gdk.CURRENT_TIME);
					}
					catch(GLib.Error e){
						logger.print(LogMessage.DEBUG, "could not open the link in an external browser: %s".printf(e.message));
						m_currentView.stop_loading();
					}
					m_currentView.stop_loading();
				}
				break;
			case WebKit.LoadEvent.COMMITTED:
				break;
			case WebKit.LoadEvent.FINISHED:
				if(m_load_ongoing >= 3){
					logger.print(LogMessage.DEBUG, "ArticleView: set open external = true");
					m_open_external = true;
					//m_currentSearch.search("Windows", WebKit.FindOptions.NONE, 99);

					if(m_firstTime)
					{
						this.setScrollPos(settings_state.get_int("articleview-scrollpos"));
						settings_state.set_int("articleview-scrollpos", 0);
						m_firstTime = false;
					}
				}
				break;
		}
	}

	public void setScrollPos(int pos)
	{
		m_currentView.run_javascript.begin("window.scrollTo(0,%i);".printf(pos), null, (obj, res) => {
			m_currentView.run_javascript.end(res);
		});
	}

	public int getScrollPos()
	{
		// use mainloop to prevent app from shutting down before the result can be fetched
		// ugly but works =/
		// better solution welcome

		int scrollPos = -1;
		var loop = new MainLoop();

		m_currentView.run_javascript.begin("document.title = window.scrollY;", null, (obj, res) => {
			m_currentView.run_javascript.end(res);
			scrollPos = int.parse(m_currentView.get_title());
			loop.quit();
		});

		loop.run();
		return scrollPos;
	}

}
