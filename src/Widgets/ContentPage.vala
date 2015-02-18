public class FeedReader.ContentPage : Gtk.Paned {
	
	private Gtk.Paned m_pane_articlelist;
	private articleView m_article_view;
	private articleList m_articleList;
	private feedList m_feedList;

	
	public ContentPage()
	{
		setupArticlelist();
		setupFeedlist();
	}
	
	private void setupFeedlist()
	{
		logger.print(LogMessage.DEBUG, "ContentPage: setup FeedList");
		int feed_row_width = settings_state.get_int("feed-row-width");
		this.orientation = Gtk.Orientation.HORIZONTAL;
		this.set_position(feed_row_width);
		m_feedList = new feedList();
		this.pack1(m_feedList, false, false);
		this.pack2(m_pane_articlelist, true, false);

		m_feedList.newFeedSelected.connect((feedID) => {
			m_articleList.setSelectedType(FeedList.FEED);
			m_article_view.clearContent();
			m_articleList.setSelectedFeed(feedID);
			m_articleList.newHeadlineList();
		});
		
		m_feedList.newTagSelected.connect((tagID) => {
			m_articleList.setSelectedType(FeedList.TAG);
			m_article_view.clearContent();
			m_articleList.setSelectedFeed(tagID);
			m_articleList.newHeadlineList();
		});

		m_feedList.newCategorieSelected.connect((categorieID) => {
			m_articleList.setSelectedType(FeedList.CATEGORY);
			m_article_view.clearContent();
			m_articleList.setSelectedFeed(categorieID);
			m_articleList.newHeadlineList();
		});
	}

	private void setupArticlelist()
	{
		try {
    		Gtk.CssProvider provider = new Gtk.CssProvider ();
    		provider.load_from_file(GLib.File.new_for_path("/usr/share/FeedReader/FeedReader.css"));
                

			weak Gdk.Display display = Gdk.Display.get_default ();
            weak Gdk.Screen screen = display.get_default_screen ();
			Gtk.StyleContext.add_provider_for_screen (screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		} catch (Error e) {
			logger.print(LogMessage.WARNING, e.message);
		}

		
		int article_row_width = settings_state.get_int("article-row-width");
		m_pane_articlelist = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);
		m_pane_articlelist.set_size_request(500, 500);
		m_pane_articlelist.set_position(article_row_width);
		
		m_articleList = new articleList();
		m_article_view = new articleView();
		m_pane_articlelist.pack1(m_articleList, false, false);
		m_pane_articlelist.pack2(m_article_view, true, false);
		
		m_articleList.setOnlyUnread(settings_state.get_boolean("only-unread"));
		m_articleList.setOnlyMarked(settings_state.get_boolean("only-marked"));
		

		m_articleList.row_activated.connect((row) => {
			if(row.isUnread()){
				feedDaemon_interface.changeUnread(row.getID(), ArticleStatus.READ);
				row.updateUnread(ArticleStatus.READ);
				row.removeUnreadIcon();
			}
			
			m_article_view.fillContent(row.getID());
		});

		m_articleList.updateFeedList.connect(() =>{
			updateFeedList();
		});
	}
	
	public void newHeadlineList()
	{
		m_articleList.newHeadlineList();
	}
	
	public void newFeedList()
	{
		m_feedList.newFeedlist();
	}
	
	public void updateFeedList()
	{
		m_feedList.updateFeedList();
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
		return this.get_position();
	}
	
	public int getArticleListWidth()
	{
		return m_pane_articlelist.get_position();
	}
	
	public int getArticlesToLoad()
	{
		return m_articleList.getAmountOfRowsToLoad();
	}
	
	public double getArticleListScrollPos()
	{
		return m_articleList.getScrollPos();
	}
	
	public string getSelectedArticle()
	{
		return m_articleList.getSelectedArticle();
	}

}
