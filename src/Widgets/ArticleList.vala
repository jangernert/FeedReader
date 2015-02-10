public class articleList : Gtk.Stack {

	private Gtk.ScrolledWindow m_currentScroll;
	private Gtk.ScrolledWindow m_scroll1;
	private Gtk.ScrolledWindow m_scroll2;
	private Gtk.ListBox m_currentList;
	private Gtk.ListBox m_List1;
	private Gtk.ListBox m_List2;
	private Gtk.Adjustment m_current_adjustment;
	private Gtk.Adjustment m_scroll1_adjustment;
	private Gtk.Adjustment m_scroll2_adjustment;
	private double m_lmit;
	private int m_displayed_articles;
	private string m_current_feed_selected;
	private bool m_only_unread;
	private bool m_only_marked;
	private string m_searchTerm;
	private int m_limit;
	private int m_IDtype;
	private bool m_limitScroll;
	public signal void row_activated(articleRow? row);
	public signal void updateFeedList();
	

	public articleList () {
		m_lmit = 0.8;
		m_displayed_articles = 0;
		m_current_feed_selected = FEEDID_ALL_FEEDS;
		m_IDtype = FEEDLIST_FEED;
		m_searchTerm = "";
		m_limit = 15;
		m_limitScroll = false;
		
		
		m_List1 = new Gtk.ListBox();
		m_List1.set_selection_mode(Gtk.SelectionMode.BROWSE);
		m_List1.get_style_context().add_class("article-list");
		m_List2 = new Gtk.ListBox();
		m_List2.set_selection_mode(Gtk.SelectionMode.BROWSE);
		m_List2.get_style_context().add_class("article-list");
		
		
		m_scroll1 = new Gtk.ScrolledWindow(null, null);
		m_scroll1.set_size_request(400, 500);
		m_scroll1.add(m_List1);
		m_scroll2 = new Gtk.ScrolledWindow(null, null);
		m_scroll2.set_size_request(400, 500);
		m_scroll2.add(m_List2);
		

		m_scroll1_adjustment = m_scroll1.get_vadjustment();
		m_scroll1_adjustment.value_changed.connect(() => {
			var current = m_scroll1_adjustment.get_value();
			var page = m_scroll1_adjustment.get_page_size();
			var max = m_scroll1_adjustment.get_upper();
			if((current + page)/max > m_lmit && !m_limitScroll)
			{
				createHeadlineList(true);
			}
		});
		
		m_scroll2_adjustment = m_scroll2.get_vadjustment();
		m_scroll2_adjustment.value_changed.connect(() => {
			var current = m_scroll2_adjustment.get_value();
			var page = m_scroll2_adjustment.get_page_size();
			var max = m_scroll2_adjustment.get_upper();
			if((current + page)/max > m_lmit && !m_limitScroll)
			{
				createHeadlineList(true);
			}
		});
		

		m_List1.row_activated.connect((row) => {
			row_activated((articleRow)row);
		});
		m_List2.row_activated.connect((row) => {
			row_activated((articleRow)row);
		});

		m_List1.key_press_event.connect((event) => {
			key_pressed(event);
			return true;
		});
		
		m_List2.key_press_event.connect((event) => {
			key_pressed(event);
			return true;
		});
		
		m_currentList = m_List1;
		m_currentScroll = m_scroll1;
		m_current_adjustment = m_scroll1_adjustment;

		this.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		this.set_transition_duration(100);
		this.add_named(m_scroll1, "list1");
		this.add_named(m_scroll2, "list2");
	}
	
	private void key_pressed(Gdk.EventKey event)
	{
		if(event.keyval == Gdk.Key.Down)
			move(true);
		else if(event.keyval == Gdk.Key.Up)
			move(false);
	}


	private void move(bool down)
	{
		articleRow selected_row = m_currentList.get_selected_row() as articleRow;
		

		var ArticleListChildren = m_currentList.get_children();

		if(!down){
			ArticleListChildren.reverse();
		}

		int current = ArticleListChildren.index(selected_row);

		current++;
		if(current < ArticleListChildren.length())
		{
			articleRow current_article = ArticleListChildren.nth_data(current) as articleRow;
			m_currentList.select_row(current_article);
			row_activated(current_article);
			
			var currentPos = m_current_adjustment.get_value();
			var max = m_current_adjustment.get_upper();
			var offset = (max)/ArticleListChildren.length();
			
			if(down)
			{
				m_current_adjustment.set_value(currentPos + offset);
			}
			else
			{
				m_current_adjustment.set_value(currentPos - offset);
			}
			
			m_currentScroll.set_vadjustment(m_current_adjustment);
			current_article.activate();
		}
	}
	
	
	public int getAmountOfRowsToLoad()
	{
		return (int)m_currentList.get_children().length();
	}
	
	
	private void restoreSelectedRow()
	{
		string selectedRow = settings_state.get_string("articlelist-selected-row");
		
		if(selectedRow != "")
		{
			var FeedChildList = m_currentList.get_children();	
			foreach(Gtk.Widget row in FeedChildList)
			{
				var tmpRow = row as articleRow;
				if(tmpRow != null && tmpRow.getID() == selectedRow)
				{
					m_currentList.select_row(tmpRow);
					tmpRow.activate();
					settings_state.set_string("articlelist-selected-row", "");
					return;
				}
			}
		}
	}
	

	void restoreScrollPos(Object sender, ParamSpec property)
	{
		print("restoreScrollPos\n");
		m_current_adjustment.notify["upper"].disconnect(restoreScrollPos);
		setScrollPos(settings_state.get_double("articlelist-scrollpos"));
		
		settings_state.set_int("articlelist-new-rows", 0);
		settings_state.set_int("articlelist-row-amount", 15);
		settings_state.set_double("articlelist-scrollpos",  0);
	}
		
	
	private void setScrollPos(double pos)
	{
		print("max scroll: " + m_current_adjustment.get_upper().to_string() + "\n");
		
		double RowVSpace = 102;
		double additionalScroll = RowVSpace * settings_state.get_int("articlelist-new-rows");
		double newPos = pos + additionalScroll;
		
		m_current_adjustment = m_currentScroll.get_vadjustment();
		m_current_adjustment.set_value(newPos);
		m_currentScroll.set_vadjustment(m_current_adjustment);
	}
	
	
	public double getScrollPos()
	{
		return m_current_adjustment.get_value();
	}
	
	private int shortenArticleList()
	{
		double RowVSpace = 102;
		int stillInViewport = (int)((settings_state.get_double("articlelist-scrollpos")+900)/RowVSpace);
		//settings_state.get_int("articlelist-new-rows")
		if(stillInViewport < settings_state.get_int("articlelist-row-amount"))
		{
			return stillInViewport+15;
		}
		
		return settings_state.get_int("articlelist-row-amount");
	}


	public void setOnlyUnread(bool only_unread)
	{
		m_only_unread = only_unread;
	}

	public void setOnlyMarked(bool only_marked)
	{
		m_only_marked = only_marked;
	}
	
	public void setSearchTerm(string searchTerm)
	{
		m_searchTerm = searchTerm;
	}

	public void setSelectedFeed(string feedID)
	{
		m_current_feed_selected = feedID;
	}
	
	public void setSelectedType(int type)
	{
		m_IDtype = type;
	}
	
	public string getSelectedArticle()
	{
		articleRow selected_row = m_currentList.get_selected_row() as articleRow;
		if(selected_row != null)
			return selected_row.getID();
		
		return "";
	}


	public void createHeadlineList(bool add = false)
	{
		// dont allow new articles being created due to scrolling for 0.5s
		limitScroll.begin((obj, res) => {
			limitScroll.end(res);
		});
		
		m_limit = shortenArticleList() + settings_state.get_int("articlelist-new-rows");
		var articles = dataBase.read_articles(m_current_feed_selected, m_IDtype, m_only_unread, m_only_marked, m_searchTerm, m_limit, m_displayed_articles);

		foreach(var item in articles)
		{
			m_displayed_articles++;
			
			articleRow tmpRow = new articleRow(
					                             item.m_title,
					                             item.m_unread,
					                             item.m_feedID.to_string(),
					                             item.m_url,
					                             item.m_feedID,
					                             item.m_articleID,
					                             item.m_marked,
					                             item.m_sortID
					                            );
			tmpRow.updateFeedList.connect(() => {updateFeedList();});
			m_currentList.add(tmpRow);
			tmpRow.reveal(true);
			
		}
		m_currentList.show_all();
		if(m_currentList == m_List1)		 this.set_visible_child_name("list1");
		else if(m_currentList == m_List2)   this.set_visible_child_name("list2");
		
		if(!add)
		{
			m_current_adjustment.notify["upper"].connect(restoreScrollPos);
			restoreSelectedRow();
		}
		
		if(settings_state.get_boolean("no-animations"))
			settings_state.set_boolean("no-animations", false);
	}

	public void newHeadlineList()
	{
		if(m_currentList == m_List1)
		{
			m_currentList = m_List2;
			m_currentScroll = m_scroll2;
			m_current_adjustment = m_scroll2_adjustment;
		}
		else
		{
			m_currentList = m_List1;
			m_currentScroll = m_scroll1;
			m_current_adjustment = m_scroll1_adjustment;
		}
		
		m_displayed_articles = 0;
		var articleChildList = m_currentList.get_children();
		foreach(Gtk.Widget row in articleChildList)
		{
			m_currentList.remove(row);
			row.destroy();
		}

		createHeadlineList();
	}

	public void updateArticleList()
	{
		var articleChildList = m_currentList.get_children();
		if(articleChildList != null)
		{
			var first_row = articleChildList.first().data as articleRow;
			int new_articles = dataBase.getRowNumberHeadline(first_row.getID()) -1;
			m_limit = m_displayed_articles + new_articles;
		}

		var articles = dataBase.read_articles(m_current_feed_selected, m_IDtype, m_only_unread, m_only_marked, m_searchTerm, m_limit);
		
		bool found;

		foreach(var item in articles)
		{
			found = false;
			
			foreach(Gtk.Widget row in articleChildList)
			{
				var tmpRow = (articleRow)row;
				if(item.m_articleID == tmpRow.getID())
				{
					tmpRow.updateUnread(item.m_unread);
					found = true;
					break;
				}
			}

			if(!found)
			{
				articleRow newRow = new articleRow(
					                             item.m_title,
					                             item.m_unread,
					                             item.m_feedID.to_string(),
					                             item.m_url,
					                             item.m_feedID,
					                             item.m_articleID,
					                             item.m_marked,
					                             item.m_sortID
					                            );
				newRow.updateFeedList.connect(() => {updateFeedList();});
				int pos = 0;
				bool added = false;
				if(articleChildList == null)
				{
					m_currentList.insert(newRow, 0);
					added = true;
				}
				foreach(Gtk.Widget row in articleChildList)
				{
					pos++;
					var tmpRow = row as articleRow;
					if(tmpRow != null && newRow.m_sortID > tmpRow.m_sortID)
					{
						m_currentList.insert(newRow, pos-1);
						m_displayed_articles++;
						added = true;
						break;
					}
				}
				
				if(!added)
				{
					m_currentList.add(newRow);
					m_displayed_articles++;
				}
				newRow.reveal(true);
				articleChildList = m_currentList.get_children();
			}
		}
	}
	
	
	private async void limitScroll()
	{
		SourceFunc callback = limitScroll.callback;
		
		ThreadFunc<void*> run = () => {
			m_limitScroll = true;
			GLib.Thread.usleep(500000);
			m_limitScroll = false;
			Idle.add((owned) callback);
			return null;
		};
		new GLib.Thread<void*>("limitScroll", run);
		yield;
	}

	 
}
