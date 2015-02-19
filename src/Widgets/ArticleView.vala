public class FeedReader.articleView : Gtk.Stack {

	private Gtk.Label m_title;
	private WebKit.WebView m_view;
	private Gtk.ScrolledWindow m_scroll;
	//private Gtk.Adjustment m_adjustment;
	private Gtk.Box m_box;
	private Gtk.Spinner m_spinner;
	private bool m_open_external;
	private int m_load_ongoing;

	public articleView () {
		m_load_ongoing = 0;
		m_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

		m_title = new Gtk.Label("");
		m_title.set_size_request(0, 40);
		m_title.set_line_wrap(true);
		m_title.set_line_wrap_mode(Pango.WrapMode.WORD);
		
		
		m_view = new WebKit.WebView();
		//m_view.self-scrolling = false;
		//m_view.set_size_request(400, 500);
		m_view.load_changed.connect(open_link);
		m_scroll = new Gtk.ScrolledWindow(null, null);
		m_scroll.set_size_request(400, 500);
		m_scroll.add(m_view);
		
		//m_adjustment = m_scroll.get_vadjustment();

		m_box.pack_start(m_title, false, false, 0);
		m_box.pack_start(m_scroll, true, true, 0);
		//m_box.pack_start(m_view, true, true, 0);

		var emptyView = new Gtk.Label(_("No Article selected."));
		emptyView.get_style_context().add_class("emptyView");

		m_spinner = new Gtk.Spinner();
		m_spinner.set_size_request(40, 40);
		var center = new Gtk.Alignment(0.5f, 0.5f, 0.0f, 0.0f);
		center.set_padding(20, 20, 20, 20);
		center.add(m_spinner);
		this.add_named(emptyView, "empty");
		this.add_named(m_box, "view");
		this.add_named(center, "spinner");
		
		this.set_visible_child_name("empty");
		this.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		this.set_transition_duration(100);
	}
	
	public void fillContent(string articleID)
	{
		this.set_visible_child_name("spinner");
		m_spinner.start();
		
		var Article = dataBase.read_article(articleID);
		string author;
		(Article.m_author == "") ? author = "not available" : author = Article.m_author;
		m_title.set_text("<big><b><a href=\"" + Article.m_url.replace("&","&amp;") + "\" title=\"Author: " + author.replace("&","&amp;") + "\">" + Article.m_title.replace("&","&amp;") + "</a></b></big>");
		m_title.set_use_markup (true);
		this.show_all();
		m_open_external = false;
		m_load_ongoing = 0;
		m_view.load_html(Article.m_html, null);
		//restoreScrollPos();
		this.set_visible_child_name("view");
	}

	public void clearContent()
	{
		this.set_visible_child_name("empty");
	}

	public void open_link(WebKit.LoadEvent load_event)
	{
		m_load_ongoing++;
		
		switch (load_event)
		{
			case WebKit.LoadEvent.STARTED:
				if(m_open_external)
				{
					try{Gtk.show_uri(Gdk.Screen.get_default(), m_view.get_uri(), Gdk.CURRENT_TIME);}
					catch(GLib.Error e){ warning("could not open the link in an external browser\n%s\n", e.message); }
					m_view.stop_loading();
				}
				break;
			case WebKit.LoadEvent.COMMITTED:
				break;	
			case WebKit.LoadEvent.FINISHED:
				if(m_load_ongoing >= 3){
					m_open_external = true;
				}
				break;
		}
	}
	
	/*private void restoreScrollPos()
	{
		//m_adjustment = m_scroll.get_vadjustment();
		m_adjustment.set_value(settings_state.get_double("articleview-scrollpos"));
		//m_scroll.set_vadjustment(m_adjustment);
		settings_state.set_double("articleview-scrollpos", 0.0);
	}
	
	public double getScrollPos()
	{
		return m_adjustment.get_value();
	}*/
}
