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
	private string m_searchTerm;
	private double m_dragBuffer[10];
	private double m_posY;
	private double m_momentum;
	private bool m_inDrag;


	public articleView () {
		m_load_ongoing = 0;
		m_searchTerm = "";
		m_firstTime = true;
		m_inDrag = false;
		m_posY = 0;
		m_momentum = 0;

		m_view1 = new WebKit.WebView();
		m_view1.load_changed.connect(open_link);
		m_view1.context_menu.connect(() => { return true; });
		m_view1.set_events(Gdk.EventMask.POINTER_MOTION_MASK);
		m_view1.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		m_view1.set_events(Gdk.EventMask.BUTTON_RELEASE_MASK);
		m_view1.button_press_event.connect(onClick);
		m_view1.button_release_event.connect(onRelease);
		m_view2 = new WebKit.WebView();
		m_view2.load_changed.connect(open_link);
		m_view2.context_menu.connect(() => { return true; });
		m_view2.set_events(Gdk.EventMask.POINTER_MOTION_MASK);
		m_view2.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		m_view2.set_events(Gdk.EventMask.BUTTON_RELEASE_MASK);
		m_view2.button_press_event.connect(onClick);
		m_view2.button_release_event.connect(onRelease);
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

	private bool onClick(Gdk.EventButton event)
	{
		if(event.button == MouseButton.MIDDLE)
		{
			m_posY = event.y;
			for(int i = 0; i < 10; ++i)
			{
				m_dragBuffer[i] = m_posY;
			}
			m_inDrag = true;

			var display = Gdk.Display.get_default();
			var pointer = display.get_device_manager().get_client_pointer();
			var cursor = new Gdk.Cursor.for_display(display, Gdk.CursorType.FLEUR);

			pointer.grab(
				m_currentView.get_window(),
				Gdk.GrabOwnership.NONE,
				false,
				Gdk.EventMask.POINTER_MOTION_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK,
				cursor,
				Gdk.CURRENT_TIME
			);

			Gtk.device_grab_add(this, pointer, false);
			GLib.Timeout.add(10, updateDragMomentum);
			m_currentView.motion_notify_event.connect(mouseMotion);
			return true;
		}

		return false;
	}

	private bool onRelease(Gdk.EventButton event)
	{
		if(event.button == MouseButton.MIDDLE)
		{
			m_posY = 0;
			m_currentView.motion_notify_event.disconnect(mouseMotion);
			m_inDrag = false;
			GLib.Timeout.add(20, ScrollDragRelease);

			var pointer = Gdk.Display.get_default().get_device_manager().get_client_pointer();
			Gtk.device_grab_remove(this, pointer);
			pointer.ungrab(Gdk.CURRENT_TIME);

			return true;
		}

		return false;
	}

	private bool mouseMotion(Gdk.EventMotion event)
	{
		double scroll = m_posY - event.y;
		m_posY = event.y;
		setScrollPos(getScrollPos() + (int)scroll);

		return true;
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
					Article.getTitle(),
					Article.getURL(),
					Article.getAuthor(),
					Article.getDateNice(),
					Article.getFeedID()
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
					m_currentSearch.search(m_searchTerm, WebKit.FindOptions.CASE_INSENSITIVE, 99);

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

	private int getScollUpper()
	{
		string javascript = """
								document.title = Math.max	(
																document.body.scrollHeight,
																document.body.offsetHeight,
																document.documentElement.clientHeight,
																document.documentElement.scrollHeight,
																document.documentElement.offsetHeight
															);
							""";
		int upper = -1;
		var loop = new MainLoop();

		m_currentView.run_javascript.begin(javascript, null, (obj, res) => {
			m_currentView.run_javascript.end(res);
			upper = int.parse(m_currentView.get_title());
			loop.quit();
		});

		loop.run();
		return upper;
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

	public void setSearchTerm(string searchTerm)
	{
		m_searchTerm = Utils.parseSearchTerm(searchTerm);
	}

	private bool updateDragMomentum()
	{
		if(!m_inDrag)
			return false;

		for(int i = 9; i > 0; --i)
		{
			m_dragBuffer[i] = m_dragBuffer[i-1];
		}

		m_dragBuffer[0] = m_posY;
		m_momentum = m_dragBuffer[9] - m_dragBuffer[0];

		return true;
	}

	private bool ScrollDragRelease()
	{
		if(m_inDrag)
			return true;

		m_momentum /= 1.2;

		Gtk.Allocation allocation;
		m_currentView.get_allocation(out allocation);

		double pageSize = m_currentView.get_allocated_height();
		double adjValue = pageSize * m_momentum / allocation.height;
		double oldAdj = getScrollPos();
		double upper = getScollUpper();

		if ((oldAdj + adjValue) > (upper - pageSize)
		|| (oldAdj + adjValue) < 0)
		{
			m_momentum = 0;
		}

		double newScrollPos = double.min(oldAdj + adjValue, upper - pageSize);
		setScrollPos((int)newScrollPos);

		if (m_momentum < 1 && m_momentum > -1)
			return false;
		else
			return true;
	}

}
