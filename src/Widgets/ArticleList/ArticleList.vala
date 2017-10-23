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


public class FeedReader.ArticleList : Gtk.Overlay {

	private Gtk.Stack m_stack;
	private ArticleListEmptyLabel m_emptyList;
	private FeedListType m_selectedFeedListType = FeedListType.FEED;
	private string m_selectedFeedListID = FeedID.ALL.to_string();
	private ArticleListState m_state = ArticleListState.ALL;
	private string m_searchTerm = "";
	private bool m_syncing = false;
	private InAppNotification m_overlay;
	private GLib.Thread<void*> m_loadThread;
	private ArticleListScroll m_currentScroll;
	private ArticleListScroll m_scroll1;
	private ArticleListScroll m_scroll2;
	private ArticleListBox m_currentList;
	private ArticleListBox m_List1;
	private ArticleListBox m_List2;
	private Gtk.Spinner m_syncSpinner;
	private uint m_scrollChangedTimeout = 0;
	private const int m_dynamicRowThreshold = 10;
	private int m_height = 0;
	private ulong m_handlerID1 = 0;
	private ulong m_handlerID2 = 0;
	private ulong m_handlerID3 = 0;

	public signal void row_activated(ArticleRow? row);

	public ArticleList()
	{
		m_emptyList = new ArticleListEmptyLabel();
		m_searchTerm = Settings.state().get_string("search-term");
		var syncingLabel = new Gtk.Label(_("Sync is in progress. Articles should appear any second."));
		syncingLabel.get_style_context().add_class("h2");
		syncingLabel.set_ellipsize (Pango.EllipsizeMode.END);
		syncingLabel.set_line_wrap_mode(Pango.WrapMode.WORD);
		syncingLabel.set_line_wrap(true);
		syncingLabel.set_lines(2);
		m_syncSpinner = new Gtk.Spinner();
		m_syncSpinner.set_size_request(32, 32);
		var syncingBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
		syncingBox.set_margin_left(30);
		syncingBox.set_margin_right(30);
		syncingBox.pack_start(m_syncSpinner);
		syncingBox.pack_start(syncingLabel);

		m_scroll1 = new ArticleListScroll();
		m_scroll2 = new ArticleListScroll();
		m_scroll1.scrolledTop.connect(dismissOverlay);
		m_scroll2.scrolledTop.connect(dismissOverlay);
		m_scroll1.valueChanged.connect(updateVisibleRows);
		m_scroll2.valueChanged.connect(updateVisibleRows);
		m_scroll1.scrolledBottom.connect(loadMore);
		m_scroll2.scrolledBottom.connect(loadMore);
		m_List1 = new ArticleListBox("1");
		m_List2 = new ArticleListBox("2");
		m_List1.row_activated.connect(rowActivated);
		m_List2.row_activated.connect(rowActivated);
		m_List1.loadDone.connect(checkForNewRows);
		m_List2.loadDone.connect(checkForNewRows);
		m_List1.balanceNextScroll.connect(m_scroll1.balanceNextScroll);
		m_List2.balanceNextScroll.connect(m_scroll2.balanceNextScroll);
		m_List1.key_press_event.connect(keyPressed);
		m_List2.key_press_event.connect(keyPressed);
		m_List1.drag_begin.connect((context) => {drag_begin(context);});
		m_List2.drag_begin.connect((context) => {drag_begin(context);});
		m_List1.drag_end.connect((context) => {drag_end(context);});
		m_List2.drag_end.connect((context) => {drag_end(context);});
		m_List1.drag_failed.connect((context, result) => {drag_failed(context, result); return false;});
		m_List2.drag_failed.connect((context, result) => {drag_failed(context, result); return false;});
		m_scroll1.add(m_List1);
		m_scroll2.add(m_List2);

		m_currentList = m_List1;
		m_currentScroll = m_scroll1;

		m_stack = new Gtk.Stack();
		m_stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		m_stack.set_transition_duration(100);
		m_stack.add_named(m_scroll1, "list1");
		m_stack.add_named(m_scroll2, "list2");
		m_stack.add_named(syncingBox, "syncing");
		m_stack.add_named(m_emptyList, "empty");
		this.add(m_stack);
		this.get_style_context().add_class("article-list");
		this.size_allocate.connect((allocation) => {
			if(allocation.height != m_height)
			{
				if(allocation.height > m_height
				&& m_stack.get_visible_child_name() != "empty"
				&& m_stack.get_visible_child_name() != "syncing")
				{
					Logger.debug("ArticleList: size changed");
					if(m_currentList.needLoadMore(allocation.height))
						loadMore.begin((obj, res) =>{
							loadMore.end(res);
						});
				}
				m_height = allocation.height;
			}
		});
	}

	public async void newList(Gtk.StackTransitionType transition = Gtk.StackTransitionType.CROSSFADE)
	{
		Logger.debug("ArticleList: newList");

		if(m_overlay != null)
			m_overlay.dismiss();

		if(m_loadThread != null)
			m_loadThread.join();

		Logger.debug("ArticleList: disallow signals from scroll");
		m_currentScroll.allowSignals(false);
		Gee.List<Article> articles = new Gee.LinkedList<Article>();
		uint offset = 0;
		SourceFunc callback = newList.callback;
		//-----------------------------------------------------------------------------------------------------------------------------------------------------
		ThreadFunc<void*> run = () => {
			int height = this.get_allocated_height();
			uint limit = height/100 + 5;
			offset = getListOffset();

			Logger.debug("load articles from db");
			articles = DataBase.readOnly().read_articles(m_selectedFeedListID,
														m_selectedFeedListType,
														m_state,
														m_searchTerm,
														limit,
														offset);
			Logger.debug("actual articles loaded: " + articles.size.to_string());

			Idle.add((owned) callback, GLib.Priority.HIGH_IDLE);
			return null;
		};
		//-----------------------------------------------------------------------------------------------------------------------------------------------------

		m_loadThread = new GLib.Thread<void*>("create", run);
		yield;

		if(articles.size == 0)
		{
			m_currentList.emptyList();
			Logger.debug("ArticleList: no content, so allow signals from scroll again");
			m_currentScroll.allowSignals(true);
			if(offset == 0)
			{
				m_emptyList.build(m_selectedFeedListID, m_selectedFeedListType, m_state, m_searchTerm);
				m_stack.set_visible_child_full("empty", transition);
			}
			else
			{
				loadNewer.begin((int)offset, 0, (obj, res) =>{
					loadNewer.end(res);
				});
			}
		}
		else
		{
			if(m_handlerID1 != 0)
			{
				m_currentList.disconnect(m_handlerID1);
				m_handlerID1 = 0;
			}

			// switch up lists
			if(m_currentList == m_List1)
			{
				Logger.debug("ArticleList: switch to list2");
				m_currentList = m_List2;
				m_currentScroll = m_scroll2;
				m_stack.set_visible_child_full("list2", transition);
			}
			else
			{
				Logger.debug("ArticleList: switch to list1");
				m_currentList = m_List1;
				m_currentScroll = m_scroll1;
				m_stack.set_visible_child_full("list1", transition);
			}

			m_currentScroll.scrollToPos(0, false);

			// restore the previous selected row
			m_handlerID1 = m_currentList.loadDone.connect(() => {
				restoreSelectedRow();
				restoreScrollPos();
				Logger.debug("ArticleList: allow signals from scroll");
				m_currentScroll.allowSignals(true);

				if(m_handlerID1 != 0)
				{
					m_currentList.disconnect(m_handlerID1);
					m_handlerID1 = 0;
				}
			});

			m_currentList.newList(articles);
		}
	}

	private void checkForNewRows()
	{
		Logger.debug("ArticleList: checkForNewRows");
		int offset;
		int count = determineNewRowCount(null, out offset);
		Logger.debug(@"new rowCount: $count");
		if(count > 0)
		{
			loadNewer.begin(count, offset, (obj, res) =>{
				loadNewer.end(res);
			});
		}
	}

	private async void loadMore()
	{
		if(m_currentList == null)
			return;

		Logger.debug("ArticleList.loadmore()");

		if(m_loadThread != null)
			m_loadThread.join();

		Gee.List<Article> articles = new Gee.LinkedList<Article>();
		SourceFunc callback = loadMore.callback;
		//-----------------------------------------------------------------------------------------------------------------------------------------------------
		ThreadFunc<void*> run = () => {
			Logger.debug("load articles from db");
			uint offset = m_currentList.getSizeForState() + determineNewRowCount(null, null);

			articles = DataBase.readOnly().read_articles(m_selectedFeedListID,
														m_selectedFeedListType,
														m_state,
														m_searchTerm,
														m_dynamicRowThreshold,
														offset);
			Logger.debug("actual articles loaded: " + articles.size.to_string());

			Idle.add((owned) callback, GLib.Priority.HIGH_IDLE);
			return null;
		};
		//-----------------------------------------------------------------------------------------------------------------------------------------------------

		m_loadThread = new GLib.Thread<void*>("create", run);
		yield;

		if(articles.size > 0)
		{
			m_currentScroll.valueChanged.disconnect(updateVisibleRows);
			m_currentList.addBottom(articles);
			m_handlerID2 = m_currentList.loadDone.connect(() => {
				m_currentScroll.startScrolledDownCooldown();
				m_currentScroll.valueChanged.connect(updateVisibleRows);

				if(m_handlerID2 != 0)
				{
					m_currentList.disconnect(m_handlerID2);
					m_handlerID2 = 0;
				}
			});
		}
		else
		{
			m_currentScroll.startScrolledDownCooldown();
		}
	}

	private async void loadNewer(int newCount, int offset)
	{
		Logger.debug(@"ArticleList: loadNewer($newCount)");
		if(m_loadThread != null)
			m_loadThread.join();

		Gee.List<Article> articles = new Gee.LinkedList<Article>();
		SourceFunc callback = loadNewer.callback;
		//-----------------------------------------------------------------------------------------------------------------------------------------------------
		ThreadFunc<void*> run = () => {
			Logger.debug("load articles from db");
			articles = DataBase.readOnly().read_articles(m_selectedFeedListID,
														m_selectedFeedListType,
														m_state,
														m_searchTerm,
														newCount,
														offset);
			Logger.debug("actual articles loaded: " + articles.size.to_string());

			Idle.add((owned) callback, GLib.Priority.HIGH_IDLE);
			return null;
		};
		//-----------------------------------------------------------------------------------------------------------------------------------------------------

		m_loadThread = new GLib.Thread<void*>("create", run);
		yield;

		if(articles.size > 0)
		{
			if(m_stack.get_visible_child_name() == "empty")
			{
				if(m_currentList == m_List1)
					m_stack.set_visible_child_full("list1", Gtk.StackTransitionType.CROSSFADE);
				else
					m_stack.set_visible_child_full("list2", Gtk.StackTransitionType.CROSSFADE);
			}

			m_currentScroll.valueChanged.disconnect(updateVisibleRows);
			m_currentList.addTop(articles);
			m_handlerID3 = m_currentList.loadDone.connect(() => {
				m_currentScroll.valueChanged.connect(updateVisibleRows);

				if(m_handlerID3 != 0)
				{
					m_currentList.disconnect(m_handlerID3);
					m_handlerID3 = 0;
				}
			});
		}
		else if(m_currentList.getSize() == 0)
		{
			m_stack.set_visible_child_full("empty", Gtk.StackTransitionType.CROSSFADE);
		}

	}

	public async void updateArticleList()
	{
		Logger.debug(@"ArticleList: updateArticleList()");

		if(m_stack.get_visible_child_name() == "empty"
		|| m_stack.get_visible_child_name() == "syncing")
		{
			Logger.debug("ArticleList: updateArticleList(): emtpy list -> create newList()");
			newList.begin(Gtk.StackTransitionType.CROSSFADE, (obj, res) => {
				newList.end(res);
			});
			return;
		}

		if(m_loadThread != null)
			m_loadThread.join();

		m_currentList.setAllUpdated(false);
		var articles = DataBase.readOnly().read_article_stats(m_currentList.getIDs());
		var children = m_currentList.get_children();

		foreach(var row in children)
		{
			var tmpRow = row as ArticleRow;
			if(tmpRow != null && articles.has_key(tmpRow.getID()))
			{
				var a = articles.get(tmpRow.getID());
				tmpRow.updateUnread(a.getUnread());
				tmpRow.updateMarked(a.getMarked());
				tmpRow.setUpdated(true);
			}
		}

		m_currentList.removeObsoleteRows();
		int length = (int)m_currentList.get_children().length();

		for(int i = 1; i < length; i++)
		{
			ArticleRow? first = m_currentList.get_row_at_index(i-1) as ArticleRow;
			ArticleRow? second = m_currentList.get_row_at_index(i) as ArticleRow;

			if(first == null
			|| second == null)
				continue;

			var insertArticles = DataBase.readOnly().read_article_between(	m_selectedFeedListID,
																			m_selectedFeedListType,
																			m_state,
																			m_searchTerm,
																			first.getID(),
																			first.getDate(),
																			second.getID(),
																			second.getDate());

			foreach(Article a in insertArticles)
			{
				if(m_currentList.insertArticle(a, i))
				{
					i++;
					length++;
				}
			}
		}

		checkForNewRows();
	}

	private int determineNewRowCount(int? newCount, out int? offset)
	{
		int count = 0;
		ArticleRow? firstRow = m_currentList.getFirstRow();

		if(firstRow != null)
		{
			count = DataBase.readOnly().getArticleCountNewerThanID(
														firstRow.getArticle().getArticleID(),
														m_selectedFeedListID,
														m_selectedFeedListType,
														m_state,
														m_searchTerm);
		}

		if(newCount != null && newCount < count)
		{
			offset = count - newCount;
			count = newCount;
		}
		else
		{
			offset = 0;
		}

		return count;
	}

	private void removeInvisibleRows(ScrollDirection direction)
	{
		if(m_scrollChangedTimeout != 0)
		{
			GLib.Source.remove(m_scrollChangedTimeout);
			m_scrollChangedTimeout = 0;
		}

		// remove lower ArticleRows only after scrolling up
		if(direction == ScrollDirection.UP)
		{
			m_scrollChangedTimeout = GLib.Timeout.add(500, () => {
				Logger.debug("ArticleList: remove invisible rows below");
				var children = m_currentList.get_children();
				children.reverse();

				foreach(var r in children)
				{
					var row = r as ArticleRow;
					if(row != null)
					{
						if(m_currentScroll.isVisible(row, m_dynamicRowThreshold) == 1)
						{
							m_currentList.removeRow(row, 0);
						}
						else
						{
							break;
						}
					}
				}
				m_scrollChangedTimeout = 0;
				return false;
			});
		}
	}

	private void updateVisibleRows(ScrollDirection direction)
	{
		if(direction == ScrollDirection.DOWN && Settings.general().get_boolean("articlelist-mark-scrolling"))
		{
			var children = m_currentList.get_children();
			children.reverse();
			var visibleArticles = new Gee.HashSet<string>();

			foreach(var r in children)
			{
				var row = r as ArticleRow;
				if(row != null)
				{
					int visible = m_currentScroll.isVisible(row);
					if(visible == 0 || visible == 1)
						visibleArticles.add(row.getID());
					else if(visible == -1)
						break;
				}
			}
			m_currentList.setVisibleRows(visibleArticles);
		}

		removeInvisibleRows(direction);
	}

	private bool keyPressed(Gdk.EventKey event)
	{
		switch(event.keyval)
		{
			case Gdk.Key.Down:
				int diff = m_currentList.move(true);
				if(m_state != ArticleListState.UNREAD)
					m_currentScroll.scrollDiff(diff);
				break;

			case Gdk.Key.Up:
				int diff = m_currentList.move(false);
				if(m_state != ArticleListState.UNREAD)
					m_currentScroll.scrollDiff(diff);
				break;

			case Gdk.Key.Page_Down:
				m_currentScroll.scrollToPos(-1);
				break;

			case Gdk.Key.Page_Up:
				m_currentScroll.scrollToPos(0);
				break;
		}
		return true;
	}

	public int move(bool down)
	{
		int diff = m_currentList.move(down);

		if(m_state != ArticleListState.UNREAD)
			m_currentScroll.scrollDiff(diff);

		return diff;
	}

	public void showOverlay()
	{
		Logger.debug("ArticleList: showOverlay");
		if(m_currentScroll.getScroll() > 0.0)
			showNotification();
	}

	private void showNotification()
	{
		if(m_overlay != null
		|| m_state != ArticleListState.ALL)
			return;

		m_overlay = new InAppNotification.withIcon(
			_("New articles"),
			"feed-arrow-up-symbolic",
			_("scroll up"));
		m_overlay.action.connect(() => {
			m_currentScroll.scrollToPos(0);
		});
		m_overlay.dismissed.connect(() => {
			m_overlay = null;
		});
		this.add_overlay(m_overlay);
		this.show_all();
	}

	public void dismissOverlay()
	{
		if(m_overlay != null)
			m_overlay.dismiss();
	}

	public Article? getSelectedArticle()
	{
		if(m_stack.get_visible_child_name() == "empty"
		|| m_stack.get_visible_child_name() == "syncing")
			return null;

		return m_currentList.getSelectedArticle();
	}

	public Article? getFirstArticle()
	{
		ArticleRow? selectedRow = m_currentList.getFirstRow();
		if(selectedRow == null)
			return null;

		return selectedRow.getArticle();
	}

	public ArticleStatus toggleReadSelected()
	{
		return m_currentList.toggleReadSelected();
	}

	public ArticleStatus toggleMarkedSelected()
	{
		return m_currentList.toggleMarkedSelected();
	}

	public void getSavedState(out double scrollPos, out int rowOffset)
	{
		Logger.debug("ArticleList: get State");

		// get current scroll position
		scrollPos = m_currentScroll.getScroll();

		// the amount of rows that are above the the current viewport
		// and thus are not visible at the moment
		// they can be skipped on startup and lazy-loaded later
		rowOffset = 0;

		var children = m_currentList.get_children();
		foreach(var row in children)
		{
			var tmpRow = row as ArticleRow;
			if(tmpRow != null)
			{
				var height = tmpRow.get_allocated_height();

				if((scrollPos-height) >= 0)
				{
					scrollPos -= height;
					++rowOffset;
				}
				else
				{
					break;
				}
			}
		}

		rowOffset += determineNewRowCount(null, null);
		Logger.debug("scrollpos %f".printf(scrollPos));
		Logger.debug("offset %i".printf(rowOffset));
	}

	private uint getListOffset()
	{
		uint offset = (uint)Settings.state().get_int("articlelist-row-offset");
		Settings.state().set_int("articlelist-row-offset", 0);
		return offset;
	}

	private void restoreSelectedRow()
	{
		string selectedRow = Settings.state().get_string("articlelist-selected-row");

		if(selectedRow != "")
		{
			m_currentList.selectRow(selectedRow, 300);
			Settings.state().set_string("articlelist-selected-row", "");
		}
	}

	private void restoreScrollPos()
	{
		var pos = Settings.state().get_double("articlelist-scrollpos");
		if(pos > 0)
		{
			Logger.debug(@"ArticleList: restore ScrollPos $pos");
			m_currentScroll.scrollDiff(pos, false);
			Settings.state().set_double("articlelist-scrollpos",  0);
		}
	}

	public void removeTagFromSelectedRow(string tagID)
	{
		m_currentList.removeTagFromSelectedRow(tagID);
	}

	public string getSelectedURL()
	{
		return m_currentList.getSelectedURL();
	}

	public bool selectedIsFirst()
	{
		return m_currentList.selectedIsFirst();
	}

	public bool selectedIsLast()
	{
		return m_currentList.selectedIsLast();
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

	public void setSelectedFeed(string feedID)
	{
		m_selectedFeedListID = feedID;
		m_List1.setSelectedFeed(feedID);
		m_List2.setSelectedFeed(feedID);
	}

	public void setSelectedType(FeedListType type)
	{
		m_selectedFeedListType = type;
		m_List1.setSelectedType(type);
		m_List2.setSelectedType(type);
	}

	public void setState(ArticleListState state)
	{
		m_state = state;
		m_List1.setState(state);
		m_List2.setState(state);
	}

	public ArticleListState getState()
	{
		return m_state;
	}

	public void setSearchTerm(string searchTerm)
	{
		m_searchTerm = searchTerm;
	}

	public void markAllAsRead()
	{
		m_currentList.markAllAsRead();
	}

	public void openSelected()
	{
		Article? selectedArticle = m_currentList.getSelectedArticle();
		if(selectedArticle != null)
		{
			try
			{
				Gtk.show_uri_on_window(MainWindow.get_default(), selectedArticle.getURL(), Gdk.CURRENT_TIME);
			}
			catch(GLib.Error e)
			{
				Logger.debug("could not open the link in an external browser: %s".printf(e.message));
			}
		}
	}

	public void centerSelectedRow()
	{
		int scroll = -(int)(m_currentScroll.getPageSize()/2);
		scroll += m_currentList.selectedRowPosition();
		m_currentScroll.scrollToPos(scroll);
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
		if(m_stack.get_visible_child_name() == "syncing" && Utils.getRelevantArticles() == 0)
		{
			m_stack.set_visible_child_full("empty", Gtk.StackTransitionType.CROSSFADE);
		}
	}

	private void rowActivated(Gtk.ListBoxRow row)
	{
		row_activated((ArticleRow)row);
	}

	public void clear()
	{
		m_currentList.emptyList();
	}
}
