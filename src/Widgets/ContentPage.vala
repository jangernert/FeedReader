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

public class FeedReader.ContentPage : Gtk.Paned {

	private Gtk.Paned m_pane;
	private articleView m_article_view;
	private articleList m_articleList;
	private feedList m_feedList;
	private FeedListFooter m_footer;
	public signal void showArticleButtons(bool show);


	public ContentPage()
	{
		logger.print(LogMessage.DEBUG, "ContentPage: setup FeedList");
		this.orientation = Gtk.Orientation.HORIZONTAL;

		this.set_position(settings_state.get_int("feeds-and-articles-width"));

		m_feedList = new feedList();
		m_footer = new FeedListFooter();
		var feedListBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		feedListBox.pack_start(m_feedList);
		feedListBox.pack_end(m_footer, false, false);

		m_pane = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);
		m_pane.set_size_request(0, 300);
		m_pane.set_position(settings_state.get_int("feed-row-width"));
		m_pane.pack1(feedListBox, false, false);

		m_feedList.newFeedSelected.connect((feedID) => {
			m_articleList.setSelectedType(FeedListType.FEED);
			m_article_view.clearContent();
			m_articleList.setSelectedFeed(feedID);
			m_articleList.newHeadlineList();

			if(feedID == FeedID.ALL)
			{
				m_footer.setRemoveButtonSensitive(false);
			}
			else
			{
				m_footer.setRemoveButtonSensitive(true);
				m_footer.setSelectedRow(FeedListType.FEED, feedID);
			}
 		});

		m_feedList.newTagSelected.connect((tagID) => {
			m_articleList.setSelectedType(FeedListType.TAG);
			m_article_view.clearContent();
			m_articleList.setSelectedFeed(tagID);
			m_articleList.newHeadlineList();
			m_footer.setRemoveButtonSensitive(true);
			m_footer.setSelectedRow(FeedListType.TAG, tagID);
		});

		m_feedList.newCategorieSelected.connect((categorieID) => {
			m_articleList.setSelectedType(FeedListType.CATEGORY);
			m_article_view.clearContent();
			m_articleList.setSelectedFeed(categorieID);
			m_articleList.newHeadlineList();

			if(categorieID != CategoryID.MASTER && categorieID != CategoryID.TAGS)
			{
				m_footer.setRemoveButtonSensitive(true);
				m_footer.setSelectedRow(FeedListType.CATEGORY, categorieID);
			}
			else
			{
				m_footer.setRemoveButtonSensitive(false);
			}
		});

		m_feedList.markAllArticlesAsRead.connect(markAllArticlesAsRead);


		m_articleList = new articleList();
		m_articleList.drag_begin.connect((context) => {
			m_feedList.expand_collapse_category(CategoryID.TAGS, true);
			m_feedList.expand_collapse_category(CategoryID.MASTER, false);
			m_feedList.addEmptyTagRow();
		});
		m_articleList.drag_end.connect((context) => {
			m_feedList.expand_collapse_category(CategoryID.MASTER, true);
		});
		m_articleList.drag_failed.connect((context, result) => {
			m_feedList.removeEmptyTagRow();
			return true;
		});
		setArticleListState((ArticleListState)settings_state.get_enum("show-articles"));

		m_pane.pack2(m_articleList, false, false);


		m_articleList.row_activated.connect((row) => {
			if(row.isUnread()){
				feedDaemon_interface.changeArticle(row.getID(), ArticleStatus.READ);
				row.updateUnread(ArticleStatus.READ);
			}

			showArticleButtons(true);

			var window = ((rssReaderApp)GLib.Application.get_default()).getWindow();
			if(window != null)
			{
				var header = window.getHeaderBar();
				logger.print(LogMessage.DEBUG, "contentPage: set headerbar");
				header.setRead(row.isUnread());
				header.setMarked(row.isMarked());
			}

			if(m_article_view.getCurrentArticle() != row.getID())
			{
				m_article_view.fillContent(row.getID());
			}
		});

		m_articleList.noRowActive.connect(() => {
			showArticleButtons(false);
		});

		m_article_view = new articleView();
		m_article_view.enterFullscreen.connect(enterFullscreen);
		m_article_view.leaveFullscreen.connect(leaveFullscreen);


		this.pack1(m_pane, false, false);
		this.pack2(m_article_view, true, false);
	}

	public void enterFullscreen()
	{
		if(settings_tweaks.get_boolean("fullscreen-videos"))
			m_pane.set_visible(false);
	}

	public void leaveFullscreen()
	{
		m_pane.set_visible(true);
	}

	public void ArticleListNEXT()
	{
		leaveFullscreen();
		m_articleList.move(false);
	}

	public void ArticleListPREV()
	{
		leaveFullscreen();
		m_articleList.move(true);
	}

	public void newHeadlineList(Gtk.StackTransitionType transition = Gtk.StackTransitionType.CROSSFADE)
	{
		m_articleList.newHeadlineList(transition);
	}

	public void newFeedList(bool defaultSettings = false)
	{
		m_feedList.newFeedlist(defaultSettings);
	}

	public void updateFeedList()
	{
		m_feedList.refreshCounters();
	}

	public void reloadArticleView()
	{
		m_article_view.reload();
	}

	public void updateArticleList()
	{
		m_articleList.updateArticleList();
	}

	public void setArticleListState(ArticleListState state)
	{
		switch(state)
		{
			case ArticleListState.ALL:
				m_articleList.setOnlyUnread(false);
				m_articleList.setOnlyMarked(false);
				break;

			case ArticleListState.UNREAD:
				m_articleList.setOnlyUnread(true);
				m_articleList.setOnlyMarked(false);
				break;

			case ArticleListState.MARKED:
				m_articleList.setOnlyUnread(false);
				m_articleList.setOnlyMarked(true);
				break;
		}
	}

	public void setSearchTerm(string searchTerm)
	{
		m_articleList.setSearchTerm(searchTerm);
		m_article_view.setSearchTerm(searchTerm);
	}

	public void clearArticleView()
	{
		m_article_view.clearContent();
	}

	public string[] getExpandedCategories()
	{
		return m_feedList.getExpandedCategories();
	}

	public double getFeedListScrollPos()
	{
		return m_feedList.getScrollPos();
	}

	public string getSelectedFeedListRow()
	{
		return m_feedList.getSelectedRow();
	}

	public int getFeedListWidth()
	{
		return m_pane.get_position();
	}

	public void setFeedListWidth(int pos)
	{
		m_pane.set_position(pos);
	}

	public int getArticlePlusFeedListWidth()
	{
		return this.get_position();
	}

	public void setArticlePlusFeedListWidth(int pos)
	{
		this.set_position(pos);
	}

	public void getArticleListState(out double scrollPos, out int offset)
	{
		m_articleList.getArticleListState(out scrollPos, out offset);
	}

	public int getArticleViewScrollPos()
	{
		return m_article_view.getScrollPos();
	}

	public string getSelectedArticle()
	{
		return m_articleList.getSelectedArticle();
	}

	public ArticleStatus getSelectedArticleMarked()
	{
		return m_articleList.getSelectedArticleMarked();
	}

	public ArticleStatus getSelectedArticleRead()
	{
		return m_articleList.getSelectedArticleRead();
	}

	public string getSelectedURL()
	{
		return m_articleList.getSelectedURL();
	}

	public void markAllArticlesAsRead()
	{
		m_articleList.markAllAsRead();
	}

	public void toggleReadSelectedArticle()
	{
		m_articleList.toggleReadSelected();
	}

	public void toggleMarkedSelectedArticle()
	{
		m_articleList.toggleMarkedSelected();
	}

	public void openSelectedArticle()
	{
		m_articleList.openSelected();
	}

	public void centerSelectedRow()
	{
		m_articleList.centerSelectedRow();
	}

	public void removeTagFromSelectedRow(string tagID)
	{
		m_articleList.removeTagFromSelectedRow(tagID);
	}

	public Gee.ArrayList<tag> getSelectedArticleTags()
	{
		string id = m_articleList.getSelectedArticle();
		var article = dataBase.read_article(id);
		unowned Gee.ArrayList<string> tagIDs = article.getTags();

		var tags = new Gee.ArrayList<tag>();

		foreach(string tagID in tagIDs)
		{
			tags.add(dataBase.read_tag(tagID));
		}

		return tags;
	}

	public void syncStarted()
	{
		m_articleList.syncStarted();
	}

	public void syncFinished()
	{
		m_articleList.syncFinished();
	}

	public void updateAccountInfo()
	{
		m_feedList.updateAccountInfo();
	}

	public Gdk.RGBA getBackgroundColor()
	{
		return m_articleList.getBackgroundColor();
	}

	public void showArticleListOverlay()
	{
		m_articleList.showOverlay();
	}

	public void setOffline()
	{
		m_feedList.setOffline();
	}

	public void setOnline()
	{
		m_feedList.setOnline();
	}

	public void footerSetBusy()
	{
		m_footer.setBusy();
	}

	public void footerSetReady()
	{
		m_footer.setReady();
	}

	public feedList getFeedList()
	{
		return m_feedList;
	}
}
