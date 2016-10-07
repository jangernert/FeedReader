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

[DBus (name = "org.gnome.feedreader.FeedReaderArticleView")]
interface FeedReaderWebExtension : Object
{
	public abstract void recalculate() throws IOError;
    public signal void onClick(string path, int width, int height, string url);
	public signal void message(string message);
}

public class FeedReader.articleView : Gtk.Overlay {

	private Gtk.Overlay m_videoOverlay;
	private Gtk.Label m_overlayLabel;
	private WebKit.WebView m_view1;
	private WebKit.WebView m_view2;
	private WebKit.WebView m_currentView;
	private WebKit.FindController m_search;
	private Gtk.Stack m_stack;
	private fullscreenHeaderbar m_fsHead;
	private fullscreenButton m_prevButton;
	private fullscreenButton m_nextButton;
	private string m_currentArticle;
	private MediaPlayer? m_currentMedia = null;
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
	private uint m_timeout_source_id;
	private uint m_overlayFade = 200;
	private FeedReaderWebExtension m_messenger = null;
	private bool m_connected = false;
	private int m_height = 0;
	private int m_width = 0;
	private bool m_FullscreenVideo = false;
	private bool m_FullscreenArticle = false;
	private double m_FullscreenZoomLevel = 1.25;
	private bool m_crashed = false;
	private int m_animationDuration = 150;
	public signal void enterFullscreen(bool video);
	public signal void leaveFullscreen(bool video);


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
		settings.set_enable_smooth_scrolling(true);
		settings.set_javascript_can_access_clipboard(false);
		settings.set_javascript_can_open_windows_automatically(false);
		settings.set_media_playback_requires_user_gesture(true);
		settings.set_user_agent_with_application_details("FeedReader", AboutInfo.version);

		m_view1 = new WebKit.WebView();
		m_view1.set_settings(settings);
		m_view1.set_events(Gdk.EventMask.POINTER_MOTION_MASK);
		m_view1.set_events(Gdk.EventMask.SCROLL_MASK);
		m_view1.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		m_view1.set_events(Gdk.EventMask.BUTTON_RELEASE_MASK);
		m_view1.set_events(Gdk.EventMask.KEY_PRESS_MASK);
		m_view1.load_changed.connect(open_link);
		m_view1.context_menu.connect(onContextMenu);
		m_view1.mouse_target_changed.connect(onMouseOver);
		m_view1.button_press_event.connect(onClick);
		m_view1.button_release_event.connect(onRelease);
		m_view1.motion_notify_event.connect(onMouseMotion);
		m_view1.enter_fullscreen.connect(enter_fullscreen);
		m_view1.leave_fullscreen.connect(leave_fullscreen);
		m_view1.scroll_event.connect(onScroll);
		m_view1.key_press_event.connect(onKeyPress);
		m_view1.web_process_crashed.connect(onCrash);

		m_view2 = new WebKit.WebView();
		m_view2.set_settings(settings);
		m_view2.set_events(Gdk.EventMask.POINTER_MOTION_MASK);
		m_view2.set_events(Gdk.EventMask.SCROLL_MASK);
		m_view2.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		m_view2.set_events(Gdk.EventMask.BUTTON_RELEASE_MASK);
		m_view2.set_events(Gdk.EventMask.KEY_PRESS_MASK);

		m_currentView = m_view1;
		m_search = m_currentView.get_find_controller();

		WebKit.WebContext.get_default().set_cache_model(WebKit.CacheModel.DOCUMENT_BROWSER);

		var emptyView = new Gtk.Label(_("No Article selected."));
		emptyView.get_style_context().add_class("h2");

		m_overlayLabel = new Gtk.Label("dummy URL");
		m_overlayLabel.margin = 10;
		m_overlayLabel.opacity = 0.0;
		m_overlayLabel.height_request = 30;
		m_overlayLabel.valign = Gtk.Align.END;
		m_overlayLabel.halign = Gtk.Align.START;
		m_overlayLabel.get_style_context().add_class("overlay");
		m_overlayLabel.no_show_all = true;

		m_stack = new Gtk.Stack();
		m_stack.add_named(emptyView, "empty");
		m_stack.add_named(m_view1, "view1");
		m_stack.add_named(m_view2, "view2");

		m_stack.set_visible_child_name("empty");
		m_stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		m_stack.set_transition_duration(m_animationDuration);
		m_stack.set_size_request(450, 0);

		this.size_allocate.connect((allocation) => {
			if(allocation.width != m_width
			|| allocation.height != m_height)
			{
				m_width = allocation.width;
				m_height = allocation.height;
				Logger.debug("ArticleView: size changed");
				recalculate.begin((obj, res) => {
					recalculate.end(res);
				});
			}
        });

		m_fsHead = new fullscreenHeaderbar();
		m_fsHead.close.connect(() => {
			leaveFullscreen(false);
			var window = this.get_toplevel() as readerUI;
			if(window != null && window.is_toplevel())
				window.unfullscreen();
		});

		var fullscreenHeaderOverlay = new Gtk.Overlay();
		fullscreenHeaderOverlay.add(m_stack);
		fullscreenHeaderOverlay.add_overlay(m_fsHead);

		m_prevButton = new fullscreenButton("go-previous-symbolic", Gtk.Align.START);
		m_prevButton.click.connect(() => {
			var window = this.get_toplevel() as readerUI;
			if(window != null && window.is_toplevel())
				window.getContent().ArticleListPREV();
		});
		var prevOverlay = new Gtk.Overlay();
		prevOverlay.add(fullscreenHeaderOverlay);
		prevOverlay.add_overlay(m_prevButton);

		m_nextButton = new fullscreenButton("go-next-symbolic", Gtk.Align.END);
		m_nextButton.click.connect(() => {
			var window = this.get_toplevel() as readerUI;
			if(window != null && window.is_toplevel())
				window.getContent().ArticleListNEXT();
		});
		var nextOverlay = new Gtk.Overlay();
		nextOverlay.add(prevOverlay);
		nextOverlay.add_overlay(m_nextButton);

		m_videoOverlay = new Gtk.Overlay();
		m_videoOverlay.add(nextOverlay);

		this.add(m_videoOverlay);
		this.add_overlay(m_overlayLabel);

		Bus.watch_name(BusType.SESSION, "org.gnome.feedreader.FeedReaderArticleView", GLib.BusNameWatcherFlags.NONE,
		(connection, name, owner) => { on_extension_appeared(connection, name, owner); }, null);
	}

	private void on_extension_appeared(GLib.DBusConnection connection, string name, string owner)
    {
    	try
    	{
			m_connected = true;
			m_messenger = connection.get_proxy_sync("org.gnome.feedreader.FeedReaderArticleView", "/org/gnome/feedreader/FeedReaderArticleView", GLib.DBusProxyFlags.DO_NOT_AUTO_START, null);
			m_messenger.onClick.connect((path, width, height, url) => {
				var window = this.get_toplevel() as readerUI;
				new imagePopup(path, url, window, height, width);
			});
			m_messenger.message.connect((message) => {
				Logger.info("ArticleView: webextension-message: " + message);
			});
			recalculate.begin((obj, res) => {
				recalculate.end(res);
			});
		}
		catch(GLib.IOError e)
		{
			Logger.error(e.message);
		}
    }

	private async void recalculate()
    {
		SourceFunc callback = recalculate.callback;
		ThreadFunc<void*> run = () => {
			try
	    	{
	    		if(m_connected && m_stack.get_visible_child_name() != "empty")
	    			m_messenger.recalculate();
	    	}
	    	catch(GLib.IOError e)
	    	{
	    		Logger.warning("ArticleView: recalculate " + e.message);
	    	}
			Idle.add((owned) callback);
			return null;
		};
		new GLib.Thread<void*>("recalculate", run);
		yield;
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
			var seat = display.get_default_seat();
			var pointer = seat.get_pointer();
			var cursor = new Gdk.Cursor.for_display(display, Gdk.CursorType.FLEUR);

			seat.grab(
				m_currentView.get_window(),
				Gdk.SeatCapabilities.POINTER,
				false,
				cursor,
				null,
				null
			);

			Gtk.device_grab_add(this, pointer, false);
			GLib.Timeout.add(10, updateDragMomentum);
			m_currentView.motion_notify_event.connect(updateScroll);
			return true;
		}

		return false;
	}

	private bool onRelease(Gdk.EventButton event)
	{
		if(event.button == MouseButton.MIDDLE)
		{
			m_currentView.motion_notify_event.disconnect(updateScroll);
			m_inDrag = false;
			m_OngoingScrollID = GLib.Timeout.add(20, ScrollDragRelease);

			var display = Gdk.Display.get_default();
			var seat = display.get_default_seat();
			var pointer = seat.get_pointer();
			Gtk.device_grab_remove(this, pointer);
			seat.ungrab();

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

	private bool onScroll(Gdk.EventScroll event)
	{
		if((event.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK)
		{
			if(event.delta_y > 0)
				m_currentView.zoom_level -= 0.25;
			else if(event.delta_y < 0)
				m_currentView.zoom_level += 0.25;
			return true;
		}

		return false;
	}

	private bool onKeyPress(Gdk.EventKey event)
	{
		if((event.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK)
		{
			switch(event.keyval)
			{
				case Gdk.Key.KP_0:
					if(m_FullscreenArticle)
						m_currentView.zoom_level = m_FullscreenZoomLevel;
					else
						m_currentView.zoom_level = 1.0;
					return true;

				case Gdk.Key.KP_Add:
					m_currentView.zoom_level += 0.25;
					return true;

				case Gdk.Key.KP_Subtract:
					m_currentView.zoom_level -= 0.25;
					return true;
			}
		}

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
		fillContent(m_currentArticle);
	}

	public void fillContent(string articleID)
	{
		m_currentArticle = articleID;
		Logger.debug("ArticleView: load article %s".printf(articleID));

		if(m_currentView.is_loading && !m_crashed)
		{
			Logger.debug("ArticleView: still busy loading last article. will cancel loading and load new article");
			m_currentView.load_failed.connect(loadFailed);
			m_currentView.stop_loading();
			m_stopLoading = true;
			return;
		}

		m_crashed = false;
		switchViews();

		if(m_FullscreenArticle)
			m_currentView.zoom_level = m_FullscreenZoomLevel;
		else
			m_currentView.zoom_level = 1.0;


		if(m_OngoingScrollID > 0)
		{
            GLib.Source.remove(m_OngoingScrollID);
            m_OngoingScrollID = 0;
        }

		var Article = dbUI.get_default().read_article(articleID);

		GLib.Idle.add(() => {
			setBackgroundColor();
			m_fsHead.setTitle(Article.getTitle());
			m_fsHead.setMarked( (Article.getMarked() == ArticleStatus.MARKED) ? true : false);
			m_fsHead.setUnread( (Article.getUnread() == ArticleStatus.UNREAD) ? true : false);

			m_currentView.load_html(
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
			return false;
		});
	}

	public void clearContent()
	{
		m_stack.set_visible_child_name("empty");
		m_currentArticle = "";
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
				Logger.debug("ArticleView: load STARTED");
				string url = m_currentView.get_uri();
				if(url != "file://" + GLib.Environment.get_home_dir() + "/.local/share/feedreader/data/images/")
				{
					Logger.debug("ArticleView: open external url: %s".printf(url));
					try{
						Gtk.show_uri(Gdk.Screen.get_default(), url, Gdk.CURRENT_TIME);
					}
					catch(GLib.Error e){
						Logger.debug("could not open the link in an external browser: %s".printf(e.message));
					}
					m_currentView.stop_loading();
				}
				break;
			case WebKit.LoadEvent.COMMITTED:
				Logger.debug("ArticleView: load COMMITTED");
				if(m_searchTerm != "")
					m_search.search(m_searchTerm, WebKit.FindOptions.CASE_INSENSITIVE, 99);
				break;
			case WebKit.LoadEvent.FINISHED:
				Logger.debug("ArticleView: load FINISHED");
				if(m_stopLoading)
				{
					Logger.debug("ArticleView: loading finished before canceling");
					m_currentView.load_failed.disconnect(loadFailed);
					m_stopLoading = false;
					reload();
				}
				if(m_firstTime)
				{
					setScrollPos(Settings.state().get_int("articleview-scrollpos"));
					Settings.state().set_int("articleview-scrollpos", 0);
					m_currentView.grab_focus();
					m_firstTime = false;
				}
				recalculate.begin((obj, res) => {
					recalculate.end(res);
				});
				break;
		}
	}

	private bool loadFailed(WebKit.LoadEvent event, string failing_uri, void* error)
	{
		GLib.Error e = (GLib.Error)error;
		Logger.debug("ArticleView: load failed: message: \"%s\", domain \"%s\", code \"%i\"".printf(e.message, e.domain.to_string(), e.code));
		if(e.matches(WebKit.NetworkError.quark(), 302))
		{
			Logger.debug("ArticleView: loading canceled " + m_currentArticle);
			WebKit.WebContext.get_default().clear_cache();
			m_currentView.load_failed.disconnect(loadFailed);
			m_stopLoading = false;
			reload();
		}
		return true;
	}

	public void setScrollPos(int pos)
	{
		m_currentView.run_javascript.begin("window.scrollTo(0,%i);".printf(pos), null, (obj, res) => {
			try
			{
				m_currentView.run_javascript.end(res);
			}
			catch(GLib.Error e)
			{
				Logger.error("ArticleView.setScrollPos: %s".printf(e.message));
			}
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
			try
			{
				m_currentView.run_javascript.end(res);
			}
			catch(GLib.Error e)
			{
				Logger.error("ArticleView.setScrollPos: %s".printf(e.message));
			}
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
				try
				{
					m_currentView.run_javascript.end(res);
				}
				catch(GLib.Error e)
				{
					Logger.error("ArticleView: could not get scroll-pos, javascript error: " + e.message);
				}
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
		double upper = getScollUpper() * m_currentView.zoom_level;

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
		var window = ((FeedApp)GLib.Application.get_default()).getWindow();
		if(window != null)
		{
			var background = window.getContent().getBackgroundColor();
            if(background.alpha == 1.0)
            {
                // Don't set a background color that is transparent.
                m_currentView.set_background_color(background);
            }
		}
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
			&& (menuItem.get_action().name != "context-menu-action-9")  // copy text
			&& (menuItem.get_action().name != "context-menu-action-6")  // copy image
			&& (menuItem.get_action().name != "context-menu-action-7")) // copy image address
			{
				menu.remove(menuItem);
			}
		}

		if(hitTest.context_is_image())
		{
			var uri = hitTest.get_image_uri().substring("file://".length);
			var action = new Gtk.Action("save", _("Save image as"), null, null);
			action.activate.connect(() => {
				UtilsUI.saveImageDialog(uri, this.get_toplevel() as Gtk.Window);
			});
			menu.append(new WebKit.ContextMenuItem(action));
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

			if(m_timeout_source_id > 0)
			{
				GLib.Source.remove(m_timeout_source_id);
				m_timeout_source_id = 0;
			}

			m_timeout_source_id = GLib.Timeout.add(m_overlayFade/10, () => {
				if(m_overlayLabel.opacity == 1.0)
				{
					m_timeout_source_id = 0;
					return false;
				}

			    m_overlayLabel.opacity += 0.1;
				return true;
			});

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
			if(m_timeout_source_id > 0)
			{
				GLib.Source.remove(m_timeout_source_id);
				m_timeout_source_id = 0;
			}

			m_timeout_source_id = GLib.Timeout.add(m_overlayFade/10, () => {
				if(m_overlayLabel.opacity == 0.0)
				{
					m_timeout_source_id = 0;
					m_overlayLabel.hide();
					return false;
				}

			    m_overlayLabel.opacity -= 0.1;
				return true;
			});
		}
	}

	private bool leave_fullscreen()
	{
		m_FullscreenVideo = false;
		m_connected = true;
		leaveFullscreen(true);
		return false;
	}

	private bool enter_fullscreen()
	{
		m_FullscreenVideo = true;
		m_connected = false;
		enterFullscreen(true);
		m_fsHead.hide();
		m_prevButton.reveal(false);
		m_nextButton.reveal(false);
		return false;
	}

	public bool fullscreenVideo()
	{
		return m_FullscreenVideo;
	}

	public bool fullscreenArticle()
	{
		return m_FullscreenArticle;
	}

	public void setFullscreenArticle(bool fs)
	{
		m_FullscreenArticle = fs;

		if(fs)
		{
			m_fsHead.show();
			m_currentView.zoom_level = m_FullscreenZoomLevel;

			var window = this.get_toplevel() as readerUI;
			var content = window.getContent();

			if(!content.ArticleListSelectedIsFirst())
				m_nextButton.reveal(true);

			if(!content.ArticleListSelectedIsLast())
				m_prevButton.reveal(true);

		}
		else
		{
			m_currentView.zoom_level = 1.0;
			m_stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
			m_stack.set_transition_duration(100);
			m_fsHead.hide();
			m_prevButton.reveal(false);
			m_nextButton.reveal(false);
		}
	}

	public void setTransition(Gtk.StackTransitionType trans, uint time)
	{
		m_stack.set_transition_type(trans);
		m_stack.set_transition_duration(time);
	}

	private void switchViews()
	{
		m_currentView.load_changed.disconnect(open_link);
		m_currentView.context_menu.disconnect(onContextMenu);
		m_currentView.mouse_target_changed.disconnect(onMouseOver);
		m_currentView.button_press_event.disconnect(onClick);
		m_currentView.button_release_event.disconnect(onRelease);
		m_currentView.motion_notify_event.disconnect(onMouseMotion);
		m_currentView.enter_fullscreen.disconnect(enter_fullscreen);
		m_currentView.leave_fullscreen.disconnect(leave_fullscreen);
		m_currentView.scroll_event.disconnect(onScroll);
		m_currentView.key_press_event.disconnect(onKeyPress);
		m_currentView.web_process_crashed.disconnect(onCrash);

		switch(m_stack.get_visible_child_name())
		{
			case "view1":
				Logger.debug("ArticleView: view2");
				m_currentView = m_view2;
				m_stack.set_visible_child_name("view2");
				GLib.Timeout.add(m_animationDuration + 10, () => {
				    m_view1.load_uri("about:blank");
					return false;
				});

				break;

			case "view2":
			case "empty":
				Logger.debug("ArticleView: view1");
				m_currentView = m_view1;
				m_stack.set_visible_child_name("view1");
				GLib.Timeout.add(m_animationDuration + 10, () => {
				    m_view2.load_uri("about:blank");
					return false;
				});
				break;
		}

		m_currentView.load_changed.connect(open_link);
		m_currentView.context_menu.connect(onContextMenu);
		m_currentView.mouse_target_changed.connect(onMouseOver);
		m_currentView.button_press_event.connect(onClick);
		m_currentView.button_release_event.connect(onRelease);
		m_currentView.motion_notify_event.connect(onMouseMotion);
		m_currentView.enter_fullscreen.connect(enter_fullscreen);
		m_currentView.leave_fullscreen.connect(leave_fullscreen);
		m_currentView.scroll_event.connect(onScroll);
		m_currentView.key_press_event.connect(onKeyPress);
		m_currentView.web_process_crashed.connect(onCrash);

		if(m_FullscreenArticle)
		{
			var window = this.get_toplevel() as readerUI;

			if(window.getContent().ArticleListSelectedIsLast())
				m_prevButton.reveal(false);
			else
				m_prevButton.reveal(true);

			if(window.getContent().ArticleListSelectedIsFirst())
				m_nextButton.reveal(false);
			else
				m_nextButton.reveal(true);
		}
	}

	public void setMarked(bool marked)
	{
		m_fsHead.setMarked(marked);
	}

	public void setUnread(bool unread)
	{
		m_fsHead.setUnread(unread);
	}

	public void nextButtonVisible(bool vis)
	{
		m_nextButton.reveal(vis);
	}

	public void prevButtonVisible(bool vis)
	{
		m_prevButton.reveal(vis);
	}

	private bool onCrash()
	{
		Logger.error("ArticleView: webview crashed");
		m_crashed = true;
		return false;
	}

	public void addMedia(MediaPlayer media)
	{
		if(m_currentMedia == null)
		{
			m_videoOverlay.add_overlay(media);
		}
		else
		{
			m_currentMedia.kill();
			m_videoOverlay.add_overlay(media);
		}

		m_currentMedia = media;
	}

}
