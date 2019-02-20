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

public class FeedReader.ArticleRow : Gtk.ListBoxRow {
	
	private Article m_article;
	private Gtk.Label m_label;
	private Gtk.Image m_icon;
	private Gtk.Revealer m_revealer;
	private Gtk.EventBox m_eventBox;
	private Gtk.EventBox m_unread_eventbox;
	private Gtk.EventBox m_marked_eventbox;
	private Gtk.Stack m_unread_stack;
	private Gtk.Stack m_marked_stack;
	private bool m_updated = false;
	private bool m_hovering_unread = false;
	private bool m_hovering_marked = false;
	private bool m_hovering_row = false;
	private bool m_populated = false;
	public signal void rowStateChanged(ArticleStatus status);
	
	public ArticleRow(Article article)
	{
		m_article = article;
		
		m_revealer = new Gtk.Revealer();
		m_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
		m_revealer.set_reveal_child(false);
		this.set_size_request(0, 100);
		this.add(m_revealer);
		this.show_all();
		
		GLib.Idle.add(populate, GLib.Priority.HIGH_IDLE);
	}
	
	~ArticleRow()
	{
		if(m_unread_eventbox != null)
		{
			m_unread_eventbox.enter_notify_event.disconnect(unreadIconEnter);
			m_unread_eventbox.leave_notify_event.disconnect(unreadIconLeave);
			m_unread_eventbox.button_press_event.disconnect(unreadIconClicked);
		}
		
		if(m_marked_eventbox != null)
		{
			m_marked_eventbox.enter_notify_event.disconnect(markedIconEnter);
			m_marked_eventbox.leave_notify_event.disconnect(markedIconLeave);
			m_marked_eventbox.button_press_event.disconnect(markedIconClicked);
		}
		
		if(m_eventBox != null)
		{
			m_eventBox.enter_notify_event.disconnect(rowEnter);
			m_eventBox.leave_notify_event.disconnect(rowLeave);
			m_eventBox.button_press_event.disconnect(rowClick);
		}
		
		this.drag_begin.disconnect(onDragBegin);
		this.drag_data_get.disconnect(onDragDataGet);
		this.drag_failed.disconnect(onDragFailed);
	}
	
	private bool populate()
	{
		m_unread_stack = new Gtk.Stack();
		m_marked_stack = new Gtk.Stack();
		m_unread_stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		m_marked_stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		m_unread_stack.set_transition_duration(50);
		m_marked_stack.set_transition_duration(50);
		
		m_label = new Gtk.Label(m_article.getTitle());
		m_label.set_line_wrap_mode(Pango.WrapMode.WORD);
		m_label.set_line_wrap(true);
		m_label.set_lines(2);
		if(m_article.getUnread() == ArticleStatus.UNREAD)
		{
			m_label.get_style_context().add_class("headline-unread");
		}
		else
		{
			m_label.get_style_context().add_class("headline-read");
		}
		m_label.set_ellipsize(Pango.EllipsizeMode.END);
		m_label.set_alignment(0.0f, 0.2f);
		m_label.set_tooltip_text(m_article.getTitle());
		
		var icon_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		icon_box.set_size_request(24, 0);
		
		var marked_icon = new Gtk.Image.from_icon_name("feed-starred", Gtk.IconSize.SMALL_TOOLBAR);
		var unread_icon = new Gtk.Image.from_icon_name("feed-article-unread", Gtk.IconSize.SMALL_TOOLBAR);
		var unmarked_icon = new Gtk.Image.from_icon_name("feed-non-starred", Gtk.IconSize.SMALL_TOOLBAR);
		var read_icon = new Gtk.Image.from_icon_name("feed-article-read", Gtk.IconSize.SMALL_TOOLBAR);
		
		m_unread_stack.add_named(unread_icon, "unread");
		m_unread_stack.add_named(read_icon, "read");
		m_unread_stack.add_named(new Gtk.Label(""), "empty");
		m_marked_stack.add_named(marked_icon, "marked");
		m_marked_stack.add_named(unmarked_icon, "unmarked");
		m_marked_stack.add_named(new Gtk.Label(""), "empty");
		
		m_unread_eventbox = new Gtk.EventBox();
		m_unread_eventbox.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		m_unread_eventbox.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
		m_unread_eventbox.set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
		m_unread_eventbox.set_size_request(16, 16);
		m_unread_eventbox.add(m_unread_stack);
		m_unread_eventbox.show_all();
		if(m_article.getUnread() == ArticleStatus.UNREAD)
		{
			m_unread_stack.set_visible_child_name("unread");
		}
		else if(m_article.getUnread() == ArticleStatus.READ)
		{
			m_unread_stack.set_visible_child_name("empty");
		}
		else
		{
			Logger.warning("ArticleRow: id %s - unread status undefined %i".printf(m_article.getArticleID(), m_article.getUnread()));
		}
		
		m_unread_eventbox.enter_notify_event.connect(unreadIconEnter);
		m_unread_eventbox.leave_notify_event.connect(unreadIconLeave);
		m_unread_eventbox.button_press_event.connect(unreadIconClicked);
		
		
		m_marked_eventbox = new Gtk.EventBox();
		m_marked_eventbox.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		m_marked_eventbox.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
		m_marked_eventbox.set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
		m_marked_eventbox.set_size_request(16, 16);
		m_marked_eventbox.add(m_marked_stack);
		m_marked_eventbox.show_all();
		if(m_article.getMarked() == ArticleStatus.MARKED)
		{
			m_marked_stack.set_visible_child_name("marked");
		}
		else if(m_article.getMarked() == ArticleStatus.UNMARKED)
		{
			m_marked_stack.set_visible_child_name("empty");
		}
		else
		{
			Logger.warning("ArticleRow: id %s - unread status undefined %i".printf(m_article.getArticleID(), m_article.getMarked()));
		}
		
		m_marked_eventbox.enter_notify_event.connect(markedIconEnter);
		m_marked_eventbox.leave_notify_event.connect(markedIconLeave);
		m_marked_eventbox.button_press_event.connect(markedIconClicked);
		
		m_icon = createFavIcon();
		
		icon_box.pack_start(m_icon, true, true, 0);
		icon_box.pack_end(m_unread_eventbox, false, false, 10);
		icon_box.pack_end(m_marked_eventbox, false, false, 0);
		
		string short_preview = "";
		
		if(m_article.getPreview() != "")
		{
			if(m_article.getPreview().length > 300)
			{
				short_preview = m_article.getPreview().slice(0, 300);
				short_preview = short_preview.slice(0, short_preview.last_index_of(" "));
				short_preview = short_preview.strip();
			}
			else
			{
				short_preview = m_article.getPreview();
			}
		}
		
		
		var body_label = new Gtk.Label(short_preview);
		body_label.opacity = 0.7;
		body_label.get_style_context().add_class("preview");
		body_label.set_alignment(0.0f, 0.0f);
		body_label.set_ellipsize (Pango.EllipsizeMode.END);
		body_label.set_line_wrap_mode(Pango.WrapMode.WORD_CHAR);
		body_label.set_line_wrap(true);
		body_label.set_lines(2);
		
		var feed = DataBase.readOnly().read_feed(m_article.getFeedID());
		var feedLabel = new Gtk.Label(feed != null ? feed.getTitle() : "");
		feedLabel.get_style_context().add_class("preview");
		feedLabel.opacity = 0.6;
		feedLabel.set_alignment(0.0f, 0.5f);
		feedLabel.set_ellipsize(Pango.EllipsizeMode.END);
		var dateLabel = new Gtk.Label(m_article.getDateNice());
		dateLabel.get_style_context().add_class("preview");
		dateLabel.opacity = 0.6;
		dateLabel.set_alignment(1.0f, 0.5f);
		var date_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
		date_box.pack_start(feedLabel, true, true, 0);
		date_box.pack_end(dateLabel, true, true, 0);
		
		
		var text_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		text_box.margin_end = 15;
		text_box.margin_top = 8;
		text_box.margin_bottom = 8;
		text_box.pack_start(date_box, true, true, 0);
		text_box.pack_start(m_label, true, true, 0);
		text_box.pack_end(body_label, true, true, 0);
		
		var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		box.pack_start(icon_box, false, false, 8);
		box.pack_start(text_box, true, true, 0);
		
		m_eventBox = new Gtk.EventBox();
		m_eventBox.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
		m_eventBox.set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
		m_eventBox.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		m_eventBox.enter_notify_event.connect(rowEnter);
		m_eventBox.leave_notify_event.connect(rowLeave);
		m_eventBox.button_press_event.connect(rowClick);
		m_eventBox.add(box);
		m_eventBox.show_all();
		
		// Make the this widget a DnD source.
		if(!Settings.general().get_boolean("only-feeds")
			&& FeedReaderBackend.get_default().isOnline()
		&& FeedReaderBackend.get_default().supportTags())
		{
			const Gtk.TargetEntry[] provided_targets = {
				{ "STRING",     0, DragTarget.TAG }
			};
			
			Gtk.drag_source_set(
				this,
				Gdk.ModifierType.BUTTON1_MASK,
				provided_targets,
				Gdk.DragAction.COPY
			);
			
			this.drag_begin.connect(onDragBegin);
			this.drag_data_get.connect(onDragDataGet);
			this.drag_failed.connect(onDragFailed);
		}
		
		m_revealer.add(m_eventBox);
		m_populated = true;
		return false;
	}
	
	private void onDragBegin(Gtk.Widget widget, Gdk.DragContext context)
	{
		Logger.debug("ArticleRow: onDragBegin");
		Gtk.drag_set_icon_widget(context, getFeedIconWindow(), 0, 0);
	}
	
	public void onDragDataGet(Gtk.Widget widget, Gdk.DragContext context, Gtk.SelectionData selection_data, uint target_type, uint time)
	{
		Logger.debug("ArticleRow: onDragDataGet");
		
		if(target_type == DragTarget.TAG)
		{
			selection_data.set_text(m_article.getArticleID(), -1);
		}
		else
		{
			selection_data.set_text("ERROR!!!!!1111eleven", -1);
		}
	}
	
	private bool onDragFailed(Gdk.DragContext context, Gtk.DragResult result)
	{
		Logger.debug("ArticleRow: onDragFailed " + result.to_string());
		return false;
	}
	
	private Gtk.Image createFavIcon()
	{
		var icon = new Gtk.Image.from_icon_name("feed-rss-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
		
		Feed? feed = DataBase.readOnly().read_feed(m_article.getFeedID());
		var favicon = FavIcon.for_feed(feed);
		favicon.get_surface.begin((obj, res) => {
			var surface = favicon.get_surface.end(res);
			if(surface != null)
			{
				icon.surface = surface;
			}
		});
		ulong handler_id = favicon.surface_changed.connect((feed, surface) => {
			icon.surface = surface;
		});
		icon.destroy.connect(() => {
			favicon.disconnect(handler_id);
		});
		
		return icon;
	}
	
	private Gtk.Window getFeedIconWindow()
	{
		var icon = createFavIcon();
		var window = new Gtk.Window(Gtk.WindowType.POPUP);
		var visual = window.get_screen().get_rgba_visual();
		window.set_visual(visual);
		window.get_style_context().add_class("transparentBG");
		window.add(icon);
		window.show_all();
		return window;
	}
	
	
	private bool rowEnter(Gdk.EventCrossing event)
	{
		if(event.detail == Gdk.NotifyType.INFERIOR)
		{
			return true;
		}
		
		m_hovering_row = true;
		
		switch(m_article.getUnread())
		{
			case ArticleStatus.READ:
			m_unread_stack.set_visible_child_name("read");
			break;
			case ArticleStatus.UNREAD:
			m_unread_stack.set_visible_child_name("unread");
			break;
		}
		
		switch(m_article.getMarked())
		{
			case ArticleStatus.MARKED:
			m_marked_stack.set_visible_child_name("marked");
			break;
			case ArticleStatus.UNMARKED:
			m_marked_stack.set_visible_child_name("unmarked");
			break;
		}
		
		return true;
	}
	
	private bool rowLeave(Gdk.EventCrossing event)
	{
		if(event.detail == Gdk.NotifyType.INFERIOR)
		{
			return true;
		}
		
		m_hovering_row = false;
		
		switch(m_article.getUnread())
		{
			case ArticleStatus.READ:
			m_unread_stack.set_visible_child_name("empty");
			break;
			case ArticleStatus.UNREAD:
			m_unread_stack.set_visible_child_name("unread");
			break;
		}
		
		switch(m_article.getMarked())
		{
			case ArticleStatus.MARKED:
			m_marked_stack.set_visible_child_name("marked");
			break;
			case ArticleStatus.UNMARKED:
			m_marked_stack.set_visible_child_name("empty");
			break;
		}
		
		return true;
	}
	
	private bool rowClick(Gdk.EventButton event)
	{
		switch (event.button) {
			//if double left clicked, open the article in an external browser:
			case 1:
			if (event.type != Gdk.EventType.@2BUTTON_PRESS)
			{
				return false;
			}
			
			try{
				Gtk.show_uri_on_window(MainWindow.get_default(), m_article.getURL(), Gdk.CURRENT_TIME);
			}
			catch(GLib.Error e) {
				Logger.debug("could not open the link in an external browser: %s".printf(e.message));
			}
			break;
			
			//If right clicked, show context menu:
			case 3:
			this.onRightClick();
			break;
			
			//Otherwise return false;
			default:
			return false;
		}
		
		return true;
	}
	
	private void onRightClick()
	{
		var pop = new Gtk.Popover(this);
		var copyArticleURL_action = new GLib.SimpleAction("copyArticleURL", null);
		copyArticleURL_action.activate.connect(() => {
			copyArticleURL(m_article.getArticleID());
		});
		copyArticleURL_action.set_enabled(true);
		FeedReaderApp.get_default().add_action(copyArticleURL_action);
		
		var menu = new GLib.Menu();
		menu.append(_("Copy URL"), "copyArticleURL");
		
		pop.set_position(Gtk.PositionType.BOTTOM);
		pop.bind_model(menu, "app");
		pop.closed.connect(() => {
			this.unset_state_flags(Gtk.StateFlags.PRELIGHT);
		});
		
		pop.show();
		this.set_state_flags(Gtk.StateFlags.PRELIGHT, true);
	}
	
	
	private bool unreadIconClicked(Gdk.EventButton event)
	{
		switch(event.type)
		{
			case Gdk.EventType.BUTTON_RELEASE:
			case Gdk.EventType.@2BUTTON_PRESS:
			case Gdk.EventType.@3BUTTON_PRESS:
			return false;
		}
		toggleUnread();
		rowStateChanged(m_article.getUnread());
		return true;
	}
	
	public ArticleStatus toggleUnread()
	{
		var view = ColumnView.get_default();
		Article? selectedArticle = ColumnView.get_default().getSelectedArticle();
		
		switch(m_article.getUnread())
		{
			case ArticleStatus.READ:
			updateUnread(ArticleStatus.UNREAD);
			break;
			case ArticleStatus.UNREAD:
			updateUnread(ArticleStatus.READ);
			break;
		}
		
		if(selectedArticle != null && selectedArticle.getArticleID() == m_article.getArticleID())
		{
			view.getHeader().setRead(m_article.getUnread());
		}
		
		FeedReaderBackend.get_default().updateArticleRead(m_article);
		show_all();
		return m_article.getUnread();
	}
	
	public void updateUnread(ArticleStatus unread)
	{
		if(m_article.getUnread() != unread)
		{
			m_article.setUnread(unread);
			if(m_populated)
			{
				if(m_article.getUnread() == ArticleStatus.UNREAD)
				{
					m_label.get_style_context().remove_class("headline-read");
					m_label.get_style_context().add_class("headline-unread");
					m_unread_stack.set_visible_child_name("unread");
				}
				else
				{
					m_label.get_style_context().remove_class("headline-unread");
					m_label.get_style_context().add_class("headline-read");
					if(m_hovering_row)
					{
						m_unread_stack.set_visible_child_name("read");
					}
					else
					{
						m_unread_stack.set_visible_child_name("empty");
					}
				}
			}
		}
	}
	
	private bool unreadIconEnter()
	{
		m_hovering_unread = true;
		if(m_article.getUnread() == ArticleStatus.READ)
		{
			m_unread_stack.set_visible_child_name("unread");
		}
		else if(m_article.getUnread() == ArticleStatus.UNREAD)
		{
			m_unread_stack.set_visible_child_name("read");
		}
		this.show_all();
		return true;
	}
	
	
	private bool unreadIconLeave()
	{
		m_hovering_unread = false;
		if(m_article.getUnread() == ArticleStatus.READ)
		{
			m_unread_stack.set_visible_child_name("read");
		}
		else
		{
			m_unread_stack.set_visible_child_name("unread");
		}
		this.show_all();
		return true;
	}
	
	private bool markedIconClicked(Gdk.EventButton event)
	{
		switch(event.type)
		{
			case Gdk.EventType.BUTTON_RELEASE:
			case Gdk.EventType.@2BUTTON_PRESS:
			case Gdk.EventType.@3BUTTON_PRESS:
			return false;
		}
		toggleMarked();
		rowStateChanged(m_article.getMarked());
		return true;
	}
	
	public ArticleStatus toggleMarked()
	{
		var view = ColumnView.get_default();
		Article? selectedArticle = ColumnView.get_default().getSelectedArticle();
		
		switch(m_article.getMarked())
		{
			case ArticleStatus.MARKED:
			updateMarked(ArticleStatus.UNMARKED);
			break;
			case ArticleStatus.UNMARKED:
			updateMarked(ArticleStatus.MARKED);
			break;
		}
		
		if(selectedArticle != null && selectedArticle.getArticleID() == m_article.getArticleID())
		{
			view.getHeader().setMarked(m_article.getMarked());
		}
		
		FeedReaderBackend.get_default().updateArticleMarked(m_article);
		this.show_all();
		return m_article.getMarked();
	}
	
	public void updateMarked(ArticleStatus marked)
	{
		if(m_article.getMarked() != marked)
		{
			m_article.setMarked(marked);
			switch(m_article.getMarked())
			{
				case ArticleStatus.MARKED:
				m_marked_stack.set_visible_child_name("marked");
				break;
				
				case ArticleStatus.UNMARKED:
				if(m_hovering_row)
				{
					m_marked_stack.set_visible_child_name("unmarked");
				}
				else
				{
					m_marked_stack.set_visible_child_name("empty");
				}
				break;
			}
		}
	}
	
	private bool markedIconEnter()
	{
		m_hovering_marked = true;
		if(m_article.getMarked() == ArticleStatus.UNMARKED)
		{
			m_marked_stack.set_visible_child_name("marked");
		}
		else if (m_article.getMarked() == ArticleStatus.MARKED)
		{
			m_marked_stack.set_visible_child_name("unmarked");
		}
		this.show_all();
		return true;
	}
	
	
	private bool markedIconLeave()
	{
		m_hovering_marked = false;
		if(m_article.getMarked() == ArticleStatus.UNMARKED)
		{
			m_marked_stack.set_visible_child_name("unmarked");
		}
		else if(m_article.getMarked() == ArticleStatus.MARKED)
		{
			m_marked_stack.set_visible_child_name("marked");
		}
		this.show_all();
		return true;
	}
	
	public Article getArticle()
	{
		return m_article;
	}
	
	public string getName()
	{
		return m_article.getTitle();
	}
	
	public string getID()
	{
		return m_article.getArticleID();
	}
	
	public GLib.DateTime getDate()
	{
		return m_article.getDate();
	}
	
	public string getDateStr()
	{
		return m_article.getDate().format("%Y-%m-%d %H:%M:%S");
	}
	
	public bool getUpdated()
	{
		return m_updated;
	}
	
	public void setUpdated(bool updated)
	{
		m_updated = updated;
	}
	
	public bool isHoveringUnread()
	{
		return m_hovering_unread;
	}
	
	public bool isHoveringMarked()
	{
		return m_hovering_marked;
	}
	
	public string getURL()
	{
		return m_article.getURL();
	}
	
	public void copyArticleURL(string article_id){
		/*
		Copy selected article url to clipboard
		*/
		if (article_id != "")
		{
			Article? article =  DataBase.readOnly().read_article(article_id);
			if (article != null)
			{
				string article_url = article.getURL();
				Gdk.Display display = MainWindow.get_default().get_display ();
				Gtk.Clipboard clipboard = Gtk.Clipboard.get_for_display (display, Gdk.SELECTION_CLIPBOARD);
				
				clipboard.set_text(article_url, article_url.length);
			}
		}
	}
	
	public void reveal(bool reveal, uint duration = 500)
	{
		if(!reveal)
		{
			this.set_size_request(0, 0);
		}
		m_revealer.set_transition_duration(duration);
		m_revealer.set_reveal_child(reveal);
	}
	
	public bool isRevealed()
	{
		return m_revealer.get_child_revealed();
	}
	
	public bool isBeingRevealed()
	{
		return m_revealer.get_reveal_child();
	}
	
	public bool hasTag(string tagID)
	{
		foreach(string tag in m_article.getTagIDs())
		{
			if(tag == tagID)
			{
				return true;
			}
		}
		
		return false;
	}
	
	public void removeTag(string tagID)
	{
		m_article.getTagIDs().remove(tagID);
	}
	
	public int getSortID()
	{
		return m_article.getSortID();
	}
	
	public bool haveMedia()
	{
		return m_article.haveMedia();
	}
}
