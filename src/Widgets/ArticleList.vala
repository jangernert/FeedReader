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

public class FeedReader.articleList : Gtk.Overlay {

	private Gtk.Stack m_stack;
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
	private Gtk.Box m_syncingBox;
	private Gtk.Spinner m_syncSpinner;
	private double m_lmit;
	private string m_current_feed_selected;
	private bool m_only_unread;
	private bool m_only_marked;
	private string m_searchTerm;
	private uint m_limit;
	private FeedListType m_IDtype;
	private bool m_limitScroll;
	private int m_threadCount;
	private uint m_timeout_source_id = 0;
	private uint m_select_source_id = 0;
	private double m_scrollPos = 0;
	private bool m_scrollOngoing = false;
	private bool m_syncing = false;
	private string m_selected_article;
	private ArticleListOverlay m_overlay;
	public signal void row_activated(articleRow? row);
	public signal void noRowActive();


	public articleList () {
		m_lmit = 0.8;
		m_current_feed_selected = FeedID.ALL;
		m_IDtype = FeedListType.FEED;
		m_searchTerm = "";
		m_limit = 15;
		m_limitScroll = false;
		m_threadCount = 0;
		m_selected_article = "";

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

		m_syncingBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
		m_syncingBox.set_margin_left(30);
		m_syncingBox.set_margin_right(30);
		var syncingLabel = new Gtk.Label(_("Sync is in progress. Articles should appear any second."));
		syncingLabel.get_style_context().add_class("emptyView");
		syncingLabel.set_ellipsize (Pango.EllipsizeMode.END);
		syncingLabel.set_line_wrap_mode(Pango.WrapMode.WORD);
		syncingLabel.set_line_wrap(true);
		syncingLabel.set_lines(2);
		m_syncSpinner = new Gtk.Spinner();
		m_syncSpinner.set_size_request(32, 32);
		m_syncingBox.pack_start(m_syncSpinner);
		m_syncingBox.pack_start(syncingLabel);

		m_List1 = new Gtk.ListBox();
		m_List1.set_selection_mode(Gtk.SelectionMode.BROWSE);
		m_List2 = new Gtk.ListBox();
		m_List2.set_selection_mode(Gtk.SelectionMode.BROWSE);



		m_scroll1 = new Gtk.ScrolledWindow(null, null);
		m_scroll1.set_size_request(400, 500);
		m_scroll1.add(m_List1);
		m_scroll2 = new Gtk.ScrolledWindow(null, null);
		m_scroll2.set_size_request(400, 500);
		m_scroll2.add(m_List2);


		m_scroll1_adjustment = m_scroll1.get_vadjustment();
		m_scroll1_adjustment.value_changed.connect(() => {
			if(!m_limitScroll)
			{
				if(!m_scrollOngoing)
					m_scrollPos = m_scroll1_adjustment.get_value();

				if((m_scroll1_adjustment.get_value() + m_scroll1_adjustment.get_page_size())/m_scroll1_adjustment.get_upper() > m_lmit)
					createHeadlineList(Gtk.StackTransitionType.CROSSFADE, true);
				else if(m_scroll1_adjustment.get_value() == 0 && !m_overlay.hovered())
					m_overlay.hide();
			}
		});

		m_scroll2_adjustment = m_scroll2.get_vadjustment();
		m_scroll2_adjustment.value_changed.connect(() => {
			if(!m_limitScroll)
			{
				if(!m_scrollOngoing)
					m_scrollPos = m_scroll2_adjustment.get_value();

				if((m_scroll2_adjustment.get_value() + m_scroll2_adjustment.get_page_size())/m_scroll2_adjustment.get_upper() > m_lmit)
					createHeadlineList(Gtk.StackTransitionType.CROSSFADE, true);
				else if(m_scroll1_adjustment.get_value() == 0 && !m_overlay.hovered())
					m_overlay.hide();
			}
		});


		m_List1.row_activated.connect((row) => {
			row_activated((articleRow)row);
		});
		m_List2.row_activated.connect((row) => {
			row_activated((articleRow)row);
		});

		this.row_activated.connect((selected_row) => {

			string selectedID = ((articleRow)selected_row).getID();

			if(m_selected_article != selectedID)
			{
				if(m_only_unread || m_only_marked || m_IDtype == FeedListType.TAG)
				{
					var articleChildList = m_currentList.get_children();
					foreach(Gtk.Widget row in articleChildList)
					{
						var tmpRow = row as articleRow;
						if(tmpRow != null && tmpRow.isBeingRevealed())
						{
							if((!tmpRow.isUnread() && m_only_unread)
							|| (!tmpRow.isMarked() && m_only_marked)
							|| (m_IDtype == FeedListType.TAG && !tmpRow.hasTag(m_current_feed_selected)))
							{
								removeRow(tmpRow);
								break;
							}
						}
					}
				}
			}

			m_selected_article = selectedID;
		});

		m_List1.key_press_event.connect(key_pressed);
		m_List2.key_press_event.connect(key_pressed);

		m_currentList = m_List1;
		m_currentScroll = m_scroll1;
		m_current_adjustment = m_scroll1_adjustment;

		m_stack = new Gtk.Stack();
		m_stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		m_stack.set_transition_duration(100);
		m_stack.add_named(m_scroll1, "list1");
		m_stack.add_named(m_scroll2, "list2");
		m_stack.add_named(m_emptyList, "empty");
		m_stack.add_named(m_syncingBox, "syncing");
		this.add(m_stack);

		m_overlay = new ArticleListOverlay("New Articles", "scroll up", "feed-arrow-up");
		m_overlay.action.connect(() => {
			scrollUP();
		});
		this.add_overlay(m_overlay);
	}

	private bool key_pressed(Gdk.EventKey event)
	{
		switch(event.keyval)
		{
			case Gdk.Key.Down:
				move(true);
				break;

			case Gdk.Key.Up:
				move(false);
				break;

			case Gdk.Key.Page_Down:
				scrollDOWN();
				break;

			case Gdk.Key.Page_Up:
				scrollUP();
				break;
		}
		return true;
	}


	public void move(bool down)
	{
		articleRow selected_row = m_currentList.get_selected_row() as articleRow;
		articleRow new_article = null;
		int time = 300;

		var ArticleListChildren = m_currentList.get_children();
		if(!down){
			ArticleListChildren.reverse();
		}

		int current = ArticleListChildren.index(selected_row);

		do {
			current++;
			if(current >= ArticleListChildren.length())
				return;

			new_article = ArticleListChildren.nth_data(current) as articleRow;
		} while(!new_article.isBeingRevealed());


		if((!m_only_unread || selected_row.isUnread())
		&&(!m_only_marked || selected_row.isMarked()))
		{
			var currentPos = m_current_adjustment.get_value();
			var max = m_current_adjustment.get_upper();
			var offset = selected_row.get_allocated_height();

			if(down)
			{
				m_scrollPos += offset;
				smooth_adjustment_to(m_current_adjustment, (int)m_scrollPos, time);
			}
			else
			{
				m_scrollPos -= offset;
				smooth_adjustment_to(m_current_adjustment, (int)m_scrollPos, time);
			}

			if(m_scrollPos < 0.0)
			{
				m_scrollPos = 0.0;
			}

			m_currentScroll.set_vadjustment(m_current_adjustment);
		}

		selectAfter(new_article, time);
	}

	private void selectAfter(articleRow row, int time)
	{
		m_currentList.select_row(row);
		row.updateUnread(ArticleStatus.READ);
		feedDaemon_interface.changeArticle(row.getID(), ArticleStatus.READ);

		if (m_select_source_id > 0)
		{
            GLib.Source.remove(m_select_source_id);
            m_select_source_id = 0;
        }

        m_select_source_id = Timeout.add(time, () => {
            row.activate();
            row_activated(row);
            return false;
        });
	}

	public void toggleReadSelected()
	{
		articleRow selected_row = m_currentList.get_selected_row() as articleRow;

		if(selected_row == null)
			return;

		selected_row.toggleUnread();
		selected_row.show_all();
	}

	public void toggleMarkedSelected()
	{
		articleRow selected_row = m_currentList.get_selected_row() as articleRow;

		if(selected_row == null)
			return;

		selected_row.toggleMarked();
		selected_row.show_all();
	}

	public void openSelected()
	{
		articleRow selected_row = m_currentList.get_selected_row() as articleRow;

		if(selected_row == null)
			return;

		try{
			Gtk.show_uri(Gdk.Screen.get_default(), selected_row.getURL(), Gdk.CURRENT_TIME);
		}
		catch(GLib.Error e){
			logger.print(LogMessage.DEBUG, "could not open the link in an external browser: %s".printf(e.message));
		}
	}


	public int getAmountOfRowsToLoad()
	{
		return (int)m_currentList.get_children().length();
	}

	public void removeTagFromSelectedRow(string tagID)
	{
		articleRow selected_row = m_currentList.get_selected_row() as articleRow;

		if(selected_row == null)
			return;

		selected_row.removeTag(tagID);
	}


	private bool restoreSelectedRow()
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
					var window = this.get_toplevel() as readerUI;
					if(window != null && !window.searchFocused())
						tmpRow.activate();
					settings_state.set_string("articlelist-selected-row", "");
					return true;
				}
			}
		}

		return false;
	}


	public void centerSelectedRow()
	{
		int scroll = -(int)(m_current_adjustment.get_page_size()/2);
		logger.print(LogMessage.DEBUG, "page size: %i".printf(scroll));
		articleRow selected_row = m_currentList.get_selected_row() as articleRow;

		if(selected_row == null)
			return;

		var FeedChildList = m_currentList.get_children();
		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpRow = row as articleRow;
			if(tmpRow != null)
			{
				logger.print(LogMessage.DEBUG, "row: %s".printf(tmpRow.getName()));
				if(tmpRow.getID() == selected_row.getID())
				{
					scroll += tmpRow.get_allocated_height()/2;
					logger.print(LogMessage.DEBUG, "scroll: %i".printf(scroll));
					break;
				}
				else if(tmpRow.isRevealed())
				{
					scroll += tmpRow.get_allocated_height();
					logger.print(LogMessage.DEBUG, "scroll: %i".printf(scroll));
				}
			}
		}

		smooth_adjustment_to(m_current_adjustment, (int)scroll);
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
		int new_rows = settings_state.get_int("articlelist-new-rows");
		int i = 0;
		int additionalScroll = 0;
		var FeedChildList = m_currentList.get_children();

		foreach(Gtk.Widget row in FeedChildList)
		{
			if(i < new_rows)
			{
				additionalScroll += row.get_allocated_height();
				++i;
			}
			else
			{
				break;
			}
		}

		double newPos = pos + additionalScroll;

		m_current_adjustment = m_currentScroll.get_vadjustment();
		m_current_adjustment.set_value(newPos);
		m_currentScroll.set_vadjustment(m_current_adjustment);
		settings_state.set_int("articlelist-new-rows", 0);

		if(new_rows > 0)
			m_overlay.reveal();
	}


	private void scrollUP()
	{
		smooth_adjustment_to(m_current_adjustment, 0);
	}


	private void scrollDOWN()
	{
		smooth_adjustment_to(m_current_adjustment, (int)m_current_adjustment.get_upper());
	}


	public double getScrollPos()
	{
		return m_current_adjustment.get_value();
	}

	private int shortenArticleList()
	{
		double RowVSpace = 102;
		int stillInViewport = (int)((settings_state.get_double("articlelist-scrollpos")+settings_state.get_int("window-height"))/RowVSpace);
		if(stillInViewport < settings_state.get_int("articlelist-row-amount"))
		{
			return stillInViewport+(int)(settings_state.get_int("window-height")/RowVSpace);
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

	public void setSelectedType(FeedListType type)
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

	public ArticleStatus getSelectedArticleMarked()
	{
		articleRow selected_row = m_currentList.get_selected_row() as articleRow;
		if(selected_row != null)
			return selected_row.getMarked();

		return ArticleStatus.UNMARKED;
	}

	public ArticleStatus getSelectedArticleRead()
	{
		articleRow selected_row = m_currentList.get_selected_row() as articleRow;
		if(selected_row != null)
			return selected_row.getUnread();

		return ArticleStatus.READ;
	}

	public string getSelectedURL()
	{
		articleRow selected_row = m_currentList.get_selected_row() as articleRow;
		if(selected_row != null)
			return selected_row.getURL();

		if(m_currentList.get_children().length() == 0)
			return "empty";

		return "";
	}


	private async void createHeadlineList(Gtk.StackTransitionType transition = Gtk.StackTransitionType.CROSSFADE, bool addRows = false)
	{
		logger.print(LogMessage.DEBUG, "ArticleList: create HeadlineList");
		GLib.List<article> articles = new GLib.List<article>();

		m_threadCount++;
		int threadID = m_threadCount;
		bool hasContent = true;
		uint displayed_artilces = getDisplayedArticles();

		// dont allow new articles being created due to scrolling for 0.5s
		limitScroll();

		SourceFunc callback = createHeadlineList.callback;
		//-----------------------------------------------------------------------------------------------------------------------------------------------------
		ThreadFunc<void*> run = () => {

			// wait a little so the currently selected article is updated in the db
			GLib.Thread.usleep(50000);
			m_limit = shortenArticleList() + settings_state.get_int("articlelist-new-rows");
			logger.print(LogMessage.DEBUG, "limit: " + m_limit.to_string());

			logger.print(LogMessage.DEBUG, "load articles from db");
			articles = dataBase.read_articles(m_current_feed_selected, m_IDtype, m_only_unread, m_only_marked, m_searchTerm, m_limit, displayed_artilces);
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
				if(m_currentList == m_List1)		 m_stack.set_visible_child_full("list1", transition);
				else if(m_currentList == m_List2)   m_stack.set_visible_child_full("list2", transition);

				foreach(var item in articles)
				{
					while(Gtk.events_pending())
					{
						Gtk.main_iteration();
					}

					if(threadID < m_threadCount)
						break;

					var tmpRow = new articleRow(
							                        item.getTitle(),
							                        item.getUnread(),
							                        item.getFeedID(),
							                        item.getURL(),
							                        item.getFeedID(),
							                        item.getArticleID(),
							                        item.getMarked(),
							                        item.getSortID(),
							                        item.getPreview(),
													item.getDate(),
													item.getTagString()
							                        );
					tmpRow.ArticleStateChanged.connect(rowStateChanged);

					while(Gtk.events_pending())
					{
						Gtk.main_iteration();
					}

					if(threadID < m_threadCount)
						break;

					m_currentList.add(tmpRow);

					if(settings_state.get_boolean("no-animations"))
					{
						tmpRow.reveal(true, 0);
					}
					else if(transition == Gtk.StackTransitionType.CROSSFADE)
					{
						if(addRows)
							tmpRow.reveal(true);
						else
							tmpRow.reveal(true, 150);
					}
					else
					{
						tmpRow.reveal(true, 0);
					}

				}

				if(!addRows)
				{
					m_current_adjustment.notify["upper"].connect(restoreScrollPos);
					if(!restoreSelectedRow())
						noRowActive();
				}

				if(settings_state.get_boolean("no-animations"))
					settings_state.set_boolean("no-animations", false);
			}
			else if(!addRows)
			{
				if(!m_syncing)
				{
					m_emptyList.set_text(buildEmptyString());
					m_stack.set_visible_child_full("empty", transition);
				}
				else
				{
					m_stack.set_visible_child_full("syncing", transition);
					m_syncSpinner.start();
				}

				noRowActive();
			}
		}
	}

	public void newHeadlineList(Gtk.StackTransitionType transition = Gtk.StackTransitionType.CROSSFADE)
	{
		logger.print(LogMessage.DEBUG, "ArticleList: delete HeadlineList");

		if(settings_state.get_int("articlelist-row-amount") < 15)
			settings_state.reset("articlelist-row-amount");

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

		var articleChildList = m_currentList.get_children();
		foreach(Gtk.Widget row in articleChildList)
		{
			m_currentList.remove(row);
			row.destroy();
		}

		createHeadlineList(transition);
	}

	public void updateArticleList()
	{
		logger.print(LogMessage.DEBUG, "ArticleList: insert new articles");
		bool sortByDate = settings_general.get_boolean("articlelist-sort-by-date");
		bool newestFirst = settings_general.get_boolean("articlelist-newest-first");
		bool newArticles = false;

		if(m_stack.get_visible_child_name() == "empty" || m_stack.get_visible_child_name() == "syncing")
		{
			newHeadlineList();
			return;
		}

		var articleChildList = m_currentList.get_children();
		if(articleChildList != null)
		{
			var first_row = articleChildList.first().data as articleRow;

			int new_articles = 0;

			if(sortByDate)
			{
				new_articles = dataBase.getRowCountHeadlineByDate(first_row.getDateStr());
			}
			else
			{
				new_articles = dataBase.getRowCountHeadlineByRowID(first_row.getDateStr());
			}

			m_limit = m_currentList.get_children().length() + new_articles;
		}

		var articles = dataBase.read_articles(m_current_feed_selected, m_IDtype, m_only_unread, m_only_marked, m_searchTerm, m_limit);

		foreach(Gtk.Widget row in articleChildList)
		{
			var tmpRow = row as articleRow;
			if(tmpRow != null)
			{
				tmpRow.setUpdated(false);
			}
		}

		bool found;

		foreach(var item in articles)
		{
			found = false;

			foreach(Gtk.Widget row in articleChildList)
			{
				var tmpRow = row as articleRow;
				if(tmpRow != null && item.getArticleID() == tmpRow.getID())
				{
					tmpRow.updateUnread(item.getUnread());
					tmpRow.updateMarked(item.getMarked());
					tmpRow.setUpdated(true);
					found = true;
					break;
				}
			}

			if(!found)
			{
				articleRow newRow = new articleRow(
					                            item.getTitle(),
					                            item.getUnread(),
					                            item.getFeedID(),
					                            item.getURL(),
					                            item.getFeedID(),
					                            item.getArticleID(),
					                            item.getMarked(),
					                            item.getSortID(),
					                            item.getPreview(),
												item.getDate(),
												item.getTagString()
					                            );
				int pos = 0;
				bool added = false;
				newRow.setUpdated(true);
				newRow.ArticleStateChanged.connect(rowStateChanged);

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
						if((newestFirst && !sortByDate && newRow.m_sortID > tmpRow.m_sortID)
						|| (!newestFirst && !sortByDate && newRow.m_sortID < tmpRow.m_sortID)
						|| (newestFirst && sortByDate && newRow.getDate().compare(tmpRow.getDate()) == 1)
						|| (!newestFirst && sortByDate && newRow.getDate().compare(tmpRow.getDate()) == -1))
						{
							m_currentList.insert(newRow, pos-1);
							added = true;
							break;
						}
					}
				}

				if(!added)
				{
					m_currentList.add(newRow);
				}


				// animate article to slide down from the top
				if(getSelectedArticle() == "")
				{
					newRow.reveal(true);
				}
				// dont animate the insert and scroll to compensate the additional pixels
				else
				{
					newRow.reveal(true, 0);
					newRow.size_allocate.connect(onAllocated);
					newArticles = true;
				}

				articleChildList = m_currentList.get_children();
			}
		}

		// delte all obsolete rows
		articleChildList = m_currentList.get_children();
		articleRow selected_row = m_currentList.get_selected_row() as articleRow;

		foreach(Gtk.Widget row in articleChildList)
		{
			var tmpRow = row as articleRow;
			if(tmpRow != null && !tmpRow.getUpdated()
			&& selected_row.getID() != tmpRow.getID())
			{
				m_currentList.remove(tmpRow);
			}
		}

		if(newArticles)
			m_overlay.reveal();
	}

	private void onAllocated(Gtk.Widget row, Gtk.Allocation allocation)
	{
		setScrollPos(getScrollPos() + allocation.height);
		row.size_allocate.disconnect(onAllocated);
	}


	private void rowStateChanged(ArticleStatus status)
	{
		logger.print(LogMessage.DEBUG, "state changed");
		switch(status)
		{
			case ArticleStatus.UNREAD:
			case ArticleStatus.MARKED:
				return;
			case ArticleStatus.READ:
			case ArticleStatus.UNMARKED:
				articleRow selected_row = m_currentList.get_selected_row() as articleRow;
				var articleChildList = m_currentList.get_children();
				foreach(Gtk.Widget row in articleChildList)
				{
					var tmpRow = row as articleRow;
					if(((tmpRow != null && tmpRow.getID() != selected_row.getID())
					|| (tmpRow != null && selected_row == null)) && tmpRow.isBeingRevealed())
					{
						if((m_only_unread && !tmpRow.isUnread())
						||(m_only_marked && !tmpRow.isMarked()))
						{
							removeRow(tmpRow);
							break;
						}

					}
				}
				break;
		}
	}

	public void removeRow(articleRow row)
	{
		row.reveal(false, 700);
		m_current_adjustment = m_currentScroll.get_vadjustment();
		if(m_current_adjustment.get_upper() < this.parent.get_allocated_height() + 306)
		{
			logger.print(LogMessage.DEBUG, "load more");
			createHeadlineList(Gtk.StackTransitionType.CROSSFADE, true);
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
			}
		}
	}

	private string buildEmptyString()
	{
		string message = "No ";

		if(m_only_unread)
			message += "unread ";

		if(m_only_marked)
		{
			if(m_only_unread)
				message += "and ";
			message += "marked ";
		}

		message += "articles ";

		if(m_searchTerm != "")
		{
			message += "that fit \"%s\" ".printf(Utils.parseSearchTerm(m_searchTerm));
		}

		string name = "";

		if(m_current_feed_selected != FeedID.ALL && m_current_feed_selected != FeedID.CATEGORIES)
		{
			message += "in ";
			switch(m_IDtype)
			{
				case FeedListType.FEED:
					message += "the feed ";
					name = dataBase.getFeedName(m_current_feed_selected);
					break;
				case FeedListType.TAG:
					message += "the tag ";
					name = dataBase.getTagName(m_current_feed_selected);
					break;
				case FeedListType.CATEGORY:
					message += "the category ";
					name = dataBase.getCategoryName(m_current_feed_selected);
					break;
			}
			message += "\"%s\" ".printf(name);
		}
		message += "could be found.";

		return message;
	}


	// thx to pantheon files developers =)
	private void smooth_adjustment_to(Gtk.Adjustment adj, int final, int duration = 1000)
	{
		m_scrollOngoing = true;

        if (m_timeout_source_id > 0)
		{
            GLib.Source.remove(m_timeout_source_id);
            m_timeout_source_id = 0;
        }

        var initial = adj.value;
        var to_do = final - initial;

        int factor;
        (to_do > 0) ? factor = 1 : factor = -1;
        to_do = (double) (((int) to_do).abs () + 1);


		int stepSize = 5;
        int steps = (int)(GLib.Math.ceil(to_do/stepSize));

        var newvalue = 0;
        var old_adj_value = adj.value;

        m_timeout_source_id = Timeout.add(duration / steps, () => {
            /* If the user move it at the same time, just stop the animation */
            if (old_adj_value != adj.value) {
                m_timeout_source_id = 0;
				m_scrollPos = adj.value;
				m_scrollOngoing = false;
                return false;
            }

            if (newvalue >= to_do - stepSize) {
                /* to be sure that there is not a little problem */
                adj.value = final;
                m_timeout_source_id = 0;
				m_scrollOngoing = false;
                return false;
            }

            newvalue += stepSize;

            adj.value = initial + factor * GLib.Math.sin( ( (double)newvalue / (double)to_do) * Math.PI / 2) * to_do;
            old_adj_value = adj.value;
            return true;
        });
    }

	private uint getDisplayedArticles()
	{
		uint count = 0;
		var articleChildList = m_currentList.get_children();

		if(m_only_unread)
		{
			foreach(Gtk.Widget row in articleChildList)
			{
				var tmpRow = row as articleRow;
				if(tmpRow != null && tmpRow.isUnread())
				{
					++count;
				}
			}
		}
		else if(m_only_marked)
		{
			foreach(Gtk.Widget row in articleChildList)
			{
				var tmpRow = row as articleRow;
				if(tmpRow != null && tmpRow.isMarked())
				{
					++count;
				}
			}
		}
		else if(m_IDtype == FeedListType.TAG)
		{
			foreach(Gtk.Widget row in articleChildList)
			{
				var tmpRow = row as articleRow;
				if(tmpRow != null && tmpRow.hasTag(m_current_feed_selected))
				{
					++count;
				}
			}
		}
		else
		{
			count = articleChildList.length();
		}

		return count;
	}

	public void syncStarted()
	{
		m_syncing = true;
		if(m_stack.get_visible_child_name() == "empty")
		{
			m_stack.set_visible_child_full("syncing", Gtk.StackTransitionType.CROSSFADE);
			m_syncSpinner.start();
		}
	}

	public void syncFinished()
	{
		m_syncing = false;
		if(m_stack.get_visible_child_name() == "syncing")
		{
			m_stack.set_visible_child_full("empty", Gtk.StackTransitionType.CROSSFADE);
		}
	}

}
