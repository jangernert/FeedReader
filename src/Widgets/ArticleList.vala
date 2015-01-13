/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * article-list.vala
 * Copyright (C) 2014 JeanLuc <jeanluc@jeanluc-desktop>
 *
 * tt-rss is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * tt-rss is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public class articleList : Gtk.Stack {

	private Gtk.ScrolledWindow m_currentScroll;
	private Gtk.ScrolledWindow m_scroll1;
	private Gtk.ScrolledWindow m_scroll2;
	private Gtk.ListBox m_currentList;
	private Gtk.ListBox m_List1;
	private Gtk.ListBox m_List2;
	private Gtk.Adjustment m_scroll1_adjustment;
	private Gtk.Adjustment m_scroll2_adjustment;
	private double m_lmit;
	private int m_displayed_articles;
	private string m_current_feed_selected;
	private bool m_only_unread;
	private bool m_only_marked;
	private string m_searchTerm;
	private int m_limit;
	public bool id_is_feedID;
	public signal void row_activated(articleRow? row);
	public signal void load_more();
	public signal void updateFeedList();
	

	public articleList () {
		m_lmit = 0.8;
		m_displayed_articles = 0;
		m_current_feed_selected = "-3";
		id_is_feedID = true;
		m_searchTerm = "";
		m_limit = 15;
		
		
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

		m_currentList = m_List1;
		m_currentScroll = m_scroll1;

		m_scroll1_adjustment = m_scroll1.get_vadjustment();
		m_scroll1_adjustment.value_changed.connect(() => {
			var current = m_scroll1_adjustment.get_value();
			var page = m_scroll1_adjustment.get_page_size();
			var max = m_scroll1_adjustment.get_upper();
			if((current + page)/max > m_lmit)
			{
				load_more();
			}
		});
		
		m_scroll2_adjustment = m_scroll2.get_vadjustment();
		m_scroll2_adjustment.value_changed.connect(() => {
			var current = m_scroll2_adjustment.get_value();
			var page = m_scroll2_adjustment.get_page_size();
			var max = m_scroll2_adjustment.get_upper();
			if((current + page)/max > m_lmit)
			{
				load_more();
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
		}
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


	public void createHeadlineList()
	{
		m_limit = 15;
		
		
		// when the daemon is updating in the background and writing new articles in the db
		// the most recent article could incomplete, so just add an offset of 1
		// the missing article will get added as soon as the update finishes anyway
		int active_in_db = feedreader_settings.get_boolean("currently-updating") ? 1 : 0;
		
		var articles = dataBase.read_articles(m_current_feed_selected, id_is_feedID, m_only_unread, m_only_marked, m_searchTerm, m_limit, m_displayed_articles + active_in_db);

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
					                             item.m_marked
					                            );
			tmpRow.updateFeedList.connect(() => {updateFeedList();});
			m_currentList.add(tmpRow);
			tmpRow.reveal(true);
		}
		m_currentList.show_all();
		if(m_currentList == m_List1)		 this.set_visible_child_name("list1");
		else if(m_currentList == m_List2)   this.set_visible_child_name("list2");
	}

	public void newHeadlineList()
	{
		if(m_currentList == m_List1)	m_currentList = m_List2;
		else							m_currentList = m_List1;
		
		m_displayed_articles = 0;
		var articleChildList = m_currentList.get_children();
		foreach(Gtk.Widget row in articleChildList)
		{
			m_currentList.remove(row);
			row.destroy();
		}

		createHeadlineList();
	}


	public void updateHeadlineList()
	{
		var articleChildList = m_currentList.get_children();
		if(articleChildList != null)
		{
			var first_row = articleChildList.first().data as articleRow;
			int new_articles = dataBase.getRowNumberHeadline(first_row.m_articleID) -1;
			m_limit = m_displayed_articles + new_articles;
		}

		var articles = dataBase.read_articles(m_current_feed_selected, id_is_feedID, m_only_unread, m_only_marked, m_searchTerm, m_limit);
		
		bool found;

		foreach(var item in articles)
		{
			found = false;
			
			foreach(Gtk.Widget row in articleChildList)
			{
				var tmpRow = (articleRow)row;
				if(item.m_articleID == tmpRow.m_articleID)
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
					                             item.m_marked
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
					if(tmpRow != null && newRow.m_articleID > tmpRow.m_articleID)
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

	 
}
