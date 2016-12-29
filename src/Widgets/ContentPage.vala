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

public class FeedReader.ContentPage : Gtk.Overlay {

	private Gtk.Paned m_pane1;
	private Gtk.Paned m_pane2;
	private articleView m_article_view;
	private ArticleList m_articleList;
	private feedList m_feedList;
	private FeedListFooter m_footer;
	public signal void showArticleButtons(bool show);
	public signal void panedPosChange(int pos);


	public ContentPage()
	{
		Logger.debug("ContentPage: setup FeedList");

		m_feedList = new feedList();
		m_footer = new FeedListFooter();
		var feedListBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		feedListBox.pack_start(m_feedList);
		feedListBox.pack_end(m_footer, false, false);

		m_pane2 = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);
		m_pane2.set_size_request(0, 300);
		m_pane2.set_position(Settings.state().get_int("feed-row-width"));
		m_pane2.pack1(feedListBox, false, false);

		m_feedList.clearSelected.connect(() => {
			m_footer.setRemoveButtonSensitive(false);
		});

		m_feedList.newFeedSelected.connect((feedID) => {
			m_articleList.setSelectedType(FeedListType.FEED);
			m_article_view.clearContent();
			showArticleButtons(false);
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
			m_articleList.setSelectedType(FeedListType.TAG);
			m_article_view.clearContent();
			showArticleButtons(false);
			m_articleList.setSelectedFeed(tagID);
			newArticleList();
			m_footer.setRemoveButtonSensitive(true);
			m_footer.setSelectedRow(FeedListType.TAG, tagID);
		});

		m_feedList.newCategorieSelected.connect((categorieID) => {
			m_articleList.setSelectedType(FeedListType.CATEGORY);
			m_article_view.clearContent();
			showArticleButtons(false);
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
				m_feedList.newFeedlist(false, true);
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
				m_feedList.newFeedlist(false, false);
			else
				m_feedList.removeEmptyTagRow();
			return false;
		});
		setArticleListState((ArticleListState)Settings.state().get_enum("show-articles"));

		m_pane2.pack2(m_articleList, false, false);


		m_articleList.row_activated.connect((row) => {
			if(m_article_view.getCurrentArticle() != row.getID())
			{
				m_article_view.load(row.getID());
				showArticleButtons(true);
				var window = ((FeedApp)GLib.Application.get_default()).getWindow();
				if(window != null)
				{
					var header = window.getHeaderBar();
					Logger.debug("ContentPage: set headerbar");
					header.setRead(row.isUnread());
					header.setMarked(row.isMarked());
					header.showMediaButton(row.haveMedia());
				}
			}
		});

		m_article_view = new articleView();
		m_article_view.enterFullscreen.connect(enterFullscreen);
		m_article_view.leaveFullscreen.connect(leaveFullscreen);


		m_pane1 = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);
		m_pane1.set_position(Settings.state().get_int("feeds-and-articles-width"));
		m_pane1.pack1(m_pane2, false, false);
		m_pane1.pack2(m_article_view, true, false);
		m_pane1.notify["position"].connect(() => {
			panedPosChange(m_pane1.get_position());
		});
		this.add(m_pane1);
	}

	public void enterFullscreen(bool video)
	{
		// fullscreen not requested by video -> go to fullscreen-article-mode
		if(!video)
		{
			m_article_view.setFullscreenArticle(true);
		}

		m_pane2.set_visible(false);
	}

	public void leaveFullscreen(bool video)
	{
		if(!video)
		{
			m_article_view.setFullscreenArticle(false);
		}

		m_pane2.set_visible(true);
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
		m_feedList.newFeedlist(defaultSettings);
	}

	public void updateFeedList()
	{
		m_feedList.refreshCounters();
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

	public ArticleListState getArticleListState()
	{
		return m_articleList.getState();
	}

	public void setArticleListState(ArticleListState state)
	{
		var oldState = m_articleList.getState();
		m_articleList.setState(state);

		if(oldState == ArticleListState.MARKED
		|| state == ArticleListState.MARKED)
			m_feedList.refreshCounters();
	}

	public void setSearchTerm(string searchTerm)
	{
		m_articleList.setSearchTerm(searchTerm);
		m_article_view.setSearchTerm(searchTerm);
	}

	public void clearArticleView()
	{
		showArticleButtons(false);
		m_article_view.clearContent();
	}

	public string[] getExpandedCategories()
	{
		return m_feedList.getExpandedCategories();
	}

	public double getFeedListScrollPos()
	{
		return m_feedList.vadjustment.value;
	}

	public string getSelectedFeedListRow()
	{
		return m_feedList.getSelectedRow();
	}

	public int getFeedListWidth()
	{
		return m_pane2.get_position();
	}

	public void setFeedListWidth(int pos)
	{
		m_pane2.set_position(pos);
	}

	public int getArticlePlusFeedListWidth()
	{
		return m_pane1.get_position();
	}

	public void setArticlePlusFeedListWidth(int pos)
	{
		m_pane1.set_position(pos);
	}

	public void getArticleListSavedState(out double scrollPos, out int offset)
	{
		m_articleList.getSavedState(out scrollPos, out offset);
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
		bool unread = m_articleList.toggleReadSelected();
		m_article_view.setUnread(unread);
	}

	public void toggleMarkedSelectedArticle()
	{
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
		m_feedList.setOffline();

		if(!UtilsUI.canManipulateContent(false))
		{
			m_footer.setActive(false);
			m_feedList.newFeedlist(false);
		}
	}

	public void setOnline()
	{
		m_feedList.setOnline();

		if(UtilsUI.canManipulateContent(true))
		{
			m_footer.setActive(true);
			m_feedList.newFeedlist(false);

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

	public void setArticleListPosition(int pos)
	{
		m_pane1.set_position(pos);
	}

	public InAppNotification showNotification(string message, string buttonText = "undo")
	{
		var notification = new InAppNotification(message, buttonText);
		this.add_overlay(notification);
		this.show_all();
		return notification;
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

	public void print(string uri)
	{
		m_article_view.print(uri);
	}
}
