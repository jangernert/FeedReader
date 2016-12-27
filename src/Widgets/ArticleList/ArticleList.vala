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
	private ulong m_handlerID = 0;

	public signal void row_activated(articleRow? row);

	public ArticleList()
	{
		m_emptyList = new ArticleListEmptyLabel();

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
		m_scroll1.valueChanged.connect(removeInvisibleRows);
		m_scroll2.valueChanged.connect(removeInvisibleRows);
		m_scroll1.scrolledBottom.connect(loadMore);
		m_scroll2.scrolledBottom.connect(loadMore);
		m_List1 = new ArticleListBox();
		m_List2 = new ArticleListBox();
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
		m_scroll1.add(m_List1);
		m_scroll2.add(m_List2);

		m_currentList = m_List1;
		m_currentScroll = m_scroll1;

		m_stack = new Gtk.Stack();
		m_stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		m_stack.set_transition_duration(100);
		m_stack.add_named(m_scroll1, "list1");
		m_stack.add_named(m_scroll2, "list2");
		m_stack.add_named(m_emptyList, "empty");
		m_stack.add_named(syncingBox, "syncing");
		this.add(m_stack);
		this.get_style_context().add_class("article-list");
	}

	public async void newList(Gtk.StackTransitionType transition = Gtk.StackTransitionType.CROSSFADE)
	{
		Logger.debug("ArticleList: newList");

		if(m_overlay != null)
			m_overlay.dismiss();

		// switch up lists
		if(m_currentList == m_List1)
		{
			m_currentList = m_List2;
			m_currentScroll = m_scroll2;
			m_stack.set_visible_child_full("list2", transition);
		}
		else
		{
			m_currentList = m_List1;
			m_currentScroll = m_scroll1;
			m_stack.set_visible_child_full("list1", transition);
		}

		if(m_loadThread != null)
			m_loadThread.join();

		m_currentScroll.scrolledBottom.disconnect(loadMore);
		var articles = new Gee.LinkedList<article>();
		uint offset = 0;
		bool newArticles = false;
		if(Settings.state().get_int("articlelist-new-rows") > 0)
			newArticles = true;
		SourceFunc callback = newList.callback;
		//-----------------------------------------------------------------------------------------------------------------------------------------------------
		ThreadFunc<void*> run = () => {
			int height = this.get_allocated_height();
			uint limit = height/100 + 5;
			offset = getListOffset();

			Logger.debug("load articles from db");
			articles = dbUI.get_default().read_articles(m_selectedFeedListID,
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
			m_emptyList.build(m_selectedFeedListID, m_selectedFeedListType, m_state, m_searchTerm);
			m_stack.set_visible_child_full("empty", transition);
			m_currentScroll.scrolledBottom.connect(loadMore);
		}
		else
		{
			m_currentList.newList(articles);

			// restore the previous selected row
			m_handlerID = m_currentList.loadDone.connect(() => {
				restoreSelectedRow();
				restoreScrollPos();
				m_currentScroll.scrolledBottom.connect(loadMore);
				if(newArticles)
					showNotification();

				if(m_handlerID != 0)
				{
					m_currentList.disconnect(m_handlerID);
					m_handlerID = 0;
				}
			});
		}
	}

	private void checkForNewRows()
	{
		Logger.debug("ArticleList: checkForNewRows");
		int offset;
		int count = determineNewRowCount(null, out offset);
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

		var articles = new Gee.LinkedList<article>();
		SourceFunc callback = loadMore.callback;
		//-----------------------------------------------------------------------------------------------------------------------------------------------------
		ThreadFunc<void*> run = () => {
			Logger.debug("load articles from db");
			uint offset = m_currentList.getSize() + determineNewRowCount(null, null);

			articles = dbUI.get_default().read_articles(m_selectedFeedListID,
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
			m_currentList.addBottom(articles);
	}

	private async void loadNewer(int newCount, int offset)
	{
		Logger.debug(@"ArticleList: loadNewer($newCount)");
		if(m_loadThread != null)
			m_loadThread.join();

		var articles = new Gee.LinkedList<article>();
		SourceFunc callback = loadNewer.callback;
		//-----------------------------------------------------------------------------------------------------------------------------------------------------
		ThreadFunc<void*> run = () => {
			Logger.debug("load articles from db");
			articles = dbUI.get_default().read_articles(m_selectedFeedListID,
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
			m_currentList.addTop(articles);
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

		var children = m_currentList.get_children();
		uint listSize = children.length();
		string? firstRowID = m_currentList.getFirstRowID();
		int newCount = 0;
		if(firstRowID == null)
			return;

		var articles = new Gee.LinkedList<article>();
		SourceFunc callback = updateArticleList.callback;
		//-----------------------------------------------------------------------------------------------------------------------------------------------------
		ThreadFunc<void*> run = () => {
			Logger.debug("load articles from db");
			newCount = dbUI.get_default().getArticleCountNewerThanID(
														firstRowID,
														m_selectedFeedListID,
														m_selectedFeedListType,
														m_state,
														m_searchTerm);

			articles = dbUI.get_default().read_articles(m_selectedFeedListID,
														m_selectedFeedListType,
														m_state,
														m_searchTerm,
														listSize,
														newCount);
			Logger.debug("actual articles loaded: " + articles.size.to_string());

			Idle.add((owned) callback, GLib.Priority.HIGH_IDLE);
			return null;
		};
		//-----------------------------------------------------------------------------------------------------------------------------------------------------

		m_loadThread = new GLib.Thread<void*>("create", run);
		yield;

		if(articles.size == 0)
			return;

		var iterator = articles.list_iterator();

		foreach(var row in children)
		{
			iterator.next();
			var articleRow = row as articleRow;
			var article = iterator.get();

			if(articleRow.getID() == article.getArticleID())
			{
				articleRow.updateUnread(article.getUnread());
				articleRow.updateMarked(article.getMarked());
			}
			else
			{
				Logger.error("ArticleList.updateArticleList: id mismatch");
			}
		}

		if(newCount > 0)
			checkForNewRows();
	}

	private int determineNewRowCount(int? newCount, out int? offset)
	{
		int count = 0;
		string? firstRowID = m_currentList.getFirstRowID();

		if(firstRowID != null)
		{
			count = dbUI.get_default().getArticleCountNewerThanID(
														firstRowID,
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

		// remove lower articleRows only after scrolling up
		if(direction == ScrollDirection.UP)
		{
			m_scrollChangedTimeout = GLib.Timeout.add(500, () => {
				Logger.debug("ArticleList: remove invisible rows below");
				var children = m_currentList.get_children();
				children.reverse();

				foreach(var r in children)
				{
					var row = r as articleRow;
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

	public void move(bool down)
	{
		int diff = m_currentList.move(down);

		if(m_state != ArticleListState.UNREAD)
			m_currentScroll.scrollDiff(diff);
	}

	public void showOverlay()
	{
		if(m_currentScroll.getScroll() > 0.0)
			showNotification();
	}

	private void showNotification()
	{
		if(m_overlay != null)
			return;

		m_overlay = new InAppNotification.withIcon(
			_("New Articles"),
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

	public string getSelectedArticle()
	{
		return m_currentList.getSelectedArticle();
	}

	public bool toggleReadSelected()
	{
		return m_currentList.toggleReadSelected();
	}

	public bool toggleMarkedSelected()
	{
		return m_currentList.toggleMarkedSelected();
	}

	public void getArticleListState(out double scrollPos, out int rowOffset)
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
			var tmpRow = row as articleRow;
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
		if(m_state == ArticleListState.ALL)
			offset += (uint)Settings.state().get_int("articlelist-new-rows");
		Settings.state().set_int("articlelist-row-offset", 0);
		Settings.state().set_int("articlelist-new-rows", 0);
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
			m_currentScroll.scrollDiff(pos);
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

	public void setSearchTerm(string searchTerm)
	{
		m_searchTerm = searchTerm;
	}

	public void markAllAsRead()
	{
		m_currentList.markAllAsRead();
	}

	public ArticleStatus getSelectedArticleMarked()
	{
		return m_currentList.getSelectedArticleMarked();
	}

	public ArticleStatus getSelectedArticleRead()
	{
		return m_currentList.getSelectedArticleRead();
	}

	public void openSelected()
	{
		string selectedURL = m_currentList.selectedURL();
		try
		{
			Gtk.show_uri(Gdk.Screen.get_default(), selectedURL, Gdk.CURRENT_TIME);
		}
		catch(GLib.Error e)
		{
			Logger.debug("could not open the link in an external browser: %s".printf(e.message));
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
		if(m_stack.get_visible_child_name() == "syncing")
		{
			m_stack.set_visible_child_full("empty", Gtk.StackTransitionType.CROSSFADE);
		}
	}

	private void rowActivated(Gtk.ListBoxRow row)
	{
		row_activated((articleRow)row);
	}
}
