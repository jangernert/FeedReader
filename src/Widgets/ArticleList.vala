public class FeedReader.articleList : Gtk.Stack {

	private Gtk.ScrolledWindow m_currentScroll;
	private Gtk.ScrolledWindow m_scroll1;
	private Gtk.ScrolledWindow m_scroll2;
	private Gtk.ListBox m_currentList;
	private Gtk.ListBox m_List1;
	private Gtk.ListBox m_List2;
	private Gtk.Adjustment m_current_adjustment;
	private Gtk.Adjustment m_scroll1_adjustment;
	private Gtk.Adjustment m_scroll2_adjustment;
	private Gtk.Label m_emptyList;
	private string m_emptyListString;
	private double m_lmit;
	private int m_displayed_articles;
	private string m_current_feed_selected;
	private bool m_only_unread;
	private bool m_only_marked;
	private string m_searchTerm;
	private int m_limit;
	private int m_IDtype;
	private bool m_limitScroll;
	private int m_threadCount;
	public signal void row_activated(articleRow? row);


	public articleList () {
		m_lmit = 0.8;
		m_displayed_articles = 0;
		m_current_feed_selected = FeedID.ALL;
		m_IDtype = FeedList.FEED;
		m_searchTerm = "";
		m_limit = 15;
		m_limitScroll = false;
		m_threadCount = 0;

		m_emptyListString = _("None of the %i Articles in the database fit the current filters.");
		m_emptyList = new Gtk.Label(m_emptyListString.printf(dataBase.getArticelCount()));
		m_emptyList.get_style_context().add_class("emptyView");
		m_emptyList.set_ellipsize (Pango.EllipsizeMode.END);
		m_emptyList.set_line_wrap_mode(Pango.WrapMode.WORD);
		m_emptyList.set_line_wrap(true);
		m_emptyList.set_lines(3);
		m_emptyList.set_margin_left(30);
		m_emptyList.set_margin_right(30);
		m_emptyList.set_justify(Gtk.Justification.CENTER);

		m_List1 = new Gtk.ListBox();
		m_List1.set_selection_mode(Gtk.SelectionMode.BROWSE);
		m_List1.get_style_context().add_class("article-list");
		m_List2 = new Gtk.ListBox();
		m_List2.set_selection_mode(Gtk.SelectionMode.BROWSE);
		m_List2.get_style_context().add_class("article-list");


		m_scroll1 = new Gtk.ScrolledWindow(null, null);
		m_scroll1.set_size_request(400, 500);
		m_scroll1.add(m_List1);
		m_scroll2 = new Gtk.ScrolledWindow(null, null);
		m_scroll2.set_size_request(400, 500);
		m_scroll2.add(m_List2);


		m_scroll1_adjustment = m_scroll1.get_vadjustment();
		m_scroll1_adjustment.value_changed.connect(() => {
			var current = m_scroll1_adjustment.get_value();
			var page = m_scroll1_adjustment.get_page_size();
			var max = m_scroll1_adjustment.get_upper();
			if((current + page)/max > m_lmit && !m_limitScroll)
			{
				createHeadlineList(true);
			}
		});

		m_scroll2_adjustment = m_scroll2.get_vadjustment();
		m_scroll2_adjustment.value_changed.connect(() => {
			var current = m_scroll2_adjustment.get_value();
			var page = m_scroll2_adjustment.get_page_size();
			var max = m_scroll2_adjustment.get_upper();
			if((current + page)/max > m_lmit && !m_limitScroll)
			{
				createHeadlineList(true);
			}
		});


		m_List1.row_activated.connect((row) => {
			row_activated((articleRow)row);
		});
		m_List2.row_activated.connect((row) => {
			row_activated((articleRow)row);
		});

		m_List1.key_press_event.connect((event) => {
			key_pressed(event);
			return true;
		});

		m_List2.key_press_event.connect((event) => {
			key_pressed(event);
			return true;
		});

		m_currentList = m_List1;
		m_currentScroll = m_scroll1;
		m_current_adjustment = m_scroll1_adjustment;

		this.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		this.set_transition_duration(100);
		this.add_named(m_scroll1, "list1");
		this.add_named(m_scroll2, "list2");
		this.add_named(m_emptyList, "empty");
	}

	private void key_pressed(Gdk.EventKey event)
	{
		if(event.keyval == Gdk.Key.Down)
			move(true);
		else if(event.keyval == Gdk.Key.Up)
			move(false);
	}


	private void move(bool down)
	{
		articleRow selected_row = m_currentList.get_selected_row() as articleRow;


		var ArticleListChildren = m_currentList.get_children();

		if(!down){
			ArticleListChildren.reverse();
		}

		int current = ArticleListChildren.index(selected_row);

		current++;
		if(current < ArticleListChildren.length())
		{
			articleRow current_article = ArticleListChildren.nth_data(current) as articleRow;
			m_currentList.select_row(current_article);
			row_activated(current_article);

			var currentPos = m_current_adjustment.get_value();
			var max = m_current_adjustment.get_upper();
			var offset = (max)/ArticleListChildren.length();

			if(down)
			{
				m_current_adjustment.set_value(currentPos + offset);
			}
			else
			{
				m_current_adjustment.set_value(currentPos - offset);
			}

			m_currentScroll.set_vadjustment(m_current_adjustment);
			current_article.activate();
		}
	}


	public int getAmountOfRowsToLoad()
	{
		return (int)m_currentList.get_children().length();
	}


	private void restoreSelectedRow()
	{
		string selectedRow = settings_state.get_string("articlelist-selected-row");

		if(selectedRow != "")
		{
			var FeedChildList = m_currentList.get_children();
			foreach(Gtk.Widget row in FeedChildList)
			{
				var tmpRow = row as articleRow;
				if(tmpRow != null && tmpRow.getID() == selectedRow)
				{
					m_currentList.select_row(tmpRow);
					tmpRow.activate();
					settings_state.set_string("articlelist-selected-row", "");
					return;
				}
			}
		}
	}


	void restoreScrollPos(Object sender, ParamSpec property)
	{
		logger.print(LogMessage.DEBUG, "ArticleList: restore ScrollPos");
		m_current_adjustment.notify["upper"].disconnect(restoreScrollPos);
		setScrollPos(settings_state.get_double("articlelist-scrollpos"));

		settings_state.set_int("articlelist-new-rows", 0);
		settings_state.set_int("articlelist-row-amount", 15);
		settings_state.set_double("articlelist-scrollpos",  0);
	}


	private void setScrollPos(double pos)
	{
		double RowVSpace = 102;
		double additionalScroll = RowVSpace * settings_state.get_int("articlelist-new-rows");
		double newPos = pos + additionalScroll;

		m_current_adjustment = m_currentScroll.get_vadjustment();
		m_current_adjustment.set_value(newPos);
		m_currentScroll.set_vadjustment(m_current_adjustment);
	}


	public double getScrollPos()
	{
		return m_current_adjustment.get_value();
	}

	private int shortenArticleList()
	{
		double RowVSpace = 102;
		int stillInViewport = (int)((settings_state.get_double("articlelist-scrollpos")+900)/RowVSpace);
		//settings_state.get_int("articlelist-new-rows")
		if(stillInViewport < settings_state.get_int("articlelist-row-amount"))
		{
			return stillInViewport+15;
		}
		else if(settings_state.get_int("articlelist-row-amount") == 0)
			return 15;

		return settings_state.get_int("articlelist-row-amount");
	}


	public void setOnlyUnread(bool only_unread)
	{
		m_only_unread = only_unread;
	}

	public void setOnlyMarked(bool only_marked)
	{
		m_only_marked = only_marked;
	}

	public void setSearchTerm(string searchTerm)
	{
		m_searchTerm = searchTerm;
	}

	public void setSelectedFeed(string feedID)
	{
		m_current_feed_selected = feedID;
	}

	public void setSelectedType(int type)
	{
		m_IDtype = type;
	}

	public string getSelectedArticle()
	{
		articleRow selected_row = m_currentList.get_selected_row() as articleRow;
		if(selected_row != null)
			return selected_row.getID();

		if(m_currentList.get_children().length() == 0)
			return "empty";

		return "";
	}


	public async void createHeadlineList(bool add = false)
	{
		logger.print(LogMessage.DEBUG, "ArticleList: create HeadlineList");
		GLib.List<article> articles = new GLib.List<article>();

		m_threadCount++;
		int threadID = m_threadCount;
		bool hasContent = true;

		// dont allow new articles being created due to scrolling for 0.5s
		limitScroll();

		SourceFunc callback = createHeadlineList.callback;
		//-----------------------------------------------------------------------------------------------------------------------------------------------------
		ThreadFunc<void*> run = () => {
			m_limit = shortenArticleList() + settings_state.get_int("articlelist-new-rows");
			logger.print(LogMessage.DEBUG, "limit: " + m_limit.to_string());

			logger.print(LogMessage.DEBUG, "load articles from db");
			articles = dataBase.read_articles(m_current_feed_selected, m_IDtype, m_only_unread, m_only_marked, m_searchTerm, m_limit, m_displayed_articles);
			logger.print(LogMessage.DEBUG, "actual articles loaded: " + articles.length().to_string());
			if(articles.length() == 0)
			{
				hasContent = false;
			}

			Idle.add((owned) callback);
			return null;
		};
		//-----------------------------------------------------------------------------------------------------------------------------------------------------

		new GLib.Thread<void*>("createHeadlineList", run);
		yield;


		if(!(threadID < m_threadCount))
		{
			if(hasContent)
			{
				if(m_currentList == m_List1)		 this.set_visible_child_full("list1", Gtk.StackTransitionType.CROSSFADE);
				else if(m_currentList == m_List2)   this.set_visible_child_full("list2", Gtk.StackTransitionType.CROSSFADE);

				foreach(var item in articles)
				{
					while(Gtk.events_pending())
					{
						Gtk.main_iteration();
					}

					if(threadID < m_threadCount)
						break;

					var tmpRow = new articleRow(
							                        item.m_title,
							                        item.m_unread,
							                        item.m_feedID.to_string(),
							                        item.m_url,
							                        item.m_feedID,
							                        item.getArticleID(),
							                        item.m_marked,
							                        item.getSortID(),
							                        item.getPreview(),
													item.getDate()
							                        );

					while(Gtk.events_pending())
					{
						Gtk.main_iteration();
					}

					if(threadID < m_threadCount)
						break;

					m_currentList.add(tmpRow);
					m_displayed_articles++;

					if(add)
						tmpRow.reveal(true);
					else
						tmpRow.reveal(true, 150);
				}

				if(!add)
				{
					m_current_adjustment.notify["upper"].connect(restoreScrollPos);
					restoreSelectedRow();
				}

				if(settings_state.get_boolean("no-animations"))
					settings_state.set_boolean("no-animations", false);
			}
			else if(!add)
			{
				m_emptyList.set_text(m_emptyListString.printf(dataBase.getArticelCount()));
				this.set_visible_child_name("empty");
			}
		}
	}

	public void newHeadlineList()
	{
		logger.print(LogMessage.DEBUG, "ArticleList: delete HeadlineList");
		string selectedArticle = getSelectedArticle();

		if(selectedArticle != "empty")
			settings_state.set_string("articlelist-selected-row", selectedArticle);

		if(m_currentList == m_List1)
		{
			m_currentList = m_List2;
			m_currentScroll = m_scroll2;
			m_current_adjustment = m_scroll2_adjustment;
		}
		else
		{
			m_currentList = m_List1;
			m_currentScroll = m_scroll1;
			m_current_adjustment = m_scroll1_adjustment;
		}

		m_displayed_articles = 0;
		var articleChildList = m_currentList.get_children();
		foreach(Gtk.Widget row in articleChildList)
		{
			m_currentList.remove(row);
			row.destroy();
		}

		createHeadlineList();
	}

	public void updateArticleList()
	{
		logger.print(LogMessage.DEBUG, "ArticleList: update HeadlineList");

		var articleChildList = m_currentList.get_children();
		if(articleChildList != null)
		{
			var first_row = articleChildList.first().data as articleRow;
			int new_articles = dataBase.getRowNumberHeadline(first_row.getDateStr()) -1;
			m_limit = m_displayed_articles + new_articles;
		}

		var articles = dataBase.read_articles(m_current_feed_selected, m_IDtype, m_only_unread, m_only_marked, m_searchTerm, m_limit);

		bool found;

		foreach(var item in articles)
		{
			found = false;

			foreach(Gtk.Widget row in articleChildList)
			{
				var tmpRow = row as articleRow;
				if(tmpRow != null && item.getArticleID() == tmpRow.getID())
				{
					tmpRow.updateUnread(item.m_unread);
					found = true;
					break;
				}
			}

			if(!found)
			{
				articleRow newRow = new articleRow(
					                            item.m_title,
					                            item.m_unread,
					                            item.m_feedID.to_string(),
					                            item.m_url,
					                            item.m_feedID,
					                            item.getArticleID(),
					                            item.m_marked,
					                            item.getSortID(),
					                            item.getPreview(),
												item.getDate()
					                            );
				int pos = 0;
				bool added = false;
				if(articleChildList == null)
				{
					m_currentList.insert(newRow, 0);
					added = true;
				}
				foreach(Gtk.Widget row in articleChildList)
				{
					pos++;
					var tmpRow = row as articleRow;
					if(tmpRow != null)
					{
						bool sortByDate = settings_general.get_boolean("articlelist-sort-by-date");
						bool newestFirst = settings_general.get_boolean("articlelist-newest-first");

						if((newestFirst && !sortByDate && newRow.m_sortID > tmpRow.m_sortID)
						|| (!newestFirst && !sortByDate && newRow.m_sortID < tmpRow.m_sortID)
						|| (newestFirst && sortByDate && newRow.getDate().compare(tmpRow.getDate()) == 1)
						|| (!newestFirst && sortByDate && newRow.getDate().compare(tmpRow.getDate()) == -1))
						{
							m_currentList.insert(newRow, pos-1);
							m_displayed_articles++;
							added = true;
							break;
						}
					}
				}

				if(!added)
				{
					m_currentList.add(newRow);
					m_displayed_articles++;
				}
				newRow.reveal(true);
				articleChildList = m_currentList.get_children();
			}
		}
	}


	private void limitScroll()
	{
		ThreadFunc<void*> run = () => {

			if(m_limitScroll == true)
				return null;

			m_limitScroll = true;
			GLib.Thread.usleep(500000);
			m_limitScroll = false;
			return null;
		};
		new GLib.Thread<void*>("limitScroll", run);
	}


	public void markAllAsRead()
	{
		var articleChildList = m_currentList.get_children();

		foreach(Gtk.Widget row in articleChildList)
		{
			var tmpRow = row as articleRow;
			if(tmpRow != null)
			{
				tmpRow.updateUnread(ArticleStatus.READ);
				tmpRow.unreadIconLeave();
			}
		}
	}


}
