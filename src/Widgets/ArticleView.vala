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

[DBus (name = "org.gnome.FeedReader.ArticleView")]
interface FeedReaderWebExtension : Object
{
	public abstract void recalculate() throws IOError;
    public signal void onClick(string path, int width, int height, string url);
	public signal void message(string message);
}

public class FeedReader.ArticleView : Gtk.Overlay {

	private Gtk.Overlay m_videoOverlay;
	private ArticleViewUrlOverlay m_UrlOverlay;
	private Gtk.Stack m_stack;
	private WebKit.WebView? m_currentView = null;
	private Gdk.RGBA? m_color = null;
	private FullscreenHeader m_fsHead;
	private fullscreenButton m_prevButton;
	private fullscreenButton m_nextButton;
	private ArticleViewLoadProgress m_progress;
	private string m_currentArticle;
	private string? m_nextArticle = null;
	private bool m_busy = false;
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
	private FeedReaderWebExtension m_messenger = null;
	private bool m_connected = false;
	private int m_height = 0;
	private int m_width = 0;
	private bool m_FullscreenVideo = false;
	private bool m_FullscreenArticle = false;
	private double m_FullscreenZoomLevel = 1.25;
	private uint m_animationDuration = 150;


	public ArticleView()
	{
		WebKit.WebContext.get_default().set_cache_model(WebKit.CacheModel.DOCUMENT_BROWSER);

		var emptyView = new Gtk.Label(_("No Article selected."));
		emptyView.get_style_context().add_class("h2");
		emptyView.get_style_context().add_class("dim-label");

		var crashLabel = new Gtk.Label(_("WebKit has crashed"));
		crashLabel.get_style_context().add_class("h2");
		var crashIcon = new Gtk.Image.from_icon_name("face-crying-symbolic", Gtk.IconSize.BUTTON);
		var crashLabelBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
		crashLabelBox.pack_start(crashLabel);
		crashLabelBox.pack_start(crashIcon);
		var crashButton = new Gtk.Button.with_label("view HTML-code");
		crashButton.get_style_context().add_class("preview");
		crashButton.opacity = 0.7;
		crashButton.set_relief(Gtk.ReliefStyle.NONE);
		crashButton.set_focus_on_click(false);
		crashButton.clicked.connect(() => {
			var Article = dbUI.get_default().read_article(m_currentArticle);
			UtilsUI.openInGedit(Article.getHTML());
		});
		var crashView = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
		crashView.set_halign(Gtk.Align.CENTER);
		crashView.set_valign(Gtk.Align.CENTER);
		crashView.pack_start(crashLabelBox);
		crashView.pack_start(crashButton);


		m_UrlOverlay = new ArticleViewUrlOverlay();
		m_stack = new Gtk.Stack();
		m_stack.add_named(emptyView, "empty");
		m_stack.add_named(crashView, "crash");

		m_stack.set_visible_child_name("empty");
		setTransition(Gtk.StackTransitionType.CROSSFADE, m_animationDuration);
		m_stack.set_size_request(450, 0);

		this.size_allocate.connect((allocation) => {
			if(allocation.width != m_width
			|| allocation.height != m_height)
			{
				m_width = allocation.width;
				m_height = allocation.height;
				Logger.debug("ArticleView: size changed");
				setBackgroundColor();
				recalculate.begin((obj, res) => {
					recalculate.end(res);
				});
			}
        });

		m_fsHead = new FullscreenHeader();

		var fullscreenHeaderOverlay = new Gtk.Overlay();
		fullscreenHeaderOverlay.add(m_stack);
		fullscreenHeaderOverlay.add_overlay(m_fsHead);

		m_prevButton = new fullscreenButton("go-previous-symbolic", Gtk.Align.START);
		m_prevButton.click.connect(() => {
			ColumnView.get_default().ArticleListPREV();
		});
		var prevOverlay = new Gtk.Overlay();
		prevOverlay.add(fullscreenHeaderOverlay);
		prevOverlay.add_overlay(m_prevButton);

		m_nextButton = new fullscreenButton("go-next-symbolic", Gtk.Align.END);
		m_nextButton.click.connect(() => {
			ColumnView.get_default().ArticleListNEXT();
		});
		var nextOverlay = new Gtk.Overlay();
		nextOverlay.add(prevOverlay);
		nextOverlay.add_overlay(m_nextButton);

    m_progress = new ArticleViewLoadProgress();

		m_videoOverlay = new Gtk.Overlay();
		this.add(m_videoOverlay);
		this.add_overlay(m_UrlOverlay);

		Gtk.Settings.get_default().notify["gtk-theme-name"].connect(() => {
			setBackgroundColor();
		});

		Gtk.Settings.get_default().notify["gtk-application-prefer-dark-theme"].connect(() => {
			setBackgroundColor();
		});

		Bus.watch_name(BusType.SESSION, "org.gnome.FeedReader.ArticleView", GLib.BusNameWatcherFlags.NONE,
		(connection, name, owner) => { on_extension_appeared(connection, name, owner); }, null);
	}

	private WebKit.WebView getNewView()
	{
		bool smoothScroll = Settings.tweaks().get_boolean("smooth-scrolling");
		var settings = new WebKit.Settings();
		settings.set_enable_accelerated_2d_canvas(true);
		settings.set_enable_html5_database(false);
		settings.set_enable_html5_local_storage(false);
		settings.set_enable_java(false);
		settings.set_enable_media_stream(false);
		settings.set_enable_page_cache(false);
		settings.set_enable_plugins(false);
		settings.set_enable_smooth_scrolling(smoothScroll);
		settings.set_javascript_can_access_clipboard(false);
		settings.set_javascript_can_open_windows_automatically(false);
		settings.set_media_playback_requires_user_gesture(true);
		settings.set_user_agent_with_application_details("FeedReader", AboutInfo.version);

		var view = new WebKit.WebView();
		view.set_settings(settings);
		view.set_events(Gdk.EventMask.POINTER_MOTION_MASK);
		view.set_events(Gdk.EventMask.SCROLL_MASK);
		view.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		view.set_events(Gdk.EventMask.BUTTON_RELEASE_MASK);
		view.set_events(Gdk.EventMask.KEY_PRESS_MASK);
		view.load_changed.connect(open_link);
		view.context_menu.connect(onContextMenu);
		view.mouse_target_changed.connect(onMouseOver);
		view.button_press_event.connect(onClick);
		view.button_release_event.connect(onRelease);
		view.motion_notify_event.connect(onMouseMotion);
		view.enter_fullscreen.connect(enterFullscreenVideo);
		view.leave_fullscreen.connect(leaveFullscreenVideo);
		view.scroll_event.connect(onScroll);
		view.key_press_event.connect(onKeyPress);
		view.web_process_crashed.connect(onCrash);
		view.notify["estimated-load-progress"].connect(printProgress);
		//view.load_failed.connect(loadFailed);
		view.decide_policy.connect(decidePolicy);
		if(m_color != null)
			view.set_background_color(m_color);

		view.show();
		return view;
	}

	public async void fillContent(string articleID)
	{
		Logger.debug(@"ArticleView: load article $articleID");

		if(m_busy)
		{
			Logger.debug(@"ArticleView: currently busy - next article in line is $articleID");
			m_nextArticle = articleID;
			return;
		}

		m_currentArticle = articleID;

		if(m_OngoingScrollID > 0)
		{
            GLib.Source.remove(m_OngoingScrollID);
            m_OngoingScrollID = 0;
        }

		article Article = null;
		SourceFunc callback = fillContent.callback;

		ThreadFunc<void*> run = () => {
			Article = dbUI.get_default().read_article(articleID);
			Idle.add((owned) callback, GLib.Priority.HIGH_IDLE);
			return null;
		};

		new GLib.Thread<void*>("fillContent", run);
		yield;

		GLib.Idle.add(() => {
			Logger.debug("ArticleView: WebView load html");
			switchViews();

			if(m_FullscreenArticle)
				m_currentView.zoom_level = m_FullscreenZoomLevel;
			else
				m_currentView.zoom_level = 1.0;

			m_fsHead.setTitle(Article.getTitle());
			m_fsHead.setMarked( (Article.getMarked() == ArticleStatus.MARKED) ? true : false);
			m_fsHead.setUnread( (Article.getUnread() == ArticleStatus.UNREAD) ? true : false);

			m_progress.reset();
			m_progress.setPercentage(0);
			m_progress.reveal(true);

			m_currentView.load_html(
				UtilsUI.buildArticle(
						Article.getHTML(),
						Article.getTitle(),
						Article.getURL(),
						Article.getAuthor(),
						Article.getDateNice(),
						Article.getFeedID()
					)
				, "file://" + GLib.Environment.get_user_data_dir() + "/feedreader/data/images/");
			this.show_all();
			return false;
		}, GLib.Priority.HIGH_IDLE);
	}

	private void switchViews()
	{
		m_busy = true;
		switch(m_stack.get_visible_child_name())
		{
			case "empty":
			case "crash":
				Logger.debug("ArticleView: %s -> view1".printf(m_stack.get_visible_child_name()));
				m_currentView = getNewView();
				m_stack.add_named(m_currentView, "view1");
				m_stack.set_visible_child_name("view1");
				m_busy = false;
				break;

			case "view1":
      case "view2":
        var article_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        article_box.add(m_progress);
        var visible_child = m_stack.get_visible_child_name();
        var old_child = "view2";
        if (visible_child == "view2"){
          old_child = "view1";
        }
				Logger.debug("ArticleView: view1 -> view2");
				m_currentView = getNewView();
        article_box.add(m_currentView);
				m_stack.add_named(article_box, visible_child);
				m_stack.set_visible_child_name(visible_child);
				GLib.Timeout.add((uint)(1.2*m_animationDuration), () => {
					var oldView = m_stack.get_child_by_name(old_child);
					if(oldView != null)
						m_stack.remove(oldView);
					checkQueue();
					return false;
				}, GLib.Priority.HIGH);
				break;
		}

		if(m_FullscreenArticle)
		{
			if(ColumnView.get_default().ArticleListSelectedIsLast())
				m_prevButton.reveal(false);
			else
				m_prevButton.reveal(true);

			if(ColumnView.get_default().ArticleListSelectedIsFirst())
				m_nextButton.reveal(false);
			else
				m_nextButton.reveal(true);
		}
	}

	private void checkQueue()
	{
		m_busy = false;
		if(m_nextArticle != null)
		{
			Logger.debug(@"ArticleView: load queued article $m_nextArticle");
			var id = m_nextArticle;
			m_nextArticle = null;
			load(id);
		}
	}

	public void clearContent()
	{
		m_busy = true;
		Gtk.Widget? oldView = null;
		if(m_stack.get_visible_child_name() != "empty"
		&& m_stack.get_visible_child_name() != "crash")
			oldView = m_stack.get_visible_child();
		m_progress.reveal(false);
		m_stack.set_visible_child_name("empty");
		GLib.Timeout.add((uint)(1.2*m_animationDuration), () => {
			if(oldView != null)
				m_stack.remove(oldView);
			checkQueue();
			return false;
		}, GLib.Priority.HIGH);
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
				if(url != "file://" + GLib.Environment.get_user_data_dir() + "/feedreader/data/images/")
				{
					Logger.debug(@"ArticleView: open external url: $url");
					try
					{
						Gtk.show_uri(Gdk.Screen.get_default(), url, Gdk.CURRENT_TIME);
					}
					catch(GLib.Error e)
					{
						Logger.debug("could not open the link in an external browser: %s".printf(e.message));
					}
					m_currentView.stop_loading();
				}
				break;
			case WebKit.LoadEvent.COMMITTED:
				Logger.debug("ArticleView: load COMMITTED");
				if(m_searchTerm != "")
					m_currentView.get_find_controller().search(m_searchTerm, WebKit.FindOptions.CASE_INSENSITIVE, 99);
				break;
			case WebKit.LoadEvent.FINISHED:
				Logger.debug("ArticleView: load FINISHED");
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
			default:
				Logger.debug("ArticleView: load ??????");
				break;
		}
	}

	/*private bool loadFailed(WebKit.LoadEvent event, string failing_uri, void* error)
	{
		GLib.Error e = (GLib.Error)error;
		Logger.error("ArticleView: load failed: message: \"%s\", domain \"%s\", code \"%i\"".printf(e.message, e.domain.to_string(), e.code));
		if(e.matches(WebKit.NetworkError.quark(), 302))
		{
			Logger.debug("ArticleView: loading canceled " + m_currentArticle);
			WebKit.WebContext.get_default().clear_cache();
			load();
		}
		return true;
	}*/

	public void setScrollPos(int pos)
	{
		if(m_stack.get_visible_child_name() == "empty"
		|| m_stack.get_visible_child_name() == "crash"
		|| m_currentView == null)
			return;

		m_busy = true;
		m_currentView.run_javascript.begin("window.scrollTo(0,%i);".printf(pos), null, (obj, res) => {
			try
			{
				m_currentView.run_javascript.end(res);
			}
			catch(GLib.Error e)
			{
				Logger.error("ArticleView.setScrollPos: %s".printf(e.message));
			}
			checkQueue();
		});
	}

	private int getScollUpper()
	{
		if(m_stack.get_visible_child_name() == "empty"
		|| m_stack.get_visible_child_name() == "crash"
		|| m_currentView == null)
			return 0;

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

		m_busy = true;
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
			checkQueue();
			loop.quit();
		});

		loop.run();
		return upper;
	}

	public int getScrollPos()
	{
		if(m_stack.get_visible_child_name() == "empty"
		|| m_stack.get_visible_child_name() == "crash"
		|| m_currentView == null)
			return 0;

		// use mainloop to prevent app from shutting down before the result can be fetched
		// ugly but works =/
		// better solution welcome

		int scrollPos = -1;
		var loop = new MainLoop();

		m_busy = true;
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
			checkQueue();
			loop.quit();
		});

		loop.run();
		return scrollPos;
	}


	public void setSearchTerm(string searchTerm)
	{
		m_searchTerm = Utils.parseSearchTerm(searchTerm);
	}


	private void on_extension_appeared(GLib.DBusConnection connection, string name, string owner)
    {
    	try
    	{
			m_connected = true;
			m_messenger = connection.get_proxy_sync("org.gnome.FeedReader.ArticleView", "/org/gnome/FeedReader/ArticleView", GLib.DBusProxyFlags.DO_NOT_AUTO_START, null);
			m_messenger.onClick.connect((path, width, height, url) => {
				var window = MainWindow.get_default();
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
			Logger.error("ArticleView.on_extension_appeared: " + e.message);
		}
    }

	private async void recalculate()
    {
		SourceFunc callback = recalculate.callback;
		ThreadFunc<void*> run = () => {
			try
	    	{
	    		if(m_connected
				&& m_stack.get_visible_child_name() != "empty"
				&& m_stack.get_visible_child_name() != "crash"
				&& m_currentView != null)
	    			m_messenger.recalculate();
	    	}
	    	catch(GLib.IOError e)
	    	{
	    		Logger.warning("ArticleView: recalculate " + e.message);
	    	}
			Idle.add((owned) callback, GLib.Priority.HIGH_IDLE);
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
			GLib.Timeout.add(10, updateDragMomentum, GLib.Priority.HIGH);
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
			m_OngoingScrollID = GLib.Timeout.add(20, ScrollDragRelease, GLib.Priority.HIGH);

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

	public void load(string? id = null)
	{
		string articleID = (id == null) ? m_currentArticle : id;
		fillContent.begin(articleID, (obj, res) => {
			fillContent.end(res);
		});
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
		Logger.debug("ArticleView.setBackgroundColor()");
		var background = ColumnView.get_default().getBackgroundColor();
        if(background.alpha == 1.0)
        {
			// Don't set a background color that is transparent.
			m_color = background;
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
				UtilsUI.saveImageDialog(uri);
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
			var align = Gtk.Align.START;
			double relX = m_posX2/this.get_allocated_height();
			double relY = m_posY2/this.get_allocated_width();

			if(relY >= 0.85 && relX <= 0.5)
				align = Gtk.Align.END;

			m_UrlOverlay.setURL(hitTest.get_link_uri(), align);
			m_UrlOverlay.reveal(true);
		}
		else
		{
			m_UrlOverlay.reveal(false);
		}
	}

	private bool leaveFullscreenVideo()
	{
		Logger.debug("ArticleView: leave fullscreen Video");
		m_FullscreenVideo = false;
		m_connected = true;
		ColumnView.get_default().showPane();
		return false;
	}

	private bool enterFullscreenVideo()
	{
		Logger.debug("ArticleView: enter fullscreen Video");
		m_FullscreenVideo = true;

		// don't try to recalculate imagesizes when playing fullscreen video
		m_connected = false;

		ColumnView.get_default().hidePane();
		m_fsHead.hide();
		m_prevButton.reveal(false);
		m_nextButton.reveal(false);
		return false;
	}

	public void exitFullscreenVideo()
	{
		if(m_currentView != null)
			m_currentView.leave_fullscreen();
	}

	public bool fullscreenVideo()
	{
		return m_FullscreenVideo;
	}

	public bool fullscreenArticle()
	{
		return m_FullscreenArticle;
	}

	public void enterFullscreenArticle()
	{
		Logger.debug("ArticleView: enter fullscreen Article");
		m_FullscreenArticle = true;
		m_fsHead.show();
		m_currentView.zoom_level = m_FullscreenZoomLevel;

		if(!ColumnView.get_default().ArticleListSelectedIsFirst())
			m_nextButton.reveal(true);

		if(!ColumnView.get_default().ArticleListSelectedIsLast())
			m_prevButton.reveal(true);
	}

	public void leaveFullscreenArticle()
	{
		Logger.debug("ArticleView: enter fullscreen Article");
		m_FullscreenArticle = false;
		m_currentView.zoom_level = 1.0;
		setTransition(Gtk.StackTransitionType.CROSSFADE, m_animationDuration);
		m_fsHead.hide();
		m_prevButton.reveal(false);
		m_nextButton.reveal(false);
	}

	public void setTransition(Gtk.StackTransitionType trans, uint time)
	{
		m_stack.set_transition_type(trans);
		m_stack.set_transition_duration(time);
		m_animationDuration = time;
	}

	private void printProgress()
	{
		double progress = m_currentView.estimated_load_progress;
		Logger.debug("ArticleView: loading %u %%".printf((uint)(progress*100)));

		m_progress.setPercentageF(progress);

		if(progress == 1.0)
			m_progress.reveal(false);
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
		m_busy = true;
		m_progress.setPercentage(0);
		m_progress.reveal(false);
		Gtk.Widget? oldView = null;
		if(m_stack.get_visible_child_name() != "crash")
			oldView = m_stack.get_visible_child();
		m_stack.set_visible_child_name("crash");
		GLib.Timeout.add((uint)(1.2*m_animationDuration), () => {
			if(oldView != null)
				m_stack.remove(oldView);
			checkQueue();
			return false;
		}, GLib.Priority.HIGH);
		Logger.error("ArticleView: webview crashed");
		uint major = WebKit.get_major_version();
		uint minor = WebKit.get_minor_version();
		uint micro = WebKit.get_micro_version();
		Logger.debug(@"Running WebKit $major.$minor.$micro");
		return false;
	}

	public void addMedia(MediaPlayer media)
	{
		killMedia();
		m_videoOverlay.add_overlay(media);
		m_currentMedia = media;
	}

	public void killMedia()
	{
		if(m_currentMedia != null)
		{
			m_currentMedia.kill();
		}
	}

	public bool playingMedia()
	{
		if(m_currentMedia == null)
			return false;

		return true;
	}

	public void print()
	{
		if(m_currentView == null)
			return;

		string articleName = dbUI.get_default().read_article(m_currentArticle).getTitle() + ".pdf";

		var settings = new Gtk.PrintSettings();
		settings.set_printer("Print to File");
		settings.set("output-file-format", "pdf");
		settings.set("output-uri", articleName);

		var setup = new Gtk.PageSetup();
		setup.set_left_margin(0, Gtk.Unit.MM);
		setup.set_right_margin(0, Gtk.Unit.MM);

		var op = new WebKit.PrintOperation(m_currentView);
		op.set_print_settings(settings);
		op.set_page_setup(setup);

		op.failed.connect((error) => {
			Logger.debug("ArticleView: print failed: "+ error.message);
		});

		op.finished.connect(() => {
			Logger.debug("ArticleView: print finished");
		});

		//op.print();
		op.run_dialog(MainWindow.get_default());
	}

	private bool decidePolicy(WebKit.PolicyDecision decision, WebKit.PolicyDecisionType type)
	{
		Logger.debug("ArticleView: Policy decision");
		Logger.debug(type.to_string());
		if(type == WebKit.PolicyDecisionType.NEW_WINDOW_ACTION)
		{
			var des = (WebKit.NavigationPolicyDecision)decision;
			if(des.frame_name == "_blank")
			{
				string url = des.get_navigation_action().get_request().get_uri();
				Logger.debug(@"ArticleView: open $url in browser");
				try
				{
					Gtk.show_uri_on_window(MainWindow.get_default(), url, Gdk.CURRENT_TIME);
				}
				catch(GLib.Error e)
				{
					Logger.debug("could not open the link in an external browser: %s".printf(e.message));
				}
				return true;
			}
		}

		return false;
	}

	public void showMediaButton(bool show)
	{
		m_fsHead.showMediaButton(show);
	}

	public void sendEvent(Gdk.EventKey event)
	{
		m_currentView.key_press_event(event);
	}

}
