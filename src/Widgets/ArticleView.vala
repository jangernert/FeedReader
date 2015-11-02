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

public class FeedReader.articleView : Gtk.Stack {

	private WebKit.WebView m_view;
	private WebKit.FindController m_search;
	private bool m_open_external;
	private string m_currentArticle;
	private bool m_firstTime;
	private string m_searchTerm;
	private double m_dragBuffer[10];
	private double m_posY;
	private double m_momentum;
	private bool m_inDrag;
	public signal void enterFullscreen();
	public signal void leaveFullscreen();


	public articleView () {
		m_open_external = true;
		m_searchTerm = "";
		m_firstTime = true;
		m_inDrag = false;
		m_posY = 0;
		m_momentum = 0;

		m_view = new WebKit.WebView();
		m_view.load_changed.connect(open_link);
		m_view.context_menu.connect(() => { return true; });
		m_view.set_events(Gdk.EventMask.POINTER_MOTION_MASK);
		m_view.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		m_view.set_events(Gdk.EventMask.BUTTON_RELEASE_MASK);
		m_view.button_press_event.connect(onClick);
		m_view.button_release_event.connect(onRelease);
		m_view.enter_fullscreen.connect(() => { enterFullscreen(); return false;});
		m_view.leave_fullscreen.connect(() => { leaveFullscreen(); return false;});
		m_view.load_failed.connect(loadFailed);
		m_search = m_view.get_find_controller();

		var emptyView = new Gtk.Label(_("No Article selected."));
		emptyView.get_style_context().add_class("h2");

		this.add_named(emptyView, "empty");
		this.add_named(m_view, "view");

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
				m_view.get_window(),
				Gdk.GrabOwnership.NONE,
				false,
				Gdk.EventMask.POINTER_MOTION_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK,
				cursor,
				Gdk.CURRENT_TIME
			);

			Gtk.device_grab_add(this, pointer, false);
			GLib.Timeout.add(10, updateDragMomentum);
			m_view.motion_notify_event.connect(mouseMotion);
			return true;
		}

		return false;
	}

	private bool onRelease(Gdk.EventButton event)
	{
		if(event.button == MouseButton.MIDDLE)
		{
			m_posY = 0;
			m_view.motion_notify_event.disconnect(mouseMotion);
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
		m_currentArticle = articleID;
		logger.print(LogMessage.DEBUG, "ArticleView: load article %s".printf(articleID));

		if(isLoading())
		{
			m_view.stop_loading();
			return;
		}

		m_open_external = false;
		article Article = null;
		SourceFunc callback = fillContent.callback;

		ThreadFunc<void*> run = () => {
			Article = dataBase.read_article(articleID);
			if(Article.getAuthor() == "")
				Article.setAuthor(_("Not available"));

			Idle.add((owned) callback);
			return null;
		};
		new GLib.Thread<void*>("fillContent", run);
		yield;


		var background = Gdk.RGBA();

		switch(settings_general.get_enum("article-theme"))
		{
			case ArticleTheme.DEFAULT:
				background.parse("#FFFFFF");
				break;

			case ArticleTheme.SPRING:
				background.parse("#FFFFFF");
				break;

			case ArticleTheme.MIDNIGHT:
				background.parse("#0B243B");
				break;

			case ArticleTheme.PARCHMENT:
				background.parse("#F5ECCE");
				break;
		}

		m_view.set_background_color(background);



		m_view.load_html(
			Utils.buildArticle(
					Article.getHTML(),
					Article.getTitle(),
					Article.getURL(),
					Article.getAuthor(),
					Article.getDateNice(),
					Article.getFeedID()
				)
			, "file://" + GLib.Environment.get_home_dir() + "/.local/share/feedreader/data/images/");
		this.show_all();
		this.set_visible_child_name("view");
	}

	public void clearContent()
	{
		this.set_visible_child_name("empty");
		m_currentArticle = "";
	}

	public bool isLoading()
	{
		return m_view.is_loading;
	}

	public string getCurrentArticle()
	{
		return m_currentArticle;
	}

	public void open_link(WebKit.LoadEvent load_event)
	{
		logger.print(LogMessage.DEBUG, "ArticleView: load event");

		switch (load_event)
		{
			case WebKit.LoadEvent.STARTED:
				if(m_open_external)
				{
					string url = m_view.get_uri();
					if(url != "file://" + GLib.Environment.get_home_dir() + "/.local/share/feedreader/data/images/")
					{
						logger.print(LogMessage.DEBUG, "ArticleView: open external url: %s".printf(url));
						try{
							Gtk.show_uri(Gdk.Screen.get_default(), url, Gdk.CURRENT_TIME);
						}
						catch(GLib.Error e){
							logger.print(LogMessage.DEBUG, "could not open the link in an external browser: %s".printf(e.message));
						}
					}

					m_view.stop_loading();
				}
				break;
			case WebKit.LoadEvent.COMMITTED:
				if(m_searchTerm != "")
					m_search.search(m_searchTerm, WebKit.FindOptions.CASE_INSENSITIVE, 99);
				break;
			case WebKit.LoadEvent.FINISHED:
				if(m_firstTime)
				{
					this.setScrollPos(settings_state.get_int("articleview-scrollpos"));
					settings_state.set_int("articleview-scrollpos", 0);
					m_firstTime = false;
				}

				logger.print(LogMessage.DEBUG, "ArticleView: set open external = true");
				m_open_external = true;
				break;
		}
	}

	private bool loadFailed(WebKit.LoadEvent event, string failing_uri, void* error)
	{
		GLib.Error e = (GLib.Error)error;
		logger.print(LogMessage.DEBUG, "ArticleView: load failed: message: \"%s\", domain \"%s\", code \"%i\"".printf(e.message, e.domain.to_string(), e.code));
		if(e.matches(WebKit.NetworkError.quark(), 302) && !m_open_external)
		{
			logger.print(LogMessage.DEBUG, "ArticleView: loading canceled " + m_currentArticle);
			fillContent(m_currentArticle);
		}
		return true;
	}

	public void setScrollPos(int pos)
	{
		m_view.run_javascript.begin("window.scrollTo(0,%i);".printf(pos), null, (obj, res) => {
			m_view.run_javascript.end(res);
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

		m_view.run_javascript.begin(javascript, null, (obj, res) => {
			m_view.run_javascript.end(res);
			upper = int.parse(m_view.get_title());
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

		m_view.run_javascript.begin("document.title = window.scrollY;", null, (obj, res) => {
			m_view.run_javascript.end(res);
			scrollPos = int.parse(m_view.get_title());
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
		m_view.get_allocation(out allocation);

		double pageSize = m_view.get_allocated_height();
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
