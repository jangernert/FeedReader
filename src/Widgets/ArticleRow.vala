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

public class FeedReader.articleRow : Gtk.ListBoxRow {

	private article m_article;
	private Gtk.Box m_box;
	private Gtk.Label m_label;
	private Gtk.Revealer m_revealer;
	private Gtk.Image m_icon;
	private Gtk.EventBox m_row_eventbox;
	private Gtk.EventBox m_unread_eventbox;
	private Gtk.EventBox m_marked_eventbox;
	private Gtk.Stack m_unread_stack;
	private Gtk.Stack m_marked_stack;
	private bool m_updated;
	private bool m_hovering_unread;
	private bool m_hovering_marked;
	private bool m_hovering_row;
	public signal void ArticleStateChanged(ArticleStatus status);
	public signal void child_revealed();

	public articleRow(article Article)
	{
		m_article = Article;
		m_hovering_unread = false;
		m_hovering_marked = false;
		m_hovering_row = false;
		m_updated = false;
		m_unread_stack = new Gtk.Stack();
		m_marked_stack = new Gtk.Stack();

		m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		m_box.set_size_request(0, 100);

		string icon_path = GLib.Environment.get_home_dir() + "/.local/share/feedreader/data/feed_icons/";

		string feed_icon_name = icon_path + m_article.getFeedID().replace("/", "_").replace(".", "_") + ".ico";
		Gdk.Pixbuf tmp_icon;
		try{
			if(FileUtils.test(feed_icon_name, GLib.FileTest.EXISTS))
			{
				tmp_icon = new Gdk.Pixbuf.from_file(feed_icon_name);
				Utils.scale_pixbuf(ref tmp_icon, 24);
				m_icon = new Gtk.Image.from_pixbuf(tmp_icon);
			}
			else
			{
				m_icon = new Gtk.Image.from_icon_name("feed-rss", Gtk.IconSize.LARGE_TOOLBAR);
			}
		}
		catch(GLib.Error e){}


		m_label = new Gtk.Label(m_article.getTitle());
		m_label.set_line_wrap_mode(Pango.WrapMode.WORD);
		m_label.set_line_wrap(true);
		m_label.set_lines(2);
		if(m_article.getUnread() == ArticleStatus.UNREAD)
			m_label.get_style_context().add_class("headline-unread-label");
		else
			m_label.get_style_context().add_class("headline-read-label");
		m_label.set_ellipsize (Pango.EllipsizeMode.END);
		m_label.set_alignment(0, 0.5f);

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
			m_unread_stack.set_visible_child_name("unread");
		else if(m_article.getUnread() == ArticleStatus.READ)
			m_unread_stack.set_visible_child_name("empty");

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
			m_marked_stack.set_visible_child_name("marked");
		else if(m_article.getMarked() == ArticleStatus.UNMARKED)
			m_marked_stack.set_visible_child_name("empty");

		m_marked_eventbox.enter_notify_event.connect(markedIconEnter);
		m_marked_eventbox.leave_notify_event.connect(markedIconLeave);
		m_marked_eventbox.button_press_event.connect(markedIconClicked);


		m_row_eventbox = new Gtk.EventBox();
		m_row_eventbox.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
		m_row_eventbox.set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
		m_row_eventbox.enter_notify_event.connect(rowEnter);
		m_row_eventbox.leave_notify_event.connect(rowLeave);



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
				short_preview = m_article.getPreview();
		}


		var body_label = new Gtk.Label(short_preview);
		body_label.opacity = 0.7;
		body_label.get_style_context().add_class("preview");
		body_label.set_alignment(0, 0);
		body_label.set_ellipsize (Pango.EllipsizeMode.END);
		body_label.set_line_wrap_mode(Pango.WrapMode.WORD_CHAR);
		body_label.set_line_wrap(true);
		body_label.set_lines(3);

		var feedLabel = new Gtk.Label(dataBase.getFeedName(m_article.getFeedID()));
		feedLabel.get_style_context().add_class("preview");
		feedLabel.opacity = 0.6;
		feedLabel.set_alignment(0.0f, 0.5f);
		var dateLabel = new Gtk.Label(m_article.getDateNice());
		dateLabel.get_style_context().add_class("preview");
		dateLabel.opacity = 0.6;
		dateLabel.set_alignment(1.0f, 0.5f);
		var date_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		date_box.pack_start(feedLabel, true, true, 0);
		date_box.pack_end(dateLabel, true, true, 0);
		date_box.margin_top = 5;


		var text_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		text_box.margin_end = 15;
		text_box.pack_start(date_box, false, false, 0);
		text_box.pack_start(m_label, true, true, 0);
		text_box.pack_end(body_label, true, true, 2);

		m_box.pack_start(icon_box, false, false, 8);
		m_box.pack_start(text_box, true, true, 0);

		var seperator_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		var separator = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
		separator.set_size_request(0, 2);
		seperator_box.pack_start(m_box, true, true, 0);
		seperator_box.pack_start(separator, false, false, 0);

		m_revealer = new Gtk.Revealer();
		m_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
		m_revealer.add(seperator_box);
		m_revealer.set_reveal_child(false);
		m_revealer.notify["child_revealed"].connect(() => {
			child_revealed();
		});
		m_row_eventbox.add(m_revealer);
		this.add(m_row_eventbox);
		this.show_all();
	}

	private bool rowEnter(Gdk.EventCrossing event)
	{
		if(event.detail == Gdk.NotifyType.INFERIOR)
			return true;

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
			return true;

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
		return true;
	}

	public void toggleUnread()
	{
		string articleID = "";
		var window = ((rssReaderApp)GLib.Application.get_default()).getWindow();
		if(window != null)
		{
			articleID = window.getContent().getSelectedArticle();
		}

		switch(m_article.getUnread())
		{
			case ArticleStatus.READ:
				updateUnread(ArticleStatus.UNREAD);
				if(articleID != "" && articleID == m_article.getArticleID())
				{
					window.getHeaderBar().setRead(true);
				}
				break;
			case ArticleStatus.UNREAD:
				updateUnread(ArticleStatus.READ);
				if(articleID != "" && articleID == m_article.getArticleID())
				{
					window.getHeaderBar().setRead(false);
				}
				break;
		}


		feedDaemon_interface.changeArticle(m_article.getArticleID(), m_article.getUnread());
	}

	public void updateUnread(ArticleStatus unread)
	{
		if(m_article.getUnread() != unread)
		{
			m_article.setUnread(unread);
			ArticleStateChanged(m_article.getUnread());
			if(m_article.getUnread() == ArticleStatus.UNREAD)
			{
				m_label.get_style_context().remove_class("headline-read-label");
				m_label.get_style_context().add_class("headline-unread-label");
				m_unread_stack.set_visible_child_name("unread");
			}
			else
			{
				m_label.get_style_context().remove_class("headline-unread-label");
				m_label.get_style_context().add_class("headline-read-label");
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

	private bool unreadIconEnter()
	{
		m_hovering_unread = true;
		if(m_article.getUnread() == ArticleStatus.READ){
			m_unread_stack.set_visible_child_name("unread");
		}
		else if(m_article.getUnread() == ArticleStatus.UNREAD){
			m_unread_stack.set_visible_child_name("read");
		}
		this.show_all();
		return true;
	}


	public bool unreadIconLeave()
	{
		m_hovering_unread = false;
		if(m_article.getUnread() == ArticleStatus.READ){
			m_unread_stack.set_visible_child_name("read");
		}
		else{
			m_unread_stack.set_visible_child_name("unread");
		}
		this.show_all();
		return true;
	}


	public void removeUnreadIcon()
	{
		m_unread_stack.set_visible_child_name("read");
		this.show_all();
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
		return true;
	}

	public void toggleMarked()
	{
		string articleID = "";
		var window = ((rssReaderApp)GLib.Application.get_default()).getWindow();
		if(window != null)
		{
			articleID = window.getContent().getSelectedArticle();
		}

		switch(m_article.getMarked())
		{
			case ArticleStatus.MARKED:
				updateMarked(ArticleStatus.UNMARKED);
				if(articleID != "" && articleID == m_article.getArticleID())
				{
					window.getHeaderBar().setMarked(false);
				}
				break;

			case ArticleStatus.UNMARKED:
				updateMarked(ArticleStatus.MARKED);
				if(articleID != "" && articleID == m_article.getArticleID())
				{
					window.getHeaderBar().setMarked(true);
				}
				break;
		}

		feedDaemon_interface.changeArticle(m_article.getArticleID(), m_article.getMarked());
	}

	public void updateMarked(ArticleStatus marked)
	{
		if(m_article.getMarked() != marked)
		{
			m_article.setMarked(marked);
			ArticleStateChanged(m_article.getMarked());
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
		if(m_article.getMarked() == ArticleStatus.UNMARKED){
			m_marked_stack.set_visible_child_name("marked");
		}
		else if (m_article.getMarked() == ArticleStatus.MARKED){
			m_marked_stack.set_visible_child_name("unmarked");
		}
		this.show_all();
		return true;
	}


	private bool markedIconLeave()
	{
		m_hovering_marked = false;
		if(m_article.getMarked() == ArticleStatus.UNMARKED){
			m_marked_stack.set_visible_child_name("unmarked");
		}
		else if(m_article.getMarked() == ArticleStatus.MARKED){
			m_marked_stack.set_visible_child_name("marked");
		}
		this.show_all();
		return true;
	}

	public bool isUnread()
	{
		if(m_article.getUnread() == ArticleStatus.UNREAD)
			return true;

		return false;
	}

	public bool isMarked()
	{
		if(m_article.getMarked() == ArticleStatus.MARKED)
			return true;

		return false;
	}

	public ArticleStatus getUnread()
	{
		return m_article.getUnread();
	}

	public ArticleStatus getMarked()
	{
		return m_article.getMarked();
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

	public void reveal(bool reveal, uint duration = 500)
	{
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
		foreach(string tag in m_article.getTags())
		{
			if(tag == tagID)
				return true;
		}

		return false;
	}

	public void removeTag(string tagID)
	{
		m_article.getTags().remove(tagID);
	}

	public int getSortID()
	{
		return m_article.getSortID();
	}

}
