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

	private Gee.List<Article> m_lazyQeue;
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
		m_lazyQeue = new Gee.LinkedList<Article>();
		m_articles = new Gee.HashSet<string>();
		m_visibleArticles = new Gee.HashSet<string>();
		this.set_selection_mode(Gtk.SelectionMode.BROWSE);
		this.row_activated.connect(rowActivated);
	}

	public void newList(Gee.List<Article> articles)
	{
		stopLoading();
		emptyList();
		setPos(articles, -1);
		m_lazyQeue = articles;
		addRow(ArticleListBalance.NONE);
	}

	public void addTop(Gee.List<Article> articles)
	{
		stopLoading();
		setPos(articles, 0);
		m_lazyQeue = articles;
		addRow(ArticleListBalance.TOP, true);
	}

	public void addBottom(Gee.List<Article> articles)
	{
		stopLoading();
		setPos(articles, -1);
		m_lazyQeue = articles;
		addRow(ArticleListBalance.NONE);
	}

	private bool stopLoading()
	{
		if(m_idleID > 0)
		{
			GLib.Source.remove(m_idleID);
			m_idleID = 0;
			return true;
		}

		return false;
	}

	private void setPos(Gee.List<Article> articles, int pos)
	{
		foreach(Article a in articles)
		{
			a.setPos(pos);
		}
	}

	private void addRow(ArticleListBalance balance, bool reverse = false, bool animate = false)
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

			Article item;

			if(reverse)
				item = m_lazyQeue.last();
			else
				item = m_lazyQeue.first();

			// check if row is already there
			if(m_articles.contains(item.getArticleID()))
			{
				Logger.debug(@"ArticleListbox$m_name: row with ID %s is already present".printf(item.getArticleID()));
				checkQueue(item, balance, reverse, animate);
				return false;
			}

			m_articles.add(item.getArticleID());
			balanceNextScroll(balance);

			var newRow = new ArticleRow(item);
			newRow.rowStateChanged.connect(rowStateChanged);
			newRow.drag_begin.connect((widget, context) => {
				highlightRow((widget as ArticleRow).getID());
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
				checkQueue(item, balance, reverse, animate);
			});

			this.insert(newRow, item.getPos());

			if(animate)
				newRow.reveal(true, 150);
			else
				newRow.reveal(true, 0);

			return false;
		}, priority);
	}

	private void checkQueue(Article item, ArticleListBalance balance, bool reverse = false, bool animate = false)
	{
		if(m_lazyQeue.size > 1)
		{
			m_lazyQeue.remove(item);
			addRow(balance, reverse, animate);
		}
		else
		{
			Logger.debug(@"ArticleListbox$m_name: all articles added to the list");
			m_lazyQeue = new Gee.LinkedList<Article>();
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

	private void selectAfter(ArticleRow row, int time)
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

	private void setRead(ArticleRow row)
	{
		if(row.getArticle().getUnread() == ArticleStatus.UNREAD)
		{
			row.updateUnread(ArticleStatus.READ);
			FeedReaderBackend.get_default().updateArticleRead(row.getArticle());
		}
	}

	public ArticleStatus toggleReadSelected()
	{
		ArticleRow selectedRow = this.get_selected_row() as ArticleRow;

		if(selectedRow == null)
			return ArticleStatus.READ;

		return selectedRow.toggleUnread();
	}

	public ArticleStatus toggleMarkedSelected()
	{
		ArticleRow selectedRow = this.get_selected_row() as ArticleRow;

		if(selectedRow == null)
			return ArticleStatus.UNMARKED;

		return selectedRow.toggleMarked();
	}

	public void setState(ArticleListState state)
	{
		m_state = state;
	}

	public Article? getSelectedArticle()
	{
		ArticleRow selectedRow = this.get_selected_row() as ArticleRow;
		if(selectedRow != null)
			return selectedRow.getArticle();

		return null;
	}

	public string getSelectedURL()
	{
		ArticleRow selectedRow = this.get_selected_row() as ArticleRow;
		if(selectedRow != null)
			return selectedRow.getURL();

		if(this.get_children().length() == 0)
			return "empty";

		return "";
	}

	public int move(bool down)
	{
		int time = 300;
		Article? sel = getSelectedArticle();
		if(sel == null)
		{
			ArticleRow? firstRow = getFirstRow();
			if(firstRow == null)
				return 0;
			else
			{
				selectAfter(firstRow, time);
				return 0;
			}
		}

		var selectedRow = this.get_selected_row() as ArticleRow;
		var height = selectedRow.get_allocated_height();
		ArticleRow nextRow = null;

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

			nextRow = rows.nth_data(current) as ArticleRow;
		}
		while(!nextRow.isBeingRevealed());

		selectAfter(nextRow, time);

		Logger.debug(@"ArticleListBox.move: height: $height");

		if(down)
			return height;

		return -height;
	}

	public void removeRow(ArticleRow row, int animateDuration = 700)
	{
		var id = row.getID();
		row.reveal(false, animateDuration);
		m_articles.remove(id);
		GLib.Timeout.add(animateDuration + 50, () => {
			if(row.get_parent() != null)
				this.remove(row);
			return false;
		});
	}

	private void rowActivated(Gtk.ListBoxRow row)
	{
		var selectedRow = (ArticleRow)row;
		string selectedID = selectedRow.getID();
		setRead(selectedRow);

		if(m_selectedArticle != selectedID)
		{
			if(m_state != ArticleListState.ALL || m_selectedFeedListType == FeedListType.TAG)
			{
				var articleChildList = this.get_children();
				foreach(Gtk.Widget r in articleChildList)
				{
					var tmpRow = r as ArticleRow;
					if(tmpRow != null && tmpRow.isBeingRevealed())
					{
						if((tmpRow.getArticle().getUnread() == ArticleStatus.READ && m_state == ArticleListState.UNREAD)
						|| (tmpRow.getArticle().getMarked() == ArticleStatus.UNMARKED && m_state == ArticleListState.MARKED)
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
				var selectedRow = this.get_selected_row() as ArticleRow;
				var articleChildList = this.get_children();
				foreach(Gtk.Widget row in articleChildList)
				{
					var tmpRow = row as ArticleRow;
					if(tmpRow != null)
					{
						if((selectedRow != null && tmpRow.getID() != selectedRow.getID())
						|| selectedRow == null)
						{
							if(m_articles.contains(tmpRow.getID()))
							{
								if((m_state == ArticleListState.UNREAD && tmpRow.getArticle().getUnread() == ArticleStatus.READ)
								|| (m_state == ArticleListState.MARKED && tmpRow.getArticle().getMarked() == ArticleStatus.UNMARKED))
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
			var tmpRow = row as ArticleRow;
			if(tmpRow != null && invisibleRows.contains(tmpRow.getID()))
			{
				setRead(tmpRow);
				if(m_state == ArticleListState.UNREAD && tmpRow.getArticle().getUnread() == ArticleStatus.READ)
				{
					balanceNextScroll(ArticleListBalance.BOTTOM);
					removeRow(tmpRow, 0);
				}
			}

		}
	}

	public void removeTagFromSelectedRow(string tagID)
	{
		ArticleRow selectedRow = this.get_selected_row() as ArticleRow;

		if(selectedRow == null)
			return;

		selectedRow.removeTag(tagID);
	}

	public ArticleRow? getFirstRow()
	{
		var children = this.get_children();

		if(children == null)
			return null;

		var firstRow = children.first().data as ArticleRow;

		if(firstRow == null)
			return null;

		return firstRow;
	}

	public ArticleRow? getLastRow()
	{
		var children = this.get_children();

		if(children == null)
			return null;

		var lastRow = children.last().data as ArticleRow;

		if(lastRow == null)
			return null;

		return lastRow;
	}

	public bool selectedIsFirst()
	{
		var selectedRow = this.get_selected_row() as ArticleRow;
		var children = this.get_children();
		int n = children.index(selectedRow);
		var lastRow = children.first().data as ArticleRow;

		if(n == 0)
			return true;
		else if(m_state == ArticleListState.UNREAD && n == 1 && !lastRow.isBeingRevealed())
			return true;

		return false;
	}

	public bool selectedIsLast()
	{
		var selectedRow = this.get_selected_row() as ArticleRow;
		var children = this.get_children();
		int n = children.index(selectedRow);
		uint length = children.length();
		var lastRow = children.last().data as ArticleRow;

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
			var tmpRow = row as ArticleRow;
			if(tmpRow != null)
				tmpRow.updateUnread(ArticleStatus.READ);
		}
	}

	public int selectedRowPosition()
	{
		ArticleRow selectedRow = this.get_selected_row() as ArticleRow;

		int scroll = 0;
		if(selectedRow == null)
			return scroll;

		var FeedChildList = this.get_children();
		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpRow = row as ArticleRow;
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
			var tmpRow = row as ArticleRow;
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
			var tmpRow = row as ArticleRow;
			if(tmpRow != null && tmpRow.getID() != articleID)
				tmpRow.opacity = 0.5;
		}
	}

	private void unHighlightRow()
	{
		var children = this.get_children();
		foreach(var row in children)
		{
			var tmpRow = row as ArticleRow;
			if(tmpRow != null)
				tmpRow.opacity = 1.0;
		}
	}

	public int getSize()
	{
		return m_articles.size;
	}

	public int getSizeForState()
	{
		if(m_state == ArticleListState.UNREAD)
		{
			int unread = 0;
			var children = this.get_children();
			foreach(var row in children)
			{
				var tmpRow = row as ArticleRow;
				if(tmpRow != null && tmpRow.getArticle().getUnread() == ArticleStatus.UNREAD)
					unread += 1;
			}
			return unread;
		}

		return getSize();
	}

	public bool needLoadMore(int height)
	{
		int rowHeight = 0;

		var FeedChildList = this.get_children();
		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpRow = row as ArticleRow;
			if(tmpRow != null && tmpRow.isRevealed())
				rowHeight += tmpRow.get_allocated_height();
		}

		if(rowHeight < height + 100)
			return true;

		return false;
	}

	public Gee.List<string> getIDs()
	{
		var tmp = new Gee.LinkedList<string>();
		foreach(string id in m_articles)
		{
			tmp.add(id);
		}
		return tmp;
	}

	public void setAllUpdated(bool updated = false)
	{
		var children = this.get_children();
		foreach(var row in children)
		{
			var tmpRow = row as ArticleRow;
			if(tmpRow != null)
				tmpRow.setUpdated(updated);
		}
	}

	public void removeObsoleteRows()
	{
		var children = this.get_children();
		foreach(var row in children)
		{
			var tmpRow = row as ArticleRow;
			if(tmpRow != null && !tmpRow.getUpdated())
			{
				removeRow(tmpRow, 50);
			}
		}
	}

	public bool insertArticle(Article a, int pos)
	{
		if(m_articles.contains(a.getArticleID()))
		{
			Logger.debug(@"ArticleListbox$m_name: row with ID %s is already present".printf(a.getArticleID()));
			return false;
		}

		a.setPos(pos);
		stopLoading();
		var list = new Gee.LinkedList<Article>();
		list.add(a);
		m_lazyQeue = list;
		addRow(ArticleListBalance.NONE, false, false);
		return true;
	}
}
