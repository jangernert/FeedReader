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
	private uint m_selectSourceID = 0;
	private ArticleListState m_state = ArticleListState.ALL;
	private FeedListType m_selectedFeedListType = FeedListType.FEED;
	private string m_selectedFeedListID = FeedID.ALL.to_string();
	private string m_selectedArticle = "";

	public signal void balanceNextScroll(ArticleListBalance mode);
	public signal void loadDone();

	public ArticleListBox()
	{
		m_lazyQeue = new Gee.LinkedList<article>();
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
			return;

		m_idleID = GLib.Idle.add(() => {

			article item;

			if(reverse)
				item = m_lazyQeue.last();
			else
				item = m_lazyQeue.first();

			balanceNextScroll(balance);

			var newRow = new articleRow(item);
			newRow.rowStateChanged.connect(rowStateChanged);
			newRow.drag_begin.connect((context) => {drag_begin(context);});
			newRow.drag_end.connect((context) => {drag_end(context);});
			newRow.drag_failed.connect((context, result) => {drag_failed(context, result); return true;});
			newRow.highlight_row.connect(highlightRow);
			newRow.revert_highlight.connect(unHighlightRow);

			if(animate)
				newRow.reveal(true, 150);
			else
				newRow.reveal(true, 0);

			this.insert(newRow, pos);

			if(m_lazyQeue.size > 1)
			{
				m_lazyQeue.remove(item);
				addRow(balance, pos, reverse);
			}
			else
			{
				m_lazyQeue = new Gee.LinkedList<article>();
				m_idleID = 0;
				loadDone();
			}

			return false;
		});
	}

	private void emptyList()
	{
		var children = get_children();
		foreach(Gtk.Widget row in children)
		{
			this.remove(row);
			row.destroy();
		}
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
		row.updateUnread(ArticleStatus.READ);
		this.select_row(row);

		try
		{
			DBusConnection.get_default().changeArticle(row.getID(), ArticleStatus.READ);
		}
		catch(GLib.Error e)
		{
			Logger.error("ArticleList.selectAfter: %s".printf(e.message));
		}

		if (m_selectSourceID > 0)
		{
            GLib.Source.remove(m_selectSourceID);
            m_selectSourceID = 0;
        }

        m_selectSourceID = Timeout.add(time, () => {
            row.activate();
            //row_activated(row);
			m_selectSourceID = 0;
            return false;
        });
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
		var selectedRow = this.get_selected_row() as articleRow;
		var height = selectedRow.get_allocated_height();
		articleRow nextRow = null;
		int time = 300;

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

		if(down)
			return height;

		return -height;
	}

	public void removeRow(articleRow row, int animateDuration = 700)
	{
		row.reveal(false, animateDuration);
		GLib.Timeout.add(animateDuration + 50, () => {
			this.remove(row);
			return false;
		});
	}

	private void rowActivated(Gtk.ListBoxRow row)
	{
		var selectedRow = (articleRow)row;
		string selectedID = selectedRow.getID();

		try
		{
			if(selectedRow.isUnread())
			{
				DBusConnection.get_default().changeArticle(selectedID, ArticleStatus.READ);
				selectedRow.updateUnread(ArticleStatus.READ);
			}
		}
		catch(GLib.Error e)
		{
			Logger.error("ArticleList.constructor: %s".printf(e.message));
		}

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
								break;
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
							if((m_state == ArticleListState.UNREAD && !tmpRow.isUnread())
							|| (m_state == ArticleListState.MARKED && !tmpRow.isMarked()))
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

	public void removeTagFromSelectedRow(string tagID)
	{
		articleRow selectedRow = this.get_selected_row() as articleRow;

		if(selectedRow == null)
			return;

		selectedRow.removeTag(tagID);
	}

	public string? getFirstRowID()
	{
		var firstRow = this.get_children().first().data as articleRow;

		if(firstRow != null)
			return firstRow.getID();

		return null;
	}

	public string? getLastRowID()
	{
		var lastRow = this.get_children().last().data as articleRow;

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

	public void selectRow(string articleID)
	{
		var children = this.get_children();
		foreach(var row in children)
		{
			var tmpRow = row as articleRow;
			if(tmpRow != null && tmpRow.getID() == articleID)
			{
				this.select_row(tmpRow);
				var window = this.get_toplevel() as readerUI;
				if(window != null && !window.searchFocused())
					tmpRow.activate();
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
}
