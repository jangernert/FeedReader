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

public class FeedReader.ColumnView : Gtk.Paned {

	private Gtk.Paned m_pane;
	private articleView m_article_view;
	private ArticleList m_articleList;
	private feedList m_feedList;
	private FeedListFooter m_footer;
	private ColumnViewHeader m_headerbar;

	private static ColumnView? m_columnView = null;

	public static ColumnView get_default()
	{
		if(m_columnView == null)
			m_columnView = new ColumnView();

		return m_columnView;
	}


	private ColumnView()
	{
		Logger.debug("ContentPage: setup FeedList");

		m_feedList = new feedList();
		m_footer = new FeedListFooter();
		var feedListBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		feedListBox.pack_start(m_feedList);
		feedListBox.pack_end(m_footer, false, false);

		m_pane = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);
		m_pane.set_size_request(0, 300);
		m_pane.set_position(Settings.state().get_int("feed-row-width"));
		m_pane.pack1(feedListBox, false, false);

		m_feedList.clearSelected.connect(() => {
			m_footer.setRemoveButtonSensitive(false);
		});

		m_feedList.newFeedSelected.connect((feedID) => {
			Logger.debug("ContentPage: new Feed selected");
			m_articleList.setSelectedType(FeedListType.FEED);
			m_article_view.clearContent();
			m_headerbar.showArticleButtons(false);
			m_articleList.setSelectedFeed(feedID);
			newArticleList();

			if(feedID == FeedID.ALL.to_string())
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
			Logger.debug("ContentPage: new Tag selected");
			m_articleList.setSelectedType(FeedListType.TAG);
			m_article_view.clearContent();
			m_headerbar.showArticleButtons(false);
			m_articleList.setSelectedFeed(tagID);
			newArticleList();
			m_footer.setRemoveButtonSensitive(true);
			m_footer.setSelectedRow(FeedListType.TAG, tagID);
		});

		m_feedList.newCategorieSelected.connect((categorieID) => {
			Logger.debug("ContentPage: new Category selected");
			m_articleList.setSelectedType(FeedListType.CATEGORY);
			m_article_view.clearContent();
			m_headerbar.showArticleButtons(false);
			m_articleList.setSelectedFeed(categorieID);
			newArticleList();

			if(categorieID != CategoryID.MASTER.to_string()
			&& categorieID != CategoryID.TAGS.to_string())
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


		m_articleList = new ArticleList();
		m_articleList.drag_begin.connect((context) => {
			if(dbUI.get_default().read_tags().is_empty)
				m_feedList.newFeedlist(m_articleList.getState(), false, true);
			m_feedList.expand_collapse_category(CategoryID.TAGS.to_string(), true);
			m_feedList.expand_collapse_category(CategoryID.MASTER.to_string(), false);
			m_feedList.addEmptyTagRow();
		});
		m_articleList.drag_end.connect((context) => {
			Logger.debug("ContentPage: articleList drag_end signal");
			m_feedList.expand_collapse_category(CategoryID.MASTER.to_string(), true);
		});
		m_articleList.drag_failed.connect((context, result) => {
			Logger.debug("ContentPage: articleList drag_failed signal");
			if(dbUI.get_default().read_tags().is_empty)
				m_feedList.newFeedlist(m_articleList.getState(), false, false);
			else
				m_feedList.removeEmptyTagRow();
			return false;
		});
		setArticleListState((ArticleListState)Settings.state().get_enum("show-articles"));

		m_pane.pack2(m_articleList, false, false);


		m_articleList.row_activated.connect((row) => {
			if(m_article_view.getCurrentArticle() != row.getID())
			{
				m_article_view.load(row.getID());
				m_headerbar.showArticleButtons(true);
				Logger.debug("ContentPage: set headerbar");
				m_headerbar.setRead(row.isUnread());
				m_headerbar.setMarked(row.isMarked());
				m_headerbar.showMediaButton(row.haveMedia());
				m_article_view.showMediaButton(row.haveMedia());
			}
		});

		m_article_view = new articleView();
		m_article_view.enterFullscreen.connect(enterFullscreen);
		m_article_view.leaveFullscreen.connect(leaveFullscreen);


		this.orientation = Gtk.Orientation.HORIZONTAL;
		this.set_position(Settings.state().get_int("feeds-and-articles-width"));
		this.pack1(m_pane, false, false);
		this.pack2(m_article_view, true, false);
		this.notify["position"].connect(() => {
			m_headerbar.set_position(this.get_position());
		});

		m_headerbar = new ColumnViewHeader();
		m_headerbar.refresh.connect(() => {
			syncStarted();
			var app = FeedReaderApp.get_default();
			app.sync.begin((obj, res) => {
				app.sync.end(res);
			});
		});

		m_headerbar.change_state.connect((state, transition) => {
			setArticleListState(state);
			clearArticleView();
			newArticleList(transition);
		});

		m_headerbar.search_term.connect((searchTerm) => {
			Logger.debug("MainWindow: new search term");
			setSearchTerm(searchTerm);
			clearArticleView();
			newArticleList();
		});

		m_headerbar.notify["position"].connect(() => {
        	this.set_position(m_headerbar.get_position());
        });

		m_headerbar.toggledMarked.connect(() => {
			toggleMarkedSelectedArticle();
		});

		m_headerbar.toggledRead.connect(() => {
			toggleReadSelectedArticle();
		});
	}

	public void enterFullscreen(bool video)
	{
		// fullscreen not requested by video -> go to fullscreen-article-mode
		if(!video)
		{
			m_article_view.setFullscreenArticle(true);
		}

		m_pane.set_visible(false);
	}

	public void leaveFullscreen(bool video)
	{
		if(!video)
		{
			m_article_view.setFullscreenArticle(false);
		}

		m_pane.set_visible(true);
	}

	public void ArticleListNEXT()
	{
		if(!m_article_view.fullscreenArticle())
			leaveFullscreen(true);
		else
			m_article_view.setTransition(Gtk.StackTransitionType.SLIDE_LEFT, 500);

		m_articleList.move(false);
	}

	public void ArticleListPREV()
	{
		if(!m_article_view.fullscreenArticle())
			leaveFullscreen(true);
		else
			m_article_view.setTransition(Gtk.StackTransitionType.SLIDE_RIGHT, 500);

		m_articleList.move(true);
	}

	public void newArticleList(Gtk.StackTransitionType transition = Gtk.StackTransitionType.CROSSFADE)
	{
		Logger.debug("ContentPage.newArticleList");
		int height = m_articleList.get_allocated_height();
		if(height == 1)
		{
			ulong id = 0;
			id = m_articleList.draw.connect_after(() => {
				m_articleList.newList.begin(transition, (obj, res) => {
					m_articleList.newList.end(res);
				});
				m_articleList.disconnect(id);
				return false;
			});
		}
		else
		{
			m_articleList.newList.begin(transition, (obj, res) => {
				m_articleList.newList.end(res);
			});
		}
	}

	public void newFeedList(bool defaultSettings = false)
	{
		m_feedList.newFeedlist(m_articleList.getState(), defaultSettings);
	}

	public void updateFeedList()
	{
		m_feedList.refreshCounters(m_articleList.getState());
	}

	public void reloadArticleView()
	{
		m_article_view.load();
	}

	public void updateArticleList()
	{
		m_articleList.updateArticleList.begin((obj,res) => {
			m_articleList.updateArticleList.end(res);
		});
	}

	private void setArticleListState(ArticleListState state)
	{
		var oldState = m_articleList.getState();
		m_articleList.setState(state);

		if(oldState == ArticleListState.MARKED
		|| state == ArticleListState.MARKED)
			m_feedList.refreshCounters(state);
	}

	private void setSearchTerm(string searchTerm)
	{
		m_articleList.setSearchTerm(searchTerm);
		m_article_view.setSearchTerm(searchTerm);
	}

	private void clearArticleView()
	{
		m_headerbar.showArticleButtons(false);
		m_article_view.clearContent();
	}

	public string getSelectedFeedListRow()
	{
		return m_feedList.getSelectedRow();
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
		m_headerbar.setRead(false);
		m_articleList.markAllAsRead();
	}

	public void toggleReadSelectedArticle()
	{
		m_headerbar.toggleRead();
		bool unread = m_articleList.toggleReadSelected();
		m_article_view.setUnread(unread);
	}

	public void toggleMarkedSelectedArticle()
	{
		m_headerbar.toggleMarked();
		bool marked = m_articleList.toggleMarkedSelected();
		m_article_view.setMarked(marked);
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
		var tags = new Gee.ArrayList<tag>();
		string id = m_articleList.getSelectedArticle();

		if(id != "" && id != "empty")
		{
			var article = dbUI.get_default().read_article(id);
			unowned Gee.ArrayList<string> tagIDs = article.getTags();

			foreach(string tagID in tagIDs)
			{
				tags.add(dbUI.get_default().read_tag(tagID));
			}
		}

		return tags;
	}

	public Gee.ArrayList<string> getSelectedArticleMedia()
	{
		string id = m_articleList.getSelectedArticle();
		var article = dbUI.get_default().read_article(id);
		return article.getMedia();
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
		m_headerbar.setOffline();
		m_feedList.setOffline();

		if(!UtilsUI.canManipulateContent(false))
		{
			m_footer.setActive(false);
			m_feedList.newFeedlist(m_articleList.getState(), false);
		}
	}

	public void setOnline()
	{
		m_headerbar.setOnline();
		m_feedList.setOnline();

		if(UtilsUI.canManipulateContent(true))
		{
			m_footer.setActive(true);
			m_feedList.newFeedlist(m_articleList.getState(), false);

			var selected_row = m_feedList.getSelectedRow();
			string[] selected = selected_row.split(" ");

			if((selected[0] == "feed" && selected[1] == FeedID.ALL.to_string())
			|| (selected[0] == "cat" && (selected[1] == CategoryID.MASTER.to_string() || selected[1] == CategoryID.TAGS.to_string())))
			{
				m_footer.setRemoveButtonSensitive(false);
			}
		}
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

	public bool isFullscreen()
	{
		return m_article_view.fullscreenArticle();
	}

	public bool isFullscreenVideo()
	{
		return m_article_view.fullscreenVideo();
	}

	public bool ArticleListSelectedIsFirst()
	{
		return m_articleList.selectedIsFirst();
	}

	public bool ArticleListSelectedIsLast()
	{
		return m_articleList.selectedIsLast();
	}

	public void ArticleViewAddMedia(MediaPlayer media)
	{
		m_article_view.addMedia(media);
	}

	public void articleViewKillMedia()
	{
		m_article_view.killMedia();
	}

	public void print()
	{
		m_article_view.print();
	}

	public bool playingMedia()
	{
		return m_article_view.playingMedia();
	}

	public string? displayedArticle()
	{
		return m_article_view.getCurrentArticle();
	}

	public void saveState(ref InterfaceState state)
	{
		int offset = 0;
		double scrollPos = 0.0;
		m_articleList.getSavedState(out scrollPos, out offset);

		state.setArticleListScrollPos(scrollPos);
		state.setArticleListRowOffset(offset);
		state.setFeedListSelectedRow(m_feedList.getSelectedRow());
		state.setExpandedCategories(m_feedList.getExpandedCategories());
		state.setFeedsAndArticleWidth(this.get_position());
		state.setFeedListWidth(m_pane.get_position());
		state.setFeedListScrollPos(m_feedList.vadjustment.value);
		state.setArticleViewScrollPos(m_article_view.getScrollPos());
		state.setArticleListSelectedRow(m_articleList.getSelectedArticle());

		m_headerbar.saveState(ref state);
	}

	public bool searchFocused()
	{
		return m_headerbar.searchFocused();
	}

	public ColumnViewHeader getHeader()
	{
		return m_headerbar;
	}
}
