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
	private bool m_only_unread;
	private bool m_only_marked;
	private string m_current_feed_selected = FeedID.ALL;
	private double m_lmit = 0.8;
	private string m_searchTerm = "";
	private uint m_limit = 15;
	private FeedListType m_IDtype = FeedListType.FEED;
	private bool m_limitScroll = false;
	private int m_threadCount = 0;
	private uint m_scroll_source_id = 0;
	private uint m_select_source_id = 0;
	private uint m_update_source_id = 0;
	private double m_scrollPos = 0.0;
	private bool m_syncing = false;
	private bool m_busy = false;
	private string m_selected_article = "";
	private InAppNotification m_overlay;
	private uint m_helperCounter = 0;
	private uint m_helperCounter2 = 0;
	public signal void row_activated(articleRow? row);
	public signal void noRowActive();


	public articleList () {
		m_emptyListString = _("None of the %i Articles in the database fit the current filters.");
		m_emptyList = new Gtk.Label(m_emptyListString.printf(dataBase.getArticelCount()));
		m_emptyList.get_style_context().add_class("h2");
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
		syncingLabel.get_style_context().add_class("h2");
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
		m_scroll1.set_size_request(250, 0);
		m_scroll1.add(m_List1);
		m_scroll2 = new Gtk.ScrolledWindow(null, null);
		m_scroll2.set_size_request(250, 0);
		m_scroll2.add(m_List2);


		m_scroll1_adjustment = m_scroll1.get_vadjustment();
		m_scroll1_adjustment.value_changed.connect(scrollValueChanged);

		m_scroll2_adjustment = m_scroll2.get_vadjustment();
		m_scroll2_adjustment.value_changed.connect(scrollValueChanged);


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
								if(tmpRow.getID() != selectedID)
								{
									removeRow(tmpRow);
									break;
								}
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
		this.get_style_context().add_class("article-list");
	}

	private void showNotification()
	{
		if(m_overlay != null)
			return;

		m_overlay = new InAppNotification.withIcon(_("New Articles"), "feed-arrow-up-symbolic", _("scroll up"));
		m_overlay.action.connect(() => {
			scrollUP();
		});
		m_overlay.dismissed.connect(() => {
			m_overlay = null;
		});
		this.add_overlay(m_overlay);
		this.show_all();
	}

	private void scrollValueChanged()
	{
		if(!m_limitScroll && m_helperCounter == 0)
		{
			var oldValue = m_scrollPos;
			m_scrollPos = m_current_adjustment.get_value();
			dismissOverlay(m_current_adjustment);
			if(m_scrollPos > oldValue)
				needToLoadMore(m_current_adjustment);
		}
	}

	private void needToLoadMore(Gtk.Adjustment adj)
	{
		if((adj.get_value() + adj.get_page_size())/adj.get_upper() > m_lmit)
		{
			logger.print(LogMessage.INFO, "load more because of scrolling");
			create(Gtk.StackTransitionType.CROSSFADE, true);
		}
	}

	public void dismissOverlay(Gtk.Adjustment adj)
	{
		if(adj.get_value() == 0.0 && m_overlay != null)
		{
			m_overlay.dismiss();
		}
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
		needToLoadMore(m_current_adjustment);
		dismissOverlay(m_current_adjustment);
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
			}
			else
			{
				m_scrollPos -= offset;
			}

			smooth_adjustment_to(m_current_adjustment, (int)m_scrollPos, time);

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
			m_select_source_id = 0;
            return false;
        });
	}

	public bool toggleReadSelected()
	{
		articleRow selected_row = m_currentList.get_selected_row() as articleRow;

		if(selected_row == null)
			return false;

		return selected_row.toggleUnread();
	}

	public bool toggleMarkedSelected()
	{
		articleRow selected_row = m_currentList.get_selected_row() as articleRow;

		if(selected_row == null)
			return false;

		return selected_row.toggleMarked();
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


	public void getArticleListState(out double scrollPos, out int offset)
	{
		logger.print(LogMessage.DEBUG, "ArticleList: get State");
		scrollPos = m_current_adjustment.get_value();
		logger.print(LogMessage.DEBUG, "scrollpos %f".printf(scrollPos));
		offset = 0;
		var FeedChildList = m_currentList.get_children();
		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpRow = row as articleRow;
			if(tmpRow != null)
			{
				if((scrollPos-tmpRow.get_allocated_height()) >= 0)
				{
					scrollPos -= tmpRow.get_allocated_height();
					++offset;
				}
				else
				{
					break;
				}
			}
		}
		logger.print(LogMessage.DEBUG, "scrollpos %f".printf(scrollPos));
		logger.print(LogMessage.DEBUG, "offset %i".printf(offset));
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
		setScrollPos(m_current_adjustment.get_value() + settings_state.get_double("articlelist-scrollpos"));
		settings_state.set_double("articlelist-scrollpos",  0);
	}


	private void setScrollPos(double pos)
	{
		m_current_adjustment = m_currentScroll.get_vadjustment();
		m_current_adjustment.set_value(pos);
		m_currentScroll.set_vadjustment(m_current_adjustment);
		settings_state.set_int("articlelist-new-rows", 0);
		m_scrollPos = pos;
	}


	private void scrollUP()
	{
		smooth_adjustment_to(m_current_adjustment, 0);
		m_scrollPos = 0.0;
	}


	private void scrollDOWN()
	{
		smooth_adjustment_to(m_current_adjustment, (int)m_current_adjustment.get_upper());
		m_scrollPos = m_current_adjustment.get_upper();
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


	private async void create(Gtk.StackTransitionType transition = Gtk.StackTransitionType.CROSSFADE, bool loadMore = false)
	{
		logger.print(LogMessage.DEBUG, "ArticleList: create");
		m_scrollPos = m_current_adjustment.get_value();
		Gee.ArrayList<article> articles = new Gee.ArrayList<article>();

		bool show_notification = false;
		if(!m_only_unread && !m_only_marked && settings_state.get_int("articlelist-new-rows") > 0)
			show_notification = true;

		m_threadCount++;
		int threadID = m_threadCount;
		bool hasContent = true;
		uint displayed_artilces = getDisplayedArticles();
		uint offset = (uint)settings_state.get_int("articlelist-row-offset");
		if(!m_only_unread && !m_only_marked)
		 	offset += (uint)settings_state.get_int("articlelist-new-rows");
		logger.print(LogMessage.DEBUG, "ArticleList: offset %u".printf(offset));

		// dont allow new articles being created due to scrolling for 0.5s
		limitScroll();

		SourceFunc callback = create.callback;
		//-----------------------------------------------------------------------------------------------------------------------------------------------------
		ThreadFunc<void*> run = () => {

			// wait a little so the currently selected article is updated in the db
			GLib.Thread.usleep(50000);
			m_limit = 20;
			logger.print(LogMessage.DEBUG, "limit: " + m_limit.to_string());

			logger.print(LogMessage.DEBUG, "load articles from db");
			articles = dataBase.read_articles(m_current_feed_selected, m_IDtype, m_only_unread, m_only_marked, m_searchTerm, m_limit, displayed_artilces + offset);
			logger.print(LogMessage.DEBUG, "actual articles loaded: " + articles.size.to_string());

			if(articles.size == 0)
			{
				hasContent = false;
			}

			Idle.add((owned) callback);
			return null;
		};
		//-----------------------------------------------------------------------------------------------------------------------------------------------------

		new GLib.Thread<void*>("create", run);
		yield;

		logger.print(LogMessage.DEBUG, "ArticleList: insert new rows");

		if(!(threadID < m_threadCount))
		{
			if(hasContent)
			{
				if(m_currentList == m_List1)		 m_stack.set_visible_child_full("list1", transition);
				else if(m_currentList == m_List2)   m_stack.set_visible_child_full("list2", transition);

				foreach(var item in articles)
				{
					if(!articleAlreadInList(item.getArticleID()))
					{
						while(Gtk.events_pending())
						{
							Gtk.main_iteration();
						}

						if(threadID < m_threadCount)
							break;

						var tmpRow = new articleRow(item);
						tmpRow.ArticleStateChanged.connect(rowStateChanged);
						tmpRow.drag_begin.connect(( context) => {drag_begin(context);});
						tmpRow.drag_end.connect((context) => {drag_end(context);});
						tmpRow.drag_failed.connect((context, result) => {drag_failed(context, result); return true;});
						tmpRow.highlight_row.connect(highlightRow);
						tmpRow.revert_highlight.connect(unHighlightRow);

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
							if(loadMore)
								tmpRow.reveal(true);
							else
								tmpRow.reveal(true, 150);
						}
						else
						{
							tmpRow.reveal(true, 0);
						}
					}
				}

				if(!loadMore)
				{
					m_current_adjustment.notify["upper"].connect(restoreScrollPos);
					if(!restoreSelectedRow())
						noRowActive();
				}

				if(settings_state.get_boolean("no-animations"))
					settings_state.set_boolean("no-animations", false);

				if(offset > 0)
				{
					settings_state.set_int("articlelist-row-offset", 0);
					updateArticleList(false);
				}

				if(show_notification)
					showNotification();
			}
			else if(!loadMore)
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
		logger.print(LogMessage.DEBUG, "ArticleList: create finished");
	}

	public void newList(Gtk.StackTransitionType transition = Gtk.StackTransitionType.CROSSFADE)
	{
		logger.print(LogMessage.DEBUG, "ArticleList: newList");
		if(m_busy)
		{
			logger.print(LogMessage.WARNING, "ArticleList: newList - already busy");

			if (m_update_source_id > 0)
			{
				GLib.Source.remove(m_update_source_id);
				m_update_source_id = 0;
			}

			logger.print(LogMessage.WARNING, "ArticleList: newList - queue up update");
			m_update_source_id = GLib.Timeout.add_seconds_full(GLib.Priority.DEFAULT, 1, () => {
				logger.print(LogMessage.WARNING, "ArticleList: newList - check if ready");
				if(!m_busy)
				{
					m_update_source_id = 0;
					newList(transition);
					return false;
				}
				return true;
			});
			return;
		}

		m_busy = true;
		if(m_overlay != null)
			m_overlay.dismiss();

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

		create(transition);
		m_busy = false;
	}

	public async void updateArticleList(bool slideIN = true)
	{
		logger.print(LogMessage.DEBUG, "ArticleList: updateArticleList");
		if(m_busy)
		{
			logger.print(LogMessage.WARNING, "ArticleList: updateArticleList - already busy");
			if(m_update_source_id == 0)
			{
				logger.print(LogMessage.WARNING, "ArticleList: updateArticleList - queue up update");
				m_update_source_id = GLib.Timeout.add_seconds_full(GLib.Priority.DEFAULT, 1, () => {
					logger.print(LogMessage.WARNING, "ArticleList: updateArticleList - check if ready");
					if(!m_busy)
					{
						m_update_source_id = 0;
						updateArticleList(slideIN);
				   		return false;
					}
					return true;
				});
			}
			return;
		}
		m_busy = true;

		m_scrollPos = m_current_adjustment.get_value();
		uint articlesInserted = 0;
		Gee.ArrayList<article> articles = new Gee.ArrayList<article>();
		bool sortByDate = settings_general.get_enum("articlelist-sort-by") == ArticleListSort.DATE;

		if(m_stack.get_visible_child_name() == "empty" || m_stack.get_visible_child_name() == "syncing")
		{
			logger.print(LogMessage.WARNING, "ArticleList: updateArticleList - list was empty, so no reason to update - will launch newList()");
			m_busy = false;
			newList();
			return;
		}

		var articleChildList = m_currentList.get_children();
		if(articleChildList != null)
		{
			var first_row = articleChildList.first().data as articleRow;

			uint new_articles = 0;

			if(sortByDate)
			{
				new_articles = UiUtils.getRelevantArticles(dataBase.getRowCountHeadlineByDate(first_row.getDateStr()));
			}
			else
			{
				new_articles = UiUtils.getRelevantArticles(dataBase.getRowCountHeadlineByRowID(first_row.getID()));
			}
			logger.print(LogMessage.DEBUG, "updateArticleList: new articles: %u".printf(new_articles));
			m_limit = m_currentList.get_children().length() + new_articles;

			// counter of all new rows that will be added
			// increase helpCounter2 on every size_allocate of a new row and check if all rows have been allocated
			// only after all articles are allocated new rows can be added by scrolling down the list
			m_helperCounter = new_articles;
		}

		uint actual_loaded = 0;

		SourceFunc callback = updateArticleList.callback;
		//-----------------------------------------------------------------------------------------------------------------------------------------------------
		ThreadFunc<void*> run = () => {
			articles = dataBase.read_articles(m_current_feed_selected, m_IDtype, m_only_unread, m_only_marked, m_searchTerm, m_limit);
			actual_loaded =  articles.size;
			logger.print(LogMessage.DEBUG, "actual articles loaded: " + actual_loaded.to_string());
			Idle.add((owned) callback);
			return null;
		};
		//-----------------------------------------------------------------------------------------------------------------------------------------------------

		new GLib.Thread<void*>("updateArticleList", run);
		yield;

		if(actual_loaded == 0)
		{
			logger.print(LogMessage.DEBUG, "updateArticleList: nothing to do -> return");
			m_busy = false;
			return;
		}

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

			while(Gtk.events_pending())
			{
				Gtk.main_iteration();
			}

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
				articlesInserted++;
				articleRow newRow = new articleRow(item);
				int pos = 0;
				bool added = false;
				newRow.setUpdated(true);
				newRow.ArticleStateChanged.connect(rowStateChanged);
				newRow.drag_begin.connect((context) => {drag_begin(context);});
				newRow.drag_end.connect((context) => {drag_end(context);});
				newRow.drag_failed.connect((context, result) => {drag_failed(context, result); return true;});
				newRow.highlight_row.connect(highlightRow);
				newRow.revert_highlight.connect(unHighlightRow);
				if(getSelectedArticle() != "" || !slideIN)
					newRow.size_allocate.connect(onAllocated);

				if(articleChildList == null)
				{
					m_currentList.insert(newRow, 0);
					added = true;
				}
				foreach(Gtk.Widget row in articleChildList)
				{
					while(Gtk.events_pending())
					{
						Gtk.main_iteration();
					}

					pos++;
					var tmpRow = row as articleRow;
					if(tmpRow != null)
					{
						if((!sortByDate && newRow.getSortID() > tmpRow.getSortID())
						|| (sortByDate && newRow.getDate().compare(tmpRow.getDate()) == 1))
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
				if(getSelectedArticle() == "" && slideIN)
				{
					newRow.reveal(true);
				}
				// dont animate the insert and scroll to compensate the additional pixels
				else
				{
					newRow.reveal(true, 0);
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
				removeRow(tmpRow);
			}
		}

		if(articlesInserted == 0 || getSelectedArticle() == "" || slideIN)
			m_busy = false;

		logger.print(LogMessage.DEBUG, "ArticleList: %u articles have been added".printf(articlesInserted));
		logger.print(LogMessage.DEBUG, "ArticleList: updateArticleList finished");
	}

	private void onAllocated(Gtk.Widget row, Gtk.Allocation allocation)
	{
		m_limitScroll = true;
		setScrollPos(m_current_adjustment.get_value() + allocation.height);
		row.size_allocate.disconnect(onAllocated);

		// increase helpCounter2 for every row that is allocated and check if all of them
		// (should be helpCounter) have been allocated
		m_helperCounter2++;
		if(m_helperCounter == m_helperCounter2)
		{
			m_helperCounter = 0;
			m_helperCounter2 = 0;
			m_busy = false;
		}
		m_limitScroll = false;
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
					if(tmpRow != null)
					{
						if((selected_row != null && tmpRow.getID() != selected_row.getID())
						|| selected_row == null)
						{
							if((m_only_unread && !tmpRow.isUnread())
							||(m_only_marked && !tmpRow.isMarked()))
							{
								removeRow(tmpRow);
								break;
							}
						}
					}
				}
				break;
		}
	}

	private void removeRow(articleRow row)
	{
		int time = 700;
		row.reveal(false, time);
		GLib.Timeout.add(time + 50, () => {
			if(!m_busy)
			{
				m_currentList.remove(row);
				return false;
			}

			logger.print(LogMessage.DEBUG, "ArticleList: removeRow(): articleList busy");
			return true;
		});
		m_current_adjustment = m_currentScroll.get_vadjustment();
		if(m_current_adjustment.get_upper() < this.parent.get_allocated_height() + 306)
		{
			logger.print(LogMessage.DEBUG, "load more");
			create(Gtk.StackTransitionType.CROSSFADE, true);
		}
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
		string message = "";
		if(m_current_feed_selected != FeedID.ALL && m_current_feed_selected != FeedID.CATEGORIES)
		{
			switch(m_IDtype)
			{
				case FeedListType.FEED:
					name = dataBase.getFeedName(m_current_feed_selected);
					if(m_only_unread && !m_only_marked)
					{
						if(m_searchTerm != "")
							message = _("No unread articles that fit \"%s\" in the feed \"%s\" could be found").printf(Utils.parseSearchTerm(m_searchTerm), name);
						else
							message = _("No unread articles in the feed \"%s\" could be found").printf(name);
					}
					else if(m_only_unread && m_only_marked)
					{
						if(m_searchTerm != "")
							message = _("No unread and marked articles that fit \"%s\" in the feed \"%s\" could be found").printf(Utils.parseSearchTerm(m_searchTerm), name);
						else
							message = _("No unread and marked articles in the feed \"%s\" could be found").printf(name);
					}
					else if(!m_only_unread && m_only_marked)
					{
						if(m_searchTerm != "")
							message = _("No marked articles that fit \"%s\" in the feed \"%s\" could be found").printf(Utils.parseSearchTerm(m_searchTerm), name);
						else
							message = _("No marked articles in the feed \"%s\" could be found").printf(name);
					}
					else if(!m_only_unread && !m_only_marked)
					{
						if(m_searchTerm != "")
							message = _("No articles that fit \"%s\" in the feed \"%s\" could be found").printf(Utils.parseSearchTerm(m_searchTerm), name);
						else
							message = _("No articles in the feed \"%s\" could be found").printf(name);
					}
					break;
				case FeedListType.TAG:
					name = dataBase.getTagName(m_current_feed_selected);
					if(m_only_unread && !m_only_marked)
					{
						if(m_searchTerm != "")
							message = _("No unread articles that fit \"%s\" in the tag \"%s\" could be found").printf(Utils.parseSearchTerm(m_searchTerm), name);
						else
							message = _("No unread articles in the tag \"%s\" could be found").printf(name);
					}
					else if(m_only_unread && m_only_marked)
					{
						if(m_searchTerm != "")
							message = _("No unread and marked articles that fit \"%s\" in the tag \"%s\" could be found").printf(Utils.parseSearchTerm(m_searchTerm), name);
						else
							message = _("No unread and marked articles in the tag \"%s\" could be found").printf(name);
					}
					else if(!m_only_unread && m_only_marked)
					{
						if(m_searchTerm != "")
							message = _("No marked articles that fit \"%s\" in the tag \"%s\" could be found").printf(Utils.parseSearchTerm(m_searchTerm), name);
						else
							message = _("No marked articles in the tag \"%s\" could be found").printf(name);
					}
					else if(!m_only_unread && !m_only_marked)
					{
						if(m_searchTerm != "")
							message = _("No articles that fit \"%s\" in the tag \"%s\" could be found").printf(Utils.parseSearchTerm(m_searchTerm), name);
						else
							message = _("No articles in the tag \"%s\" could be found").printf(name);
					}
					break;
				case FeedListType.CATEGORY:
					name = dataBase.getCategoryName(m_current_feed_selected);
					if(m_only_unread && !m_only_marked)
					{
						if(m_searchTerm != "")
							message = _("No unread articles that fit \"%s\" in the category \"%s\" could be found").printf(Utils.parseSearchTerm(m_searchTerm), name);
						else
							message = _("No unread articles in the category \"%s\" could be found").printf(name);
					}
					else if(m_only_unread && m_only_marked)
					{
						if(m_searchTerm != "")
							message = _("No unread and marked articles that fit \"%s\" in the category \"%s\" could be found").printf(Utils.parseSearchTerm(m_searchTerm), name);
						else
							message = _("No unread and marked articles in the category \"%s\" could be found").printf(name);
					}
					else if(!m_only_unread && m_only_marked)
					{
						if(m_searchTerm != "")
							message = _("No marked articles that fit \"%s\" in the category \"%s\" could be found").printf(Utils.parseSearchTerm(m_searchTerm), name);
						else
							message = _("No marked articles in the category \"%s\" could be found").printf(name);
					}
					else if(!m_only_unread && !m_only_marked)
					{
						if(m_searchTerm != "")
							message = _("No articles that fit \"%s\" in the category \"%s\" could be found").printf(Utils.parseSearchTerm(m_searchTerm), name);
						else
							message = _("No articles in the category \"%s\" could be found").printf(name);
					}
					break;
			}
		}
		else
		{
			if(m_only_unread && !m_only_marked)
			{
				if(m_searchTerm != "")
					message = _("No unread articles that fit \"%s\" could be found").printf(Utils.parseSearchTerm(m_searchTerm));
				else
					message = _("No unread articles could be found");
			}
			else if(m_only_unread && m_only_marked)
			{
				if(m_searchTerm != "")
					message = _("No unread and marked articles that fit \"%s\" could be found").printf(Utils.parseSearchTerm(m_searchTerm));
				else
					message = _("No unread and marked articles could be found");
			}
			else if(!m_only_unread && m_only_marked)
			{
				if(m_searchTerm != "")
					message = _("No marked articles that fit \"%s\" could be found").printf(Utils.parseSearchTerm(m_searchTerm));
				else
					message = _("No marked articles could be found");
			}
			else if(!m_only_unread && !m_only_marked)
			{
				if(m_searchTerm != "")
					message = _("No articles that fit \"%s\" could be found").printf(Utils.parseSearchTerm(m_searchTerm));
				else
					message = _("No articles could be found");
			}

		}
		return message;
	}

	// thx to pantheon files developers =)
	private void smooth_adjustment_to(Gtk.Adjustment adj, int final, int duration = 1000)
	{
		logger.print(LogMessage.DEBUG, "smooth adjust to: " + final.to_string());
		m_limitScroll = true;

        if (m_scroll_source_id > 0)
		{
            GLib.Source.remove(m_scroll_source_id);
            m_scroll_source_id = 0;
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

        m_scroll_source_id = Timeout.add(duration / steps, () => {
            /* If the user move it at the same time, just stop the animation */
            if (old_adj_value != adj.value) {
                m_scroll_source_id = 0;
				m_scrollPos = adj.value;
				m_limitScroll = false;
                return false;
            }

            if (newvalue >= to_do - stepSize) {
                /* to be sure that there is not a little problem */
                adj.value = final;
                m_scroll_source_id = 0;
				m_limitScroll = false;
				if(adj.value == 0.0 && m_overlay != null)
					m_overlay.dismiss();
                return false;
            }

            newvalue += stepSize;
			m_limitScroll = true;
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

	public Gdk.RGBA getBackgroundColor()
	{
		// code according to: https://blogs.gnome.org/mclasen/2015/11/20/a-gtk-update/
		var context = m_currentList.get_style_context();
		context.save();
		context.set_state(Gtk.StateFlags.NORMAL);
		var color = context.get_background_color(context.get_state());
		context.restore();
		return color;
	}

	public void showOverlay()
	{
		if(m_current_adjustment.get_value() > 0.0)
			showNotification();
	}

	private void limitScroll()
	{
		m_limitScroll = true;

		GLib.Timeout.add(500, () => {
			m_limitScroll = false;
			return false;
		});
	}

	private bool articleAlreadInList(string id)
	{
		var articleChildList = m_currentList.get_children();
		foreach(Gtk.Widget row in articleChildList)
		{
			var tmpRow = row as articleRow;
			if(tmpRow != null && tmpRow.getID() == id)
				return true;
		}

		return false;
	}

	private void highlightRow(string articleID)
	{
		var articleChildList = m_currentList.get_children();
		foreach(Gtk.Widget row in articleChildList)
		{
			var tmpRow = row as articleRow;
			if(tmpRow != null && tmpRow.getID() != articleID)
				tmpRow.opacity = 0.5;
		}
	}

	private void unHighlightRow()
	{
		var articleChildList = m_currentList.get_children();
		foreach(Gtk.Widget row in articleChildList)
		{
			var tmpRow = row as articleRow;
			if(tmpRow != null)
				tmpRow.opacity = 1.0;
		}
	}

	public bool selectedIsFirst()
	{
		var selected_row = m_currentList.get_selected_row() as articleRow;
		var ArticleListChildren = m_currentList.get_children();
		int n = ArticleListChildren.index(selected_row);
		var lastRow = ArticleListChildren.first().data as articleRow;

		if(n == 0)
			return true;
		else if(m_only_unread && n == 1 && !lastRow.isBeingRevealed())
			return true;

		return false;
	}

	public bool selectedIsLast()
	{
		var selected_row = m_currentList.get_selected_row() as articleRow;
		var ArticleListChildren = m_currentList.get_children();
		int n = ArticleListChildren.index(selected_row);
		uint length = ArticleListChildren.length();
		var lastRow = ArticleListChildren.last().data as articleRow;

		if(n + 1 == length)
			return true;
		else if(m_only_unread && n + 2 == length && !lastRow.isBeingRevealed())
			return true;

		return false;
	}

}
