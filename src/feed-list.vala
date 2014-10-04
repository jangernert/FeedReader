/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * feed-list.vala
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

public class feedList : Gtk.Stack {

	private Gtk.ScrolledWindow m_scroll;
	private Gtk.ListBox m_list;
	private baseRow m_selected;
	private Gtk.Spinner m_spinner;
	public signal void newFeedSelected(int feedID);
	public signal void newCategorieSelected(int categorieID);

	public feedList () {
		m_selected = null;
		m_spinner = new Gtk.Spinner();
		m_list = new Gtk.ListBox();
		m_list.set_selection_mode(Gtk.SelectionMode.BROWSE);
		m_list.get_style_context().add_class("feed-list");

		m_scroll = new Gtk.ScrolledWindow(null, null);
		m_scroll.set_size_request(200, 500);
		m_scroll.add(m_list);
		this.get_style_context().add_class("feed-list");

		this.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		this.set_transition_duration(50);
		
		this.add_named(m_scroll, "list");
		this.add_named(m_spinner, "spinner");
		this.set_visible_child_name("list");


		m_list.row_activated.connect(() => {
			FeedRow selected_row = m_list.get_selected_row() as FeedRow;
			if(selected_row != null)
			{
				if(selected_row.m_name == "")
				{
					// don't select seperator
					m_list.select_row(m_selected);
					return;
				}
				if(selected_row != m_selected)
				{
					m_selected = selected_row;
					newFeedSelected(selected_row.m_ID);
				}
			}
			categorieRow selected_categorie = m_list.get_selected_row() as categorieRow;
			if(selected_categorie != null)
			{
				m_selected = selected_categorie;
				newCategorieSelected(selected_categorie.getID());
			}
		});


		m_list.key_press_event.connect((event) => {
			
			if(event.keyval == Gdk.Key.Down)
				move(true);
			else if(event.keyval == Gdk.Key.Up)
				move(false);
			else if(event.keyval == Gdk.Key.Left || event.keyval == Gdk.Key.Right)
			{
				categorieRow selected_categorie = m_list.get_selected_row() as categorieRow;
				if(selected_categorie != null)
					selected_categorie.expand_collapse();
			}
			
			return true;
		});
	}


	private void move(bool down)
	{
		FeedRow selected_feed = m_list.get_selected_row() as FeedRow;
		categorieRow selected_categorie = m_list.get_selected_row() as categorieRow;
		

		var FeedListChildren = m_list.get_children();

		if(!down){
			FeedListChildren.reverse();
		}


		int current = -1;
		if(selected_feed != null)
		{
			current = FeedListChildren.index(selected_feed);

		}
		else if(selected_categorie != null)
		{
			current = FeedListChildren.index(selected_categorie);
		}

		current++;
		while(current < FeedListChildren.length())
		{
			FeedRow current_feed = FeedListChildren.nth_data(current) as FeedRow;
			categorieRow current_categorie = FeedListChildren.nth_data(current) as categorieRow;

			if(current_feed != null)
			{
				if(current_feed.isRevealed() && current_feed.m_name != "")
				{
					m_list.select_row(current_feed);
					newFeedSelected(current_feed.m_ID);
					break;
				}
			}

			if(current_categorie != null)
			{
				if(current_categorie.isRevealed())
				{
					m_list.select_row(current_categorie);
					newCategorieSelected(current_categorie.getID());
					break;
				}
			}
			
			current++;
		}
	}


	public void createFeedlist()
	{
		var row_spacer = new FeedRow("", "", false, "", -1, 0);
		row_spacer.set_size_request(0, 8);
		m_list.add(row_spacer);
		
		var unread = dataBase.read_propertie("unread_articles");
		var row_all = new FeedRow("All Articles",unread.to_string(), false, "0", -1, 0);
		m_list.add(row_all);
		row_all.reveal(true);

		var row_seperator = new FeedRow("", "", false, "", -1, 0);
		var separator = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
		separator.set_size_request(0, 20);
		row_seperator.add(separator);
		m_list.add(row_seperator);

		//-------------------------------------------------------------------

		createCategories();

		var feeds = dataBase.read_feeds();
		foreach(var item in feeds)
		{
			var FeedChildList = m_list.get_children();
			int pos = 0;
			foreach(Gtk.Widget row in FeedChildList)
			{
				pos++;
				var tmpRow = row as categorieRow;

				if(tmpRow != null)
				{
					if(tmpRow.getID() == item.m_categorieID)
					{
						var feedrow = new FeedRow(
											       item.m_title,
											       item.m_unread.to_string(),
											       item.m_hasIcon,
											       item.m_feedID.to_string(),
							                       item.m_categorieID,
							                       tmpRow.getLevel()
											      );
						m_list.insert(feedrow, pos);
						feedrow.reveal(true);
						break;
					}
				}
			}
		}
		if(m_selected == null)
		{
			m_selected = row_all;
			m_list.select_row(row_all);
		}
		initCollapseCategories();
		this.show_all();
	}


	private void createCategories()
	{
		int maxCatLevel = dataBase.getMaxCatLevel();
		string[] exp = feedreader_settings.get_strv("expanded-categories");
		bool expand = false;

		for(int i = 1; i <= maxCatLevel; i++)
		{
			var categories = dataBase.read_categories_level(i);
			foreach(var item in categories)
			{
				var FeedChildList = m_list.get_children();
				int pos = 0;
				foreach(Gtk.Widget existing_row in FeedChildList)
				{
					pos++;
					var tmpRow = existing_row as categorieRow;
					if((tmpRow != null && tmpRow.getID() == item.m_parent) || (item.m_parent == -99 && pos > 2))
					{
						foreach(string str in exp)
						{
							if(item.m_title == str)
								expand = true;
						}
						var categorierow = new categorieRow(
					                                item.m_title,
					                                item.m_categorieID,
					                                item.m_orderID,
					                                item.m_unread_count.to_string(),
					                                item.m_parent,
							                        item.m_level,
							                        expand
					                                );
					    expand = false;
						categorierow.collapse.connect((collapse, catID) => {
							if(collapse)
								collapseCategorie(catID);
							else
								expandCategorie(catID);
						});
						m_list.insert(categorierow, pos);
						categorierow.reveal(true);
						break;
					}
				}
			}
		}
	}


	private void updateCategories()
	{

		var categories = dataBase.read_categories();
		bool found, inserted;
		var FeedChildList = m_list.get_children();
		
		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpRow = row as categorieRow;
			if(tmpRow != null)
			{
				tmpRow.setExist(false);
			}
		}
		
		foreach(var item in categories)
		{
			found = false;
			foreach(Gtk.Widget row in FeedChildList)
			{
				var tmpRow = row as categorieRow;
				if(tmpRow != null)
				{
					if(tmpRow.getID() == item.m_categorieID)
					{
						found = true;
						tmpRow.setExist(true);
						tmpRow.set_unread_count(item.m_unread_count.to_string());
						break;
					}
				}
			}
				
			if(!found)
			{
				var categorierow = new categorieRow(
					                                item.m_title,
					                                item.m_categorieID,
					                                item.m_orderID,
					                                item.m_unread_count.to_string(),
					                                item.m_parent,
							                        item.m_level,
							                        false
					                                );
					
				categorierow.collapse.connect((collapse, catID) => {
					if(collapse)
						collapseCategorie(catID);
					else
						expandCategorie(catID);
				});

				int pos = 0;
				inserted = false;
				foreach(Gtk.Widget row in FeedChildList)
				{
					var tmpRow = row as categorieRow;
					pos++;
					if(tmpRow != null && tmpRow.getID() == categorierow.getParent()+1)
					{
						m_list.insert(categorierow, pos-1);
						categorierow.reveal(true);
						inserted = true;
					}
				}
				if(!inserted)
				{
					m_list.add(categorierow);
					categorierow.reveal(true);
				}
					
			}
		}
		
		this.show_all();
	}


	public async void updateFeedList()
	{
		var unread = dataBase.read_propertie("unread_articles");
		bool found;
		var FeedChildList = m_list.get_children();
		updateCategories();

		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpRow = row as FeedRow;
			if(tmpRow != null)
			{
				tmpRow.setSubscribed(false);
			}
		}

		var feeds = dataBase.read_feeds();
		foreach(var item in feeds)
		{
			found = false;
			foreach(Gtk.Widget row in FeedChildList)
			{
				var tmpRow = row as FeedRow;
				if(tmpRow != null)
				{
					if(item.m_feedID == tmpRow.m_ID && item.m_categorieID == tmpRow.getCategorie())
					{
						tmpRow.setSubscribed(true);
						tmpRow.update(item.m_title, item.m_unread.to_string());
						found = true;
						break;
					}
					else if(item.m_feedID == tmpRow.m_ID && item.m_categorieID != tmpRow.getCategorie())
					{
						m_list.remove(tmpRow);
						break;
					}
				}
			}

			if(!found)
			{
				FeedChildList = m_list.get_children();
				int pos = 0;
				foreach(Gtk.Widget row in FeedChildList)
				{
					pos++;
					var tmpRow = row as categorieRow;

					if(tmpRow != null)
					{
						if(tmpRow.getID() == item.m_categorieID)
						{
							var feedrow = new FeedRow(
											           item.m_title,
											           item.m_unread.to_string(),
											           item.m_hasIcon,
											           item.m_feedID.to_string(),
							                           item.m_categorieID,
							                           tmpRow.getLevel()
											          );
							m_list.insert(feedrow, pos);
							feedrow.reveal(true);
							break;
						}
					}
				}	
			}
		}

		// update "All Articles" row
		// delete non subscribed rows
		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpRow = row as FeedRow;
			if(tmpRow != null)
			{
				if(tmpRow.m_name == "All Articles")
				{
					tmpRow.setSubscribed(true);
					tmpRow.update("All Articles", unread.to_string());
				}
				else if(tmpRow.m_name == "")
				{
					tmpRow.setSubscribed(true);
				}
				else if(!tmpRow.isSubscribed())
				{
					m_list.remove(tmpRow);
					tmpRow.destroy();
				}
			}
		}

		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpRow = row as categorieRow;
			if(tmpRow != null && !tmpRow.doesExist())
			{
				m_list.remove(tmpRow);
				tmpRow.destroy();
			}
		}

		initCollapseCategories();
		this.show_all();
	}

	private void initCollapseCategories()
	{
		var FeedChildList = m_list.get_children();

		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpCatRow = row as categorieRow;
			if(tmpCatRow != null && !tmpCatRow.isExpanded())
			{
				collapseCategorie(tmpCatRow.getID());
			}
		}
	}

	private void collapseCategorie(int catID)
	{
		var FeedChildList = m_list.get_children();

		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpFeedRow = row as FeedRow;
			var tmpCatRow = row as categorieRow;
			if(tmpFeedRow != null && tmpFeedRow.getCategorie() == catID)
			{
				tmpFeedRow.reveal(false);
			}
			if(tmpCatRow != null && tmpCatRow.getParent() == catID)
			{
				tmpCatRow.reveal(false);
				collapseCategorie(tmpCatRow.getID());
			}
		}
	}


	private void expandCategorie(int catID)
	{
		var FeedChildList = m_list.get_children();

		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpFeedRow = row as FeedRow;
			var tmpCatRow = row as categorieRow;
			if(tmpFeedRow != null && tmpFeedRow.getCategorie() == catID)
			{
				tmpFeedRow.reveal(true);
			}
			if(tmpCatRow != null && tmpCatRow.getParent() == catID)
			{
				tmpCatRow.reveal(true);
				if(tmpCatRow.isExpanded())
					expandCategorie(tmpCatRow.getID());
			}
		}
	}



	public int getSelectedFeed()
	{
		FeedRow selected_row = (FeedRow)m_list.get_selected_row();
		return selected_row.m_ID;
	}
	
	public string[] getExpandedCategories()
	{
		var FeedChildList = m_list.get_children();
		string[] e = {};
		
		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpCatRow = row as categorieRow;
			if(tmpCatRow != null)
			{
				if(tmpCatRow.isExpanded())
				{
					e += tmpCatRow.getName();
					stdout.printf("%s\n", tmpCatRow.getName());
				}
			}
		}
		return e;
	}

}

