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

	private Gtk.Overlay m_overlay;
	private Gtk.Label m_overlayLabel;
	private WebKit.WebView m_view;
	private WebKit.FindController m_search;
	private string m_currentArticle;
	private bool m_firstTime = true;
	private string m_searchTerm = "";
	private double m_dragBuffer[10];
	private double m_posY = 0;
	private double m_posY2 = 0;
	private double m_posX2 = 0;
	private double m_momentum = 0;
	private bool m_inDrag = false;
	private uint m_OngoingScrollID = 0;
	private bool m_stopLoading = false;
	private string m_imageURL;
	public signal void enterFullscreen();
	public signal void leaveFullscreen();


	public articleView()
	{
		var settings = new WebKit.Settings();
		settings.set_enable_accelerated_2d_canvas(true);
		settings.set_enable_html5_database(false);
		settings.set_enable_html5_local_storage(false);
		settings.set_enable_java(false);
		settings.set_enable_media_stream(false);
		settings.set_enable_page_cache(false);
		settings.set_enable_plugins(false);
		settings.set_enable_private_browsing(true);
		settings.set_enable_smooth_scrolling(true);
		settings.set_javascript_can_access_clipboard(false);
		settings.set_javascript_can_open_windows_automatically(false);
		settings.set_media_playback_requires_user_gesture(true);
		settings.set_user_agent_with_application_details("FeedReader", AboutInfo.version);

		m_view = new WebKit.WebView();
		m_view.set_settings(settings);
		m_view.load_changed.connect(open_link);
		m_view.context_menu.connect(onContextMenu);
		m_view.mouse_target_changed.connect(onMouseOver);
		m_view.set_events(Gdk.EventMask.POINTER_MOTION_MASK);
		m_view.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		m_view.set_events(Gdk.EventMask.BUTTON_RELEASE_MASK);
		m_view.button_press_event.connect(onClick);
		m_view.button_release_event.connect(onRelease);
		m_view.motion_notify_event.connect(onMouseMotion);
		m_view.notify["title"].connect(() => {
			if(m_view.title.has_prefix("path:"))
			{
				int pathEnd = m_view.title.index_of_char(' ');
				string path = GLib.Uri.unescape_string(m_view.title.substring(5, pathEnd-5));
				string prefix = "file://";
				if(path.has_prefix(prefix))
					path = path.substring(prefix.length);
				logger.print(LogMessage.DEBUG, "path: " + path);

				int sizeXStart = m_view.title.index_of_char(':', pathEnd) + 1;
				int sizeXEnd = m_view.title.index_of_char(' ', sizeXStart);
				double sizeX = double.parse(m_view.title.substring(sizeXStart, sizeXEnd-sizeXStart));

				int sizeYStart = m_view.title.index_of_char(':', sizeXEnd) + 1;
				int sizeYEnd = m_view.title.index_of_char(' ', sizeYStart);
				double sizeY = double.parse(m_view.title.substring(sizeYStart, sizeYEnd-sizeYStart));

				logger.print(LogMessage.DEBUG, "sizeX: %f sizeY: %f".printf(sizeX, sizeY));
				m_view.run_javascript.begin("document.title = \"\";", null, (obj, res) => {
					m_view.run_javascript.end(res);
				});

				var window = this.get_toplevel() as readerUI;
				var popup = new imagePopup(path, null, window, sizeY, sizeX);
			}

		});

		m_view.enter_fullscreen.connect(() => { enterFullscreen(); return false;});
		m_view.leave_fullscreen.connect(() => { leaveFullscreen(); return false;});
		m_search = m_view.get_find_controller();

		WebKit.WebContext.get_default().set_cache_model(WebKit.CacheModel.DOCUMENT_BROWSER);

		var emptyView = new Gtk.Label(_("No Article selected."));
		emptyView.get_style_context().add_class("h2");

		m_overlayLabel = new Gtk.Label("dummy URL");
		m_overlayLabel.margin = 10;
		m_overlayLabel.height_request = 30;
		m_overlayLabel.valign = Gtk.Align.END;
		m_overlayLabel.halign = Gtk.Align.START;
		m_overlayLabel.get_style_context().add_class("overlay");
		m_overlayLabel.no_show_all = true;
		m_overlay = new Gtk.Overlay();
		m_overlay.add(m_view);
		m_overlay.add_overlay(m_overlayLabel);

		this.add_named(emptyView, "empty");
		this.add_named(m_overlay, "view");

		this.set_visible_child_name("empty");
		this.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		this.set_transition_duration(100);
		this.set_size_request(450, 0);
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
			m_view.motion_notify_event.connect(updateScroll);
			return true;
		}

		return false;
	}

	private bool onRelease(Gdk.EventButton event)
	{
		if(event.button == MouseButton.MIDDLE)
		{
			//m_posY = 0;
			m_view.motion_notify_event.disconnect(updateScroll);
			m_inDrag = false;
			m_OngoingScrollID = GLib.Timeout.add(20, ScrollDragRelease);

			var pointer = Gdk.Display.get_default().get_device_manager().get_client_pointer();
			Gtk.device_grab_remove(this, pointer);
			pointer.ungrab(Gdk.CURRENT_TIME);

			return true;
		}

		return false;
	}

	private bool onMouseMotion(Gdk.EventMotion event)
	{
		m_posX2 = event.x;
		m_posY2 = event.y;
		return false;
	}

	private bool updateScroll(Gdk.EventMotion event)
	{
		double scroll = m_posY - event.y;
		m_posY = event.y;
		setScrollPos(getScrollPos() + (int)scroll);

		return false;
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
			logger.print(LogMessage.DEBUG, "ArticleView: still busy loading last article. will cancel loading and load new article");
			m_view.load_failed.connect(loadFailed);
			m_view.stop_loading();
			m_stopLoading = true;
			return;
		}

		if(m_OngoingScrollID > 0)
		{
            GLib.Source.remove(m_OngoingScrollID);
            m_OngoingScrollID = 0;
        }

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

		setBackgroundColor();



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
		switch (load_event)
		{
			case WebKit.LoadEvent.STARTED:
				logger.print(LogMessage.DEBUG, "ArticleView: load STARTED");
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
					m_view.stop_loading();
				}
				break;
			case WebKit.LoadEvent.COMMITTED:
				logger.print(LogMessage.DEBUG, "ArticleView: load COMMITTED");
				if(m_searchTerm != "")
					m_search.search(m_searchTerm, WebKit.FindOptions.CASE_INSENSITIVE, 99);
				break;
			case WebKit.LoadEvent.FINISHED:
				logger.print(LogMessage.DEBUG, "ArticleView: load FINISHED");
				if(m_stopLoading)
				{
					logger.print(LogMessage.DEBUG, "ArticleView: loading finished before canceling");
					m_view.load_failed.disconnect(loadFailed);
					m_stopLoading = false;
					fillContent(m_currentArticle);
				}
				if(m_firstTime)
				{
					this.setScrollPos(settings_state.get_int("articleview-scrollpos"));
					settings_state.set_int("articleview-scrollpos", 0);
					m_view.grab_focus();
					m_firstTime = false;
				}
				break;
		}
	}

	private bool loadFailed(WebKit.LoadEvent event, string failing_uri, void* error)
	{
		GLib.Error e = (GLib.Error)error;
		logger.print(LogMessage.DEBUG, "ArticleView: load failed: message: \"%s\", domain \"%s\", code \"%i\"".printf(e.message, e.domain.to_string(), e.code));
		if(e.matches(WebKit.NetworkError.quark(), 302))
		{
			logger.print(LogMessage.DEBUG, "ArticleView: loading canceled " + m_currentArticle);
			WebKit.WebContext.get_default().clear_cache();
			m_view.load_failed.disconnect(loadFailed);
			m_stopLoading = false;
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

		try{
			m_view.run_javascript.begin("document.title = window.scrollY;", null, (obj, res) => {
				m_view.run_javascript.end(res);
				scrollPos = int.parse(m_view.get_title());
				loop.quit();
			});
		}
		catch(GLib.Error e)
		{
			logger.print(LogMessage.ERROR, "ArticleView: could not get scroll-pos, javascript error: " + e.message);
		}


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
		{
			m_OngoingScrollID = 0;
			return false;
		}
		else
			return true;
	}

	private void setBackgroundColor()
	{
#if USE_WEBKIT_4
		var window = ((rssReaderApp)GLib.Application.get_default()).getWindow();
		if(window != null)
		{
			var background = window.getContent().getBackgroundColor();
			m_view.set_background_color(background);
		}
#endif
	}

	private bool onContextMenu(WebKit.ContextMenu menu, Gdk.Event event, WebKit.HitTestResult hitTest)
	{
		var menuItems = menu.get_items().copy();
		foreach(var menuItem in menuItems)
		{
			if(menuItem.get_action() == null)
			{
				menu.remove(menuItem);
				continue;
			}

			if((menuItem.get_action().name != "context-menu-action-3")  // copy link location
			&& (menuItem.get_action().name != "context-menu-action-6")  // copy image
			&& (menuItem.get_action().name != "context-menu-action-7")) // copy image address
			{
				menu.remove(menuItem);
			}
		}

		if(menu.first() == null)
			return true;

		return false;
	}

	private void onMouseOver(WebKit.HitTestResult hitTest, uint modifiers)
	{
		if(hitTest.context_is_link())
		{
			var url = hitTest.get_link_uri();
			int length = 45;

			if(url.length >= length)
			{
				url = url.substring(0, length-3) + "...";
			}
			m_overlayLabel.label = url;
			m_overlayLabel.width_chars = url.length;
			m_overlayLabel.show();

			double relX = m_posX2/this.get_allocated_height();
			double relY = m_posY2/this.get_allocated_width();

			if(relY >= 0.85 && relX <= 0.5)
			{
				m_overlayLabel.halign = Gtk.Align.END;
			}
			else
			{
				m_overlayLabel.halign = Gtk.Align.START;
			}
		}
		else
		{
			m_overlayLabel.hide();
		}
	}

}
