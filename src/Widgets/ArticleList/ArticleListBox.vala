//	This file is part of FeedReader.
//
//	FeedReader is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	FeedReader is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General public License for more details.
//
//	You should have received a copy of the GNU General public License
//	along with FeedReader.  If not, see <http://www.gnu.org/licenses/>.

public class FeedReader.ArticleListBox : Gtk.ListBox {

	private Gee.LinkedList<article> m_lazyQeue;
	private uint m_idleID = 0;
	private string m_name;
	private uint m_selectSourceID = 0;
	private ArticleListState m_state = ArticleListState.ALL;
	private FeedListType m_selectedFeedListType = FeedListType.FEED;
	private string m_selectedFeedListID = FeedID.ALL.to_string();
	private string m_selectedArticle = "";
	private Gee.HashSet<string> m_articles;
	private Gee.HashSet<string> m_visibleArticles;

	public signal void balanceNextScroll(ArticleListBalance mode);
	public signal void loadDone();

	public ArticleListBox(string name)
	{
		m_name = name;
		m_lazyQeue = new Gee.LinkedList<article>();
		m_articles = new Gee.HashSet<string>();
		m_visibleArticles = new Gee.HashSet<string>();
		this.set_selection_mode(Gtk.SelectionMode.BROWSE);
		this.row_activated.connect(rowActivated);
	}

	public void newList(Gee.LinkedList<article> articles)
	{
		stopLoading();
		emptyList();
		m_lazyQeue = articles;
		addRow(ArticleListBalance.NONE);
	}

	public void addTop(Gee.LinkedList<article> articles)
	{
		stopLoading();
		m_lazyQeue = articles;
		addRow(ArticleListBalance.TOP, 0, true);
	}

	public void addBottom(Gee.LinkedList<article> articles)
	{
		stopLoading();
		m_lazyQeue = articles;
		addRow(ArticleListBalance.NONE);
	}

	private void stopLoading()
	{
		if(m_idleID > 0)
		{
			GLib.Source.remove(m_idleID);
			m_idleID = 0;
		}
	}

	private void addRow(ArticleListBalance balance, int pos = -1, bool reverse = false, bool animate = false)
	{
		if(m_lazyQeue.size == 0)
		{
			Logger.debug(@"ArticleListbox$m_name: lazyQueu == 0 -> return");
			return;
		}


		var priority = GLib.Priority.DEFAULT_IDLE;
		if(ColumnView.get_default().playingMedia())
			priority = GLib.Priority.HIGH_IDLE;

		m_idleID = GLib.Idle.add(() => {

			if(m_lazyQeue == null || m_lazyQeue.size == 0)
				return false;

			article item;

			if(reverse)
				item = m_lazyQeue.last();
			else
				item = m_lazyQeue.first();

			// check if row is already there
			if(m_articles.contains(item.getArticleID()))
			{
				Logger.warning(@"ArticleListbox$m_name: row with ID %s is already present".printf(item.getArticleID()));
				checkQueue(item, balance, pos, reverse, animate);
				return false;
			}

			m_articles.add(item.getArticleID());
			balanceNextScroll(balance);

			var newRow = new articleRow(item);
			newRow.rowStateChanged.connect(rowStateChanged);
			newRow.drag_begin.connect((widget, context) => {
				highlightRow((widget as articleRow).getID());
				drag_begin(context);
			});
			newRow.drag_end.connect((widget, context) => {
				unHighlightRow();
				drag_end(context);
			});
			newRow.drag_failed.connect((context, result) => {
				drag_failed(context, result);
				return false;
			});

			newRow.realize.connect(() => {
				checkQueue(item, balance, pos, reverse, animate);
			});

			this.insert(newRow, pos);

			if(animate)
				newRow.reveal(true, 150);
			else
				newRow.reveal(true, 0);

			return false;
		}, priority);
	}

	private void checkQueue(article item, ArticleListBalance balance, int pos = -1, bool reverse = false, bool animate = false)
	{
		if(m_lazyQeue.size > 1)
		{
			m_lazyQeue.remove(item);
			addRow(balance, pos, reverse, animate);
		}
		else
		{
			Logger.debug(@"ArticleListbox$m_name: all articles added to the list");
			m_lazyQeue = new Gee.LinkedList<article>();
			GLib.Timeout.add(150, () => {
				Logger.debug(@"ArticleListbox$m_name: loadDone()");
				loadDone();
				return false;
			});
			m_idleID = 0;
		}
	}

	public void emptyList()
	{
		var children = get_children();
		foreach(Gtk.Widget row in children)
		{
			this.remove(row);
			row.destroy();
		}
		m_articles.clear();
	}

	public void setSelectedFeed(string feedID)
	{
		m_selectedFeedListID = feedID;
	}

	public void setSelectedType(FeedListType type)
	{
		m_selectedFeedListType = type;
	}

	private void selectAfter(articleRow row, int time)
	{
		this.select_row(row);
		setRead(row);

		if(m_selectSourceID > 0)
		{
            GLib.Source.remove(m_selectSourceID);
            m_selectSourceID = 0;
        }

        m_selectSourceID = Timeout.add(time, () => {
			if(!ColumnView.get_default().searchFocused())
            	row.activate();
			m_selectSourceID = 0;
            return false;
        });
	}

	private void setRead(articleRow row)
	{
		try
		{
			if(row.isUnread())
			{
				row.updateUnread(ArticleStatus.READ);
				DBusConnection.get_default().changeArticle(row.getID(), ArticleStatus.READ);
			}
		}
		catch(GLib.Error e)
		{
			Logger.error("ArticleListBox.setRead: %s".printf(e.message));
		}
	}

	public bool toggleReadSelected()
	{
		articleRow selectedRow = this.get_selected_row() as articleRow;

		if(selectedRow == null)
			return false;

		return selectedRow.toggleUnread();
	}

	public bool toggleMarkedSelected()
	{
		articleRow selectedRow = this.get_selected_row() as articleRow;

		if(selectedRow == null)
			return false;

		return selectedRow.toggleMarked();
	}

	public string selectedURL()
	{
		articleRow selectedRow = this.get_selected_row() as articleRow;

		if(selectedRow == null)
			return "";

		return selectedRow.getURL();
	}

	public void setState(ArticleListState state)
	{
		m_state = state;
	}

	public string getSelectedArticle()
	{
		articleRow selectedRow = this.get_selected_row() as articleRow;
		if(selectedRow != null)
			return selectedRow.getID();

		if(this.get_children().length() == 0)
			return "empty";

		return "";
	}

	public ArticleStatus getSelectedArticleMarked()
	{
		articleRow selectedRow = this.get_selected_row() as articleRow;
		if(selectedRow != null)
			return selectedRow.getMarked();

		return ArticleStatus.UNMARKED;
	}

	public ArticleStatus getSelectedArticleRead()
	{
		articleRow selectedRow = this.get_selected_row() as articleRow;
		if(selectedRow != null)
			return selectedRow.getUnread();

		return ArticleStatus.READ;
	}

	public string getSelectedURL()
	{
		articleRow selectedRow = this.get_selected_row() as articleRow;
		if(selectedRow != null)
			return selectedRow.getURL();

		if(this.get_children().length() == 0)
			return "empty";

		return "";
	}

	public int move(bool down)
	{
		int time = 300;
		var sel = getSelectedArticle();
		if(sel == "empty")
		{
			Logger.debug("ArticleListBox is empty -> do nothing");
			return 0;
		}
		else if(sel == "")
		{
			Logger.debug("ArticleListBox: no row selected -> select first");
			var firstRow = getFirstRow();
			if(firstRow == null)
				return 0;
			else
			{
				selectAfter(firstRow, time);
				return 0;
			}
		}

		var selectedRow = this.get_selected_row() as articleRow;
		var height = selectedRow.get_allocated_height();
		articleRow nextRow = null;

		var rows = this.get_children();

		if(!down)
			rows.reverse();

		int current = rows.index(selectedRow);
		uint length = rows.length();

		do
		{
			current++;
			if(current >= length)
				return 0;

			nextRow = rows.nth_data(current) as articleRow;
		}
		while(!nextRow.isBeingRevealed());

		selectAfter(nextRow, time);

		Logger.debug(@"ArticleListBox.move: height: $height");

		if(down)
			return height;

		return -height;
	}

	public void removeRow(articleRow row, int animateDuration = 700)
	{
		var id = row.getID();
		row.reveal(false, animateDuration);
		m_articles.remove(id);
		GLib.Timeout.add(animateDuration + 50, () => {
			this.remove(row);
			return false;
		});
	}

	private void rowActivated(Gtk.ListBoxRow row)
	{
		var selectedRow = (articleRow)row;
		string selectedID = selectedRow.getID();
		setRead(selectedRow);

		if(m_selectedArticle != selectedID)
		{
			if(m_state != ArticleListState.ALL || m_selectedFeedListType == FeedListType.TAG)
			{
				var articleChildList = this.get_children();
				foreach(Gtk.Widget r in articleChildList)
				{
					var tmpRow = r as articleRow;
					if(tmpRow != null && tmpRow.isBeingRevealed())
					{
						if((!tmpRow.isUnread() && m_state == ArticleListState.UNREAD)
						|| (!tmpRow.isMarked() && m_state == ArticleListState.MARKED)
						|| (m_selectedFeedListType == FeedListType.TAG && !tmpRow.hasTag(m_selectedFeedListID)))
						{
							if(tmpRow.getID() != selectedID)
							{
								removeRow(tmpRow);
							}
						}
					}
				}
			}
		}

		m_selectedArticle = selectedID;
	}

	private void rowStateChanged(ArticleStatus status)
	{
		Logger.debug("state changed");
		switch(status)
		{
			case ArticleStatus.UNREAD:
			case ArticleStatus.MARKED:
				return;
			case ArticleStatus.READ:
			case ArticleStatus.UNMARKED:
				var selectedRow = this.get_selected_row() as articleRow;
				var articleChildList = this.get_children();
				foreach(Gtk.Widget row in articleChildList)
				{
					var tmpRow = row as articleRow;
					if(tmpRow != null)
					{
						if((selectedRow != null && tmpRow.getID() != selectedRow.getID())
						|| selectedRow == null)
						{
							if(m_articles.contains(tmpRow.getID()))
							{
								if((m_state == ArticleListState.UNREAD && !tmpRow.isUnread())
								|| (m_state == ArticleListState.MARKED && !tmpRow.isMarked()))
								{
									removeRow(tmpRow);
									break;
								}
							}
						}
					}
				}
				break;
		}
	}

	public void setVisibleRows(Gee.HashSet<string> visibleArticles)
	{
		var invisibleRows = new Gee.HashSet<string>();
		// mark all rows that are not visible now and have been before as read
		m_visibleArticles.foreach((id) => {
			if(!visibleArticles.contains(id))
				invisibleRows.add(id);
			return true;
		});

		m_visibleArticles = visibleArticles;

		var children = this.get_children();
		foreach(var row in children)
		{
			var tmpRow = row as articleRow;
			if(tmpRow != null && invisibleRows.contains(tmpRow.getID()))
			{
				setRead(tmpRow);
				if(m_state == ArticleListState.UNREAD && !tmpRow.isUnread())
				{
					balanceNextScroll(ArticleListBalance.BOTTOM);
					removeRow(tmpRow, 0);
				}
			}

		}
	}

	public void removeTagFromSelectedRow(string tagID)
	{
		articleRow selectedRow = this.get_selected_row() as articleRow;

		if(selectedRow == null)
			return;

		selectedRow.removeTag(tagID);
	}

	public string? getFirstRowID()
	{
		var children = this.get_children();

		if(children == null)
			return null;

		var firstRow = children.first().data as articleRow;

		if(firstRow == null)
			return null;

		return firstRow.getID();
	}

	private articleRow? getFirstRow()
	{
		var children = this.get_children();

		if(children == null)
			return null;

		var firstRow = children.first().data as articleRow;

		if(firstRow == null)
			return null;

		return firstRow;
	}

	public string? getLastRowID()
	{
		var children = this.get_children();

		if(children == null)
			return null;

		var lastRow = children.last().data as articleRow;

		if(lastRow != null)
			return lastRow.getID();

		return null;
	}

	public bool selectedIsFirst()
	{
		var selectedRow = this.get_selected_row() as articleRow;
		var children = this.get_children();
		int n = children.index(selectedRow);
		var lastRow = children.first().data as articleRow;

		if(n == 0)
			return true;
		else if(m_state == ArticleListState.UNREAD && n == 1 && !lastRow.isBeingRevealed())
			return true;

		return false;
	}

	public bool selectedIsLast()
	{
		var selectedRow = this.get_selected_row() as articleRow;
		var children = this.get_children();
		int n = children.index(selectedRow);
		uint length = children.length();
		var lastRow = children.last().data as articleRow;

		if(n + 1 == length)
			return true;
		else if(m_state == ArticleListState.UNREAD && n + 2 == length && !lastRow.isBeingRevealed())
			return true;

		return false;
	}

	public void markAllAsRead()
	{
		var children = this.get_children();

		foreach(var row in children)
		{
			var tmpRow = row as articleRow;
			if(tmpRow != null)
				tmpRow.updateUnread(ArticleStatus.READ);
		}
	}

	public int selectedRowPosition()
	{
		articleRow selectedRow = this.get_selected_row() as articleRow;

		int scroll = 0;
		if(selectedRow == null)
			return scroll;

		var FeedChildList = this.get_children();
		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpRow = row as articleRow;
			if(tmpRow != null)
			{
				if(tmpRow.getID() == selectedRow.getID())
				{
					scroll += tmpRow.get_allocated_height()/2;
					Logger.debug("scroll: %i".printf(scroll));
					break;
				}
				else if(tmpRow.isRevealed())
				{
					scroll += tmpRow.get_allocated_height();
					Logger.debug("scroll: %i".printf(scroll));
				}
			}
		}
		return scroll;
	}

	public void selectRow(string articleID, int time = 10)
	{
		var children = this.get_children();
		foreach(var row in children)
		{
			var tmpRow = row as articleRow;
			if(tmpRow != null && tmpRow.getID() == articleID)
			{
				selectAfter(tmpRow, time);
			}
		}
	}

	private void highlightRow(string articleID)
	{
		var children = this.get_children();
		foreach(var row in children)
		{
			var tmpRow = row as articleRow;
			if(tmpRow != null && tmpRow.getID() != articleID)
				tmpRow.opacity = 0.5;
		}
	}

	private void unHighlightRow()
	{
		var children = this.get_children();
		foreach(var row in children)
		{
			var tmpRow = row as articleRow;
			if(tmpRow != null)
				tmpRow.opacity = 1.0;
		}
	}

	public int getSize()
	{
		return m_articles.size;
	}

	public bool needLoadMore(int height)
	{
		int rowHeight = 0;

		var FeedChildList = this.get_children();
		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpRow = row as articleRow;
			if(tmpRow != null && tmpRow.isRevealed())
				rowHeight += tmpRow.get_allocated_height();
		}

		if(rowHeight < height + 100)
			return true;

		return false;
	}
}
