public class feedList : Gtk.Stack {

	private Gtk.ScrolledWindow m_scroll;
	private Gtk.ListBox m_list;
	private baseRow m_selected;
	private Gtk.Spinner m_spinner;
	private Gtk.Adjustment m_scroll_adjustment;
	public signal void newFeedSelected(string feedID);
	public signal void newTagSelected(string tagID);
	public signal void newCategorieSelected(string categorieID);

	public feedList () {
		m_selected = null;
		m_spinner = new Gtk.Spinner();
		m_list = new Gtk.ListBox();
		m_list.set_selection_mode(Gtk.SelectionMode.BROWSE);
		m_list.get_style_context().add_class("feed-list");

		m_scroll = new Gtk.ScrolledWindow(null, null);
		m_scroll.set_size_request(200, 500);
		m_scroll.add(m_list);
		m_scroll_adjustment = m_scroll.get_vadjustment();

		
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
				if(selected_row.getName() == "")
				{
					// don't select seperator
					m_list.select_row(m_selected);
					return;
				}
				if(selected_row != m_selected)
				{
					m_selected = selected_row;
					newFeedSelected(selected_row.getID());
				}
			}
			categorieRow selected_categorie = m_list.get_selected_row() as categorieRow;
			if(selected_categorie != null)
			{
				m_selected = selected_categorie;
				newCategorieSelected(selected_categorie.getID());
			}
			TagRow selected_tag = m_list.get_selected_row() as TagRow;
			if(selected_tag != null)
			{
				m_selected = selected_tag;
				newTagSelected(selected_tag.getID());
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
				if(current_feed.isRevealed() && current_feed.getName() != "")
				{
					m_list.select_row(current_feed);
					newFeedSelected(current_feed.getID());
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
	
	
	public void newFeedlist()
	{
		var FeedChildList = m_list.get_children();
		foreach(Gtk.Widget row in FeedChildList)
		{
			m_list.remove(row);
			row.destroy();
		}
		createFeedlist();
	}


	public void createFeedlist()
	{
		var row_spacer = new FeedRow("", "", false, "", "-1", 0);
		row_spacer.set_size_request(0, 8);
		row_spacer.sensitive = false;
		m_list.add(row_spacer);
		
		var unread = dataBase.get_unread_total();
		var row_all = new FeedRow("All Articles", unread.to_string(), false, FEEDID_ALL_FEEDS.to_string(), "-1", 0);
		m_list.add(row_all);
		row_all.reveal(true);

		var row_seperator = new FeedRow("", "", false, "", "-1", 0);
		var separator = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
		separator.set_size_request(0, 20);
		row_seperator.add(separator);
		row_seperator.sensitive = false;
		m_list.add(row_seperator);

		//-------------------------------------------------------------------

		createCategories();
		createTags();

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
		
		initCollapseCategories();
		restoreSelectedRow();
		this.show_all();
		m_scroll_adjustment.notify["upper"].connect(restoreScrollPos);
	}
	
	private void restoreSelectedRow()
	{
		string[] selectedRow = settings_state.get_string("feedlist-selected-row").split(" ", 2);
		
		var FeedChildList = m_list.get_children();
		
		if(selectedRow[0] == "feed")
		{
			foreach(Gtk.Widget row in FeedChildList)
			{
				var tmpRow = row as FeedRow;
				if(tmpRow != null && tmpRow.getID() == selectedRow[1])
				{
					m_list.select_row(tmpRow);
					tmpRow.activate();
					return;
				}
			}
		}
		
		if(selectedRow[0] == "cat")
		{
			foreach(Gtk.Widget row in FeedChildList)
			{
				var tmpRow = row as categorieRow;
				if(tmpRow != null && tmpRow.getID() == selectedRow[1])
				{
					m_list.select_row(tmpRow);
					tmpRow.activate();
					return;
				}
			}
		}
		
		if(selectedRow[0] == "tag")
		{
			foreach(Gtk.Widget row in FeedChildList)
			{
				var tmpRow = row as TagRow;
				if(tmpRow != null && tmpRow.getID() == selectedRow[1])
				{
					m_list.select_row(tmpRow);
					tmpRow.activate();
					return;
				}
			}
		}
	}
	

	void restoreScrollPos(Object sender, ParamSpec property)
	{
		m_scroll_adjustment.notify["upper"].disconnect(restoreScrollPos);
		setScrollPos(settings_state.get_double("feed-row-scrollpos"));
	}
		
	
	private void setScrollPos(double pos)
	{
		m_scroll_adjustment = m_scroll.get_vadjustment();
		m_scroll_adjustment.set_value(pos);
		m_scroll.set_vadjustment(m_scroll_adjustment);
		this.show_all();
	}


	private void createCategories()
	{
		int maxCatLevel = dataBase.getMaxCatLevel();
		int account_type = settings_general.get_enum("account-type");
		string[] exp = settings_state.get_strv("expanded-categories");
		bool expand = false;
		
		if(account_type != TYPE_OWNCLOUD)
		{
			foreach(string str in exp)
			{
				if("Categories" == str)
					expand = true;
			}
			var categorierow = new categorieRow(
					                                "Categories",
					                                CAT_ID_MASTER,
					                                0,
					                                "",
					                                CAT_ID_NONE,
							                        1,
							                        expand
					                                );
			categorierow.collapse.connect((collapse, catID) => {
				if(collapse)
					collapseCategorie(catID);
				else
					expandCategorie(catID);
			});
			m_list.insert(categorierow, 3);
			categorierow.reveal(true);
			expand = false;
			string name = "Tags";
			if(account_type == TYPE_TTRSS)
				name = "Labels";
			
			foreach(string str in exp)
			{
				if(str == name)
					expand = true;
			}
			var tagrow = new categorieRow(
					                                name,
					                                CAT_TAGS,
					                                0,
					                                "",
					                                CAT_ID_NONE,
							                        1,
							                        expand
					                                );
			tagrow.collapse.connect((collapse, catID) => {
				if(collapse)
					collapseCategorie(catID);
				else
					expandCategorie(catID);
			});
			m_list.insert(tagrow, 4);
			tagrow.reveal(true);
			expand = false;
		}

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
					if((tmpRow != null && tmpRow.getID() == item.m_parent) ||
						(item.m_parent == CAT_ID_NONE && pos > 2) && (account_type == TYPE_OWNCLOUD) ||
						(item.m_parent == CAT_ID_NONE && pos > 3) && (account_type != TYPE_OWNCLOUD))
					{
						foreach(string str in exp)
						{
							if(item.m_title == str)
								expand = true;
						}
						
						int level = item.m_level;
						string parent = item.m_parent;
						if(account_type != TYPE_OWNCLOUD)
						{
							level++;
							parent = CAT_ID_MASTER;
						}
						
						var categorierow = new categorieRow(
					                                item.m_title,
					                                item.m_categorieID,
					                                item.m_orderID,
					                                item.m_unread_count.to_string(),
					                                parent,
							                        level,
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
	
	
	private void createTags()
	{
		var FeedChildList = m_list.get_children();
		int pos = 0;
		var tags = dataBase.read_tags();
		foreach(var Tag in tags)
		{
			pos = 0;
			foreach(Gtk.Widget row in FeedChildList)
			{
				pos++;
				var tmpRow = row as categorieRow;

				if(tmpRow != null)
				{
					if(tmpRow.getID() == CAT_TAGS)
					{
						var tagrow = new TagRow (Tag.m_title, Tag.m_tagID, Tag.m_color);
						m_list.insert(tagrow, pos);
						tagrow.reveal(true);
						break;
					}
				}
			}
		}
	}
	
	private void updateTags()
	{
		var FeedChildList = m_list.get_children();
		bool found = false;
		int pos = 0;
		var tags = dataBase.read_tags();
		
		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpRow = row as TagRow;
			if(tmpRow != null)
				tmpRow.setExits(false);
		}
		
		foreach(var Tag in tags)
		{
			found = false;
			foreach(Gtk.Widget row in FeedChildList)
			{
				var tmpRow = row as TagRow;
				if(tmpRow != null)
				{
					if(tmpRow.getID() == Tag.m_tagID)
					{
						tmpRow.update(Tag.m_title);
						tmpRow.setExits(true);
						found = true;
						break;
					}
				}
			}
			
			if(!found)
			{
				pos = 0;
				FeedChildList = m_list.get_children();
				foreach(Gtk.Widget row in FeedChildList)
				{
					pos++;
					var tmpRow = row as categorieRow;
					if(tmpRow != null && tmpRow.getID() == CAT_TAGS)
					{
						var tagrow = new TagRow (Tag.m_title, Tag.m_tagID, Tag.m_color);
						tagrow.setExits(true);
						m_list.insert(tagrow, pos);
						tagrow.reveal(true);
						break;
					}
				}
			}
		}
		
		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpRow = row as TagRow;
			if(tmpRow != null && !tmpRow.stillExits())
			{
				m_list.remove(tmpRow);
				tmpRow.destroy();
			}
		}
	}


	private void updateCategories()
	{
		var categories = dataBase.read_categories();
		bool found, inserted;
		int account_type = settings_general.get_enum("account-type");
		var FeedChildList = m_list.get_children();
		
		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpRow = row as categorieRow;
			if(tmpRow != null)
			{
				tmpRow.setExist(false);
			}
		}
		
		if(account_type != TYPE_OWNCLOUD)
		{
			foreach(Gtk.Widget row in FeedChildList)
			{
				var tmpRow = row as categorieRow;
				if(tmpRow != null && (tmpRow.getID() == CAT_ID_MASTER || tmpRow.getID() == CAT_TAGS))
				{
					tmpRow.setExist(true);
				}
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
					if((tmpRow.getID() == item.m_categorieID))
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
				int level = item.m_level;
				string parent = item.m_parent;
				if(account_type != TYPE_OWNCLOUD)
				{
					level++;
					parent = CAT_ID_MASTER;
				}
				
				var categorierow = new categorieRow(
													item.m_title,
													item.m_categorieID,
													item.m_orderID,
													item.m_unread_count.to_string(),
													parent,
													level,
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
					if(tmpRow != null && tmpRow.getOrder() > categorierow.getOrder() && (tmpRow.getID() == (int.parse(categorierow.getParent())+1).to_string() 
					|| categorierow.getLevel() == 1) || tmpRow.getID() == CAT_TAGS)
					{
						m_list.insert(categorierow, pos-1);
						categorierow.reveal(true);
						inserted = true;
						break;
					}
				}
				if(!inserted)
				{
					m_list.add(categorierow);
					categorierow.reveal(true);
				}
				FeedChildList = m_list.get_children();
			}
		}
		
		this.show_all();
	}


	public void updateFeedList()
	{
		var unread = dataBase.get_unread_total();
		bool found;
		var FeedChildList = m_list.get_children();
		updateCategories();
		updateTags();

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
					if(item.m_feedID == tmpRow.getID() && item.m_categorieID == tmpRow.getCategorie())
					{
						tmpRow.setSubscribed(true);
						tmpRow.update(item.m_title, item.m_unread.to_string());
						found = true;
						break;
					}
					else if(item.m_feedID == tmpRow.getID() && item.m_categorieID != tmpRow.getCategorie())
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
				if(tmpRow.getName() == "All Articles")
				{
					tmpRow.setSubscribed(true);
					tmpRow.update("All Articles", unread.to_string());
				}
				else if(tmpRow.getName() == "")
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
	
	
	public void updateCounters(string feedID, bool increase)
	{
		var FeedChildList = m_list.get_children();
		string catID = "";
		
		// decrease "All Articles"
		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpFeedRow = row as FeedRow;
			if(tmpFeedRow != null && tmpFeedRow.getName() == "All Articles")
			{
				if(increase)
					tmpFeedRow.upUnread();
				else
					tmpFeedRow.downUnread();
				break;
			}
		}
		
		// decrease feedrow
		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpFeedRow = row as FeedRow;
			if(tmpFeedRow != null && tmpFeedRow.getID() == feedID)
			{
				if(increase)
					tmpFeedRow.upUnread();
				else
					tmpFeedRow.downUnread();
				catID = tmpFeedRow.getCategorie();
				break;
			}
		}
		
		// decrease categorierow
		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpCatRow = row as categorieRow;
			if(tmpCatRow != null && tmpCatRow.getID() == catID)
			{
				if(increase)
					tmpCatRow.upUnread();
				else
					tmpCatRow.downUnread();
				break;
			}
		}
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

	private void collapseCategorie(string catID)
	{
		var FeedChildList = m_list.get_children();

		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpFeedRow = row as FeedRow;
			var tmpCatRow = row as categorieRow;
			var tmpTagRow = row as TagRow;
			if(tmpFeedRow != null && tmpFeedRow.getCategorie() == catID)
			{
				tmpFeedRow.reveal(false);
			}
			if(tmpCatRow != null && tmpCatRow.getParent() == catID)
			{
				tmpCatRow.reveal(false);
				collapseCategorie(tmpCatRow.getID());
			}
			if(tmpTagRow != null && catID == CAT_TAGS)
			{
				tmpTagRow.reveal(false);
			}
		}
		
		var selected_feed = m_list.get_selected_row() as FeedRow;
		var selected_cat = m_list.get_selected_row() as categorieRow;
		var selected_tag = m_list.get_selected_row() as TagRow;
		
		if( (selected_feed != null && !selected_feed.isRevealed()) || (selected_cat != null && !selected_cat.isRevealed()) || (selected_tag != null && !selected_tag.isRevealed()) )
		{
			foreach(Gtk.Widget row in FeedChildList)
			{
				var tmpCatRow = row as categorieRow;
				if(tmpCatRow != null && tmpCatRow.getID() == catID)
				{
					m_list.select_row(tmpCatRow);
					m_selected = tmpCatRow;
					newCategorieSelected(catID);
				}
			}
		}
	}


	private void expandCategorie(string catID)
	{
		var FeedChildList = m_list.get_children();

		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpFeedRow = row as FeedRow;
			var tmpCatRow = row as categorieRow;
			var tmpTagRow = row as TagRow;
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
			if(tmpTagRow != null && catID == CAT_TAGS)
			{
				tmpTagRow.reveal(true);
			}
		}
	}



	public string getSelectedFeed()
	{
		FeedRow selected_row = m_list.get_selected_row() as FeedRow;
		if(selected_row != null)
			return selected_row.getID();
		
		return "0";
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
				}
			}
		}
		return e;
	}
	
	public string getSelectedRow()
	{
		var feedrow = m_list.get_selected_row() as FeedRow;
		var catrow = m_list.get_selected_row() as categorieRow;
		var tagrow = m_list.get_selected_row() as TagRow;
		
		if(feedrow != null)
		{
			return "feed " + feedrow.getID();
		}
		else if(catrow != null)
		{
			return "cat " + catrow.getID();
		}
		else if(tagrow != null)
		{
			return "tag " + tagrow.getID();
		}
		
		return "";
	}
	
	
	public double getScrollPos()
	{
		return m_scroll_adjustment.get_value();
	}

}

