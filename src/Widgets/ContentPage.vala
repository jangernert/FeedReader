public class FeedReader.ContentPage : Gtk.Paned {

	private Gtk.Paned m_pane;
	private articleView m_article_view;
	private articleList m_articleList;
	private feedList m_feedList;
	public signal void setMarkReadButtonActive(bool active);


	public ContentPage()
	{
		logger.print(LogMessage.DEBUG, "ContentPage: setup FeedList");
		this.orientation = Gtk.Orientation.HORIZONTAL;

		this.set_position(settings_state.get_int("feeds-and-articles-width"));


		m_feedList = new feedList();

		m_pane = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);
		m_pane.set_size_request(500, 500);
		m_pane.set_position(settings_state.get_int("feed-row-width"));

		m_pane.pack1(m_feedList, false, false);

		m_feedList.newFeedSelected.connect((feedID) => {

			if(feedID == FeedID.ALL
			&& dataBase.get_unread_total() > 0)
				setMarkReadButtonActive(true);
			else if(dataBase.get_unread_feed(feedID) == 0)
				setMarkReadButtonActive(false);
			else
				setMarkReadButtonActive(true);

			m_articleList.setSelectedType(FeedList.FEED);
			m_article_view.clearContent();
			m_articleList.setSelectedFeed(feedID);
			m_articleList.newHeadlineList();
		});

		m_feedList.newTagSelected.connect((tagID) => {
			setMarkReadButtonActive(false);
			m_articleList.setSelectedType(FeedList.TAG);
			m_article_view.clearContent();
			m_articleList.setSelectedFeed(tagID);
			m_articleList.newHeadlineList();
		});

		m_feedList.newCategorieSelected.connect((categorieID) => {
			if(categorieID == CategoryID.MASTER
			|| categorieID == CategoryID.TAGS
			|| dataBase.get_unread_category(categorieID) == 0)
				setMarkReadButtonActive(false);
			else
				setMarkReadButtonActive(true);

			m_articleList.setSelectedType(FeedList.CATEGORY);
			m_article_view.clearContent();
			m_articleList.setSelectedFeed(categorieID);
			m_articleList.newHeadlineList();
		});


		m_articleList = new articleList();
		m_articleList.setOnlyUnread(settings_state.get_boolean("only-unread"));
		m_articleList.setOnlyMarked(settings_state.get_boolean("only-marked"));
		m_pane.pack2(m_articleList, false, false);


		m_articleList.row_activated.connect((row) => {
			if(row.isUnread()){
				feedDaemon_interface.changeUnread(row.getID(), ArticleStatus.READ);
				row.updateUnread(ArticleStatus.READ);
				row.removeUnreadIcon();
			}

			if(m_article_view.getCurrentArticle() != row.getID())
				m_article_view.fillContent(row.getID());
		});

		m_article_view = new articleView();


		this.pack1(m_pane, false, false);
		this.pack2(m_article_view, true, false);
	}

	public void ArticleListNEXT()
	{
		m_articleList.move(false);
	}

	public void ArticleListPREV()
	{
		m_articleList.move(true);
	}

	public void newHeadlineList()
	{
		m_articleList.newHeadlineList();
	}

	public void newFeedList(bool defaultSettings = false)
	{
		m_feedList.newFeedlist(defaultSettings);
	}

	public void reloadArticleView()
	{
		m_article_view.reload();
	}

	public void updateFeedListCountUnread(string feedID, bool increase)
	{
		m_feedList.updateCounters(feedID, increase);
	}

	public void updateArticleList()
	{
		m_articleList.updateArticleList();
	}

	public void setOnlyUnread(bool only_unread)
	{
		m_articleList.setOnlyUnread(only_unread);
	}

	public void setOnlyMarked(bool only_marked)
	{
		m_articleList.setOnlyMarked(only_marked);
	}

	public void setSearchTerm(string searchTerm)
	{
		m_articleList.setSearchTerm(searchTerm);
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

	public int getArticlesToLoad()
	{
		return m_articleList.getAmountOfRowsToLoad();
	}

	public double getArticleListScrollPos()
	{
		return m_articleList.getScrollPos();
	}

	public int getArticleViewScrollPos()
	{
		return m_article_view.getScrollPos();
	}

	public string getSelectedArticle()
	{
		return m_articleList.getSelectedArticle();
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

}
