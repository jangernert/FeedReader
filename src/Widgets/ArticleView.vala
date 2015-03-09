public class FeedReader.articleView : Gtk.Stack {

	private Gtk.Label m_title1;
	private Gtk.Label m_title2;
	private Gtk.Label m_currentTitle;
	private WebKit.WebView m_view1;
	private WebKit.WebView m_view2;
	private WebKit.WebView m_currentView;
	private Gtk.Box m_box1;
	private Gtk.Box m_box2;
	private bool m_open_external;
	private int m_load_ongoing;
	private string m_currentArticle;

	public articleView () {
		m_load_ongoing = 0;
		m_box1 = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		m_box2 = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

		m_title1 = new Gtk.Label("");
		m_title1.set_size_request(0, 40);
		m_title1.set_line_wrap(true);
		m_title1.set_line_wrap_mode(Pango.WrapMode.WORD);
		m_title2 = new Gtk.Label("");
		m_title2.set_size_request(0, 40);
		m_title2.set_line_wrap(true);
		m_title2.set_line_wrap_mode(Pango.WrapMode.WORD);
		m_currentTitle = m_title1;


		m_view1 = new WebKit.WebView();
		m_view1.load_changed.connect(open_link);
		m_view2 = new WebKit.WebView();
		m_view2.load_changed.connect(open_link);
		m_currentView = m_view1;

		m_box1.pack_start(m_title1, false, false, 0);
		m_box1.pack_start(m_view1, true, true, 0);
		m_box2.pack_start(m_title2, false, false, 0);
		m_box2.pack_start(m_view2, true, true, 0);

		var emptyView = new Gtk.Label(_("No Article selected."));
		emptyView.get_style_context().add_class("emptyView");

		this.add_named(emptyView, "empty");
		this.add_named(m_box1, "view1");
		this.add_named(m_box2, "view2");

		this.set_visible_child_name("empty");
		this.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		this.set_transition_duration(100);
		this.set_size_request(600, 0);
	}

	public async void fillContent(string articleID)
	{
		SourceFunc callback = fillContent.callback;
		m_currentArticle = articleID;

		if(m_currentView == m_view1)
		{
			m_currentView = m_view2;
			m_currentTitle = m_title2;
		}
		else
		{
			m_currentView = m_view1;
			m_currentTitle = m_title1;
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

		m_currentTitle.set_text(
			"<big><b><a href=\"" + Article.m_url.replace("&","&amp;") +
			"\" title=\"Author: " + Article.getAuthor().replace("&","&amp;") + "\">" +
			Article.m_title.replace("&","&amp;") + "</a></b></big>"
		);
		m_currentTitle.set_use_markup (true);
		m_open_external = false;
		m_load_ongoing = 0;


		string css;
		GLib.FileUtils.get_contents("/usr/share/FeedReader/ArticleView-default.css", out css);
		m_currentView.load_html("<style>" + css + "</style>" + Article.getHTML(), null);
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

					if(!url.has_prefix("http://"))
						url = "http://" + url;

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
				}
				break;
		}
	}
}
