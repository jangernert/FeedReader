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

public class FeedReader.feedList : Gtk.Stack {

	private Gtk.ScrolledWindow m_scroll;
	private Gtk.ListBox m_list;
	private Gtk.ListBoxRow? m_selected = null;
	private TagRow? m_emptyTagRow = null;
	private Gtk.Spinner m_spinner;
	private Gtk.Adjustment m_scroll_adjustment;
	private ServiceInfo m_branding;
	private uint m_expand_collapse_time = 150;
	private bool m_update = false;
	private bool m_busy = false;
	private bool m_TagsDisplayed = false;
	public signal void newFeedSelected(string feedID);
	public signal void newTagSelected(string tagID);
	public signal void newCategorieSelected(string categorieID);
	public signal void markAllArticlesAsRead();
	public signal void clearSelected();

	public feedList () {
		m_spinner = new Gtk.Spinner();
		m_list = new Gtk.ListBox();
		m_list.set_selection_mode(Gtk.SelectionMode.BROWSE);
		m_list.get_style_context().add_class("fr-sidebar");
		m_branding = new ServiceInfo();
		var feedlist_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		feedlist_box.pack_start(m_branding, false, false, 0);
		feedlist_box.pack_start(m_list);

		m_scroll = new Gtk.ScrolledWindow(null, null);
		m_scroll.set_size_request(100, 0);
		m_scroll.add(feedlist_box);
		m_scroll_adjustment = m_scroll.get_vadjustment();

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
					if(!m_update)
						newFeedSelected(selected_row.getID());
					return;
				}
			}
			categorieRow selected_categorie = m_list.get_selected_row() as categorieRow;
			if(selected_categorie != null && selected_categorie != m_selected)
			{
				m_selected = selected_categorie;
				if(!m_update)
					newCategorieSelected(selected_categorie.getID());
				return;
			}
			TagRow selected_tag = m_list.get_selected_row() as TagRow;
			if(selected_tag != null && selected_tag != m_selected)
			{
				m_selected = selected_tag;
				if(!m_update)
					newTagSelected(selected_tag.getID());
				return;
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
				{
					selected_categorie.expand_collapse();
				}

			}
			return true;
		});
	}

	public void collapseSelectedCat()
	{
		categorieRow selected_categorie = m_list.get_selected_row() as categorieRow;
		if(selected_categorie != null && selected_categorie.isExpanded())
		{
			selected_categorie.expand_collapse();
		}
	}

	private void move(bool down)
	{
		FeedRow selected_feed = m_list.get_selected_row() as FeedRow;
		categorieRow selected_categorie = m_list.get_selected_row() as categorieRow;
		TagRow selected_tag = m_list.get_selected_row() as TagRow;

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
		else if(selected_tag != null)
		{
			current = FeedListChildren.index(selected_tag);
		}

		current++;
		while(current < FeedListChildren.length())
		{
			FeedRow current_feed = FeedListChildren.nth_data(current) as FeedRow;
			categorieRow current_categorie = FeedListChildren.nth_data(current) as categorieRow;
			TagRow current_tag = FeedListChildren.nth_data(current) as TagRow;

			if(current_feed != null)
			{
				if(current_feed.getID() != FeedID.SEPARATOR.to_string() && current_feed.isRevealed() && current_feed.getName() != "")
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

			if(current_tag != null)
			{
				if(current_tag.isRevealed())
				{
					m_list.select_row(current_tag);
					newTagSelected(current_tag.getID());
					break;
				}
			}

			current++;
		}
	}


	public void newFeedlist(bool defaultSettings, bool masterCat = false)
	{
		logger.print(LogMessage.DEBUG, "FeedList: new FeedList");

		if(m_busy)
		{
			logger.print(LogMessage.DEBUG, "FeedList: busy");
			return;
		}

		m_busy = true;
		m_branding.refresh();
		var FeedChildList = m_list.get_children();

		if(FeedChildList != null)
		{
			if(!defaultSettings)
			{
				settings_state.set_strv("expanded-categories", getExpandedCategories());
				settings_state.set_string("feedlist-selected-row", getSelectedRow());
			}

			settings_state.set_double("feed-row-scrollpos",  getScrollPos());
			settings_state.set_boolean("no-animations", true);
			m_update = true;
		}

		foreach(Gtk.Widget row in FeedChildList)
		{
			m_list.remove(row);
			row.destroy();
		}
		createFeedlist(defaultSettings, masterCat);
		settings_state.set_boolean("no-animations", false);
		m_update = false;
		m_busy = false;
	}


	private void createFeedlist(bool defaultSettings, bool masterCat)
	{
		var row_separator1 = new FeedRow(null, 0, false, FeedID.SEPARATOR.to_string(), "-1", 0);
		var separator1 = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
		separator1.get_style_context().add_class("fr-sidebar-separator");
		separator1.margin_top = 8;
		row_separator1.add(separator1);
		row_separator1.sensitive = false;
		m_list.add(row_separator1);

		var unread = dataBase.get_unread_total();
		var row_all = new FeedRow(_("All Articles"), unread, false, FeedID.ALL.to_string(), "-1", 0);
		row_all.margin_top = 8;
		row_all.margin_bottom = 8;
		m_list.add(row_all);
		row_all.setAsRead.connect(markSelectedRead);
		row_all.reveal(true);

		var row_separator = new FeedRow(null, 0, false, FeedID.SEPARATOR.to_string(), "-1", 0);
		var separator = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
		separator.get_style_context().add_class("fr-sidebar-separator");
		separator.margin_bottom = 8;
		row_separator.add(separator);
		row_separator.sensitive = false;
		m_list.add(row_separator);

		//-------------------------------------------------------------------

		var feeds = dataBase.read_feeds();

		if(!UtilsUI.onlyShowFeeds())
		{
			createCategories(ref feeds, masterCat);
			createTags();
		}

		foreach(var item in feeds)
		{

			if(!UtilsUI.onlyShowFeeds())
			{
				var FeedChildList = m_list.get_children();
				int pos = 0;
				foreach(Gtk.Widget row in FeedChildList)
				{
					pos++;
					var tmpRow = row as categorieRow;

					if(tmpRow != null)
					{
						if(Utils.arrayContains(item.getCatIDs(), tmpRow.getID())
						|| tmpRow.getID() == "" && item.isUncategorized())
						{
							var feedrow = new FeedRow(
													   item.getTitle(),
													   item.getUnread(),
													   item.hasIcon(),
													   item.getFeedID(),
									                   tmpRow.getID(),
									                   tmpRow.getLevel()
													  );
							m_list.insert(feedrow, pos);
							feedrow.setAsRead.connect(markSelectedRead);
							feedrow.moveUP.connect(moveUP);
							feedrow.deselectRow.connect(deselectRow);
							feedrow.drag_begin.connect((context) => {
								onDragBegin(context);
								showNewCategory();
							});
							feedrow.drag_failed.connect(onDragEnd);
							if(!settings_general.get_boolean("feedlist-only-show-unread") || item.getUnread() != 0)
								feedrow.reveal(true);
							pos++;
						}
					}
				}
			}
			else
			{
				var feedrow = new FeedRow	(
												item.getTitle(),
												item.getUnread(),
												item.hasIcon(),
												item.getFeedID(),
												item.getCatIDs()[0],
												0
											);
				m_list.insert(feedrow, 3);
				feedrow.setAsRead.connect(markSelectedRead);
				feedrow.moveUP.connect(moveUP);
				feedrow.deselectRow.connect(deselectRow);
				feedrow.drag_begin.connect((context) => {
					onDragBegin(context);
					showNewCategory();
				});
				feedrow.drag_failed.connect(onDragEnd);
				if(!settings_general.get_boolean("feedlist-only-show-unread") || item.getUnread() != 0)
					feedrow.reveal(true);
			}
		}

		initCollapseCategories();
		restoreSelectedRow(defaultSettings);
		this.show_all();
		m_scroll_adjustment.notify["upper"].connect(restoreScrollPos);
	}

	private void restoreSelectedRow(bool defaultSettings)
	{
		logger.print(LogMessage.DEBUG, "FeedList: restore selected row: " + settings_state.get_string("feedlist-selected-row"));
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


		// row not found: default select "ALL ARTICLES"
		logger.print(LogMessage.DEBUG, "FeedList: restoreSelectedRow: no selected row found, selectin default");
		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpRow = row as FeedRow;
			if(tmpRow != null && tmpRow.getID() == FeedID.ALL.to_string())
			{
				m_list.select_row(tmpRow);
				tmpRow.activate();
				newFeedSelected(tmpRow.getID());
				return;
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

	private void addMasterCategory(int length, string name)
	{
		var categorierow = new categorieRow(
												name,
												CategoryID.MASTER.to_string(),
												0,
												0,
												CategoryID.NONE.to_string(),
												1,
												// expand the category "categories" if either it is inserted for the first time (no tag before)
												// or if it has to be done to restore the state of the feedrow
												getCatState(CategoryID.MASTER.to_string())
												);
		categorierow.collapse.connect((collapse, catID, selectParent) => {
			if(collapse)
				collapseCategorieInternal(catID, selectParent);
			else
				expandCategorieInternal(catID);
		});
		m_list.insert(categorierow, length+1);
		categorierow.setAsRead.connect(markSelectedRead);
		categorierow.moveUP.connect(moveUP);
		categorierow.reveal(true);
	}

	private void addTagCategory(int length)
	{
		var tagrow = new categorieRow(
												_("Tags"),
												CategoryID.TAGS.to_string(),
												0,
												0,
												CategoryID.NONE.to_string(),
												1,
												// expand the category "tags" if either it is inserted for the first time (no tag before)
												// or if it has to be done to restore the state of the feedrow
												getCatState(CategoryID.TAGS.to_string())
												);
		tagrow.collapse.connect((collapse, catID, selectParent) => {
			if(collapse)
				collapseCategorieInternal(catID, selectParent);
			else
				expandCategorieInternal(catID);
		});
		m_list.insert(tagrow, length+2);
		tagrow.setAsRead.connect(markSelectedRead);
		tagrow.reveal(true);
		m_TagsDisplayed = true;
	}


	private void createCategories(ref Gee.ArrayList<feed> feeds, bool masterCat)
	{
		int maxCatLevel = dataBase.getMaxCatLevel();
		int length = (int)m_list.get_children().length();
		bool supportTags = false;
		bool supportCategories = true;
		bool supportMultiLevelCategories = false;
		string uncategorizedID = "";

		try
		{
			supportTags = feedDaemon_interface.supportTags();
			supportCategories = feedDaemon_interface.supportCategories();
			uncategorizedID = feedDaemon_interface.uncategorizedID();
			supportMultiLevelCategories = feedDaemon_interface.supportMultiLevelCategories();
		}
		catch(GLib.Error e)
		{
			logger.print(LogMessage.ERROR, "FeedList.createCategories: %s".printf(e.message));
		}

		if((supportTags
		&& !dataBase.isTableEmpty("tags"))
		|| masterCat)
		{
			addMasterCategory(length, _("Categories"));
			addTagCategory(length);
		}
		else if(!supportCategories)
		{
			addMasterCategory(length, _("Feeds"));
			m_TagsDisplayed = false;
		}
		else
		{
			m_TagsDisplayed = false;
			logger.print(LogMessage.DEBUG, "FeedList: no tags");
		}

		for(int i = 1; i <= maxCatLevel; i++)
		{
			var categories = dataBase.read_categories_level(i, feeds);

			if(dataBase.haveFeedsWithoutCat())
			{
				categories.insert(
					0,
					new category(
						uncategorizedID,
						_("Uncategorized"),
						(int)dataBase.get_unread_uncategorized(),
						(int)(categories.size + 10),
						CategoryID.MASTER.to_string(),
						1
					)
				);
			}

			foreach(var item in categories)
			{
				var FeedChildList = m_list.get_children();
				int pos = 0;
				foreach(Gtk.Widget existing_row in FeedChildList)
				{
					pos++;
					var tmpRow = existing_row as categorieRow;
					if((tmpRow != null && tmpRow.getID() == item.getParent()) ||
						(item.getParent() == CategoryID.MASTER.to_string() && pos > length-1 && !m_TagsDisplayed) ||
						(item.getParent() == CategoryID.MASTER.to_string() && pos > length && m_TagsDisplayed))
					{
						int level = item.getLevel();
						string parent = item.getParent();
						if(m_TagsDisplayed)
						{
							if(level == 1)
								parent = CategoryID.MASTER.to_string();
							level++;
						}

						var categorierow = new categorieRow(
					                                item.getTitle(),
					                                item.getCatID(),
					                                item.getOrderID(),
					                                item.getUnreadCount(),
					                                parent,
							                        level,
							                        getCatState(item.getCatID())
					                                );
					    expand = false;
						categorierow.collapse.connect((collapse, catID, selectParent) => {
							if(collapse)
								collapseCategorieInternal(catID, selectParent);
							else
								expandCategorieInternal(catID);
						});
						m_list.insert(categorierow, pos);
						categorierow.setAsRead.connect(markSelectedRead);
						categorierow.moveUP.connect(moveUP);
						categorierow.deselectRow.connect(deselectRow);
						categorierow.drag_begin.connect((context) => {
							onDragBegin(context);
							if(supportMultiLevelCategories)
								showNewCategory();
						});
						categorierow.drag_failed.connect(onDragEnd);
						if(!settings_general.get_boolean("feedlist-only-show-unread") || item.getUnreadCount() != 0)
							categorierow.reveal(true);
						break;
					}
				}
			}
		}
	}


	private void createTags()
	{
		if(!settings_general.get_boolean("only-feeds"))
		{
			var tags = dataBase.read_tags();
			foreach(var Tag in tags)
			{
				var tagrow = new TagRow (Tag.getTitle(), Tag.getTagID(), Tag.getColor());
				tagrow.moveUP.connect(moveUP);
				tagrow.removeRow.connect(() => {
					removeRow(tagrow);
				});
				m_list.insert(tagrow, -1);
				tagrow.reveal(true);
			}
		}
	}

	public void refreshCounters()
	{
		var feeds = dataBase.read_feeds();
		var categories = dataBase.read_categories(feeds);

		var FeedChildList = m_list.get_children();

		// update "All Articles"
		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpFeedRow = row as FeedRow;
			if(tmpFeedRow != null && tmpFeedRow.getID() == FeedID.ALL.to_string())
			{
				tmpFeedRow.set_unread_count(dataBase.get_unread_total());
				break;
			}
		}

		// update feeds
		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpFeedRow = row as FeedRow;
			if(tmpFeedRow != null)
			{
				foreach(feed Feed in feeds)
				{
					if(tmpFeedRow.getID() == Feed.getFeedID())
					{
						tmpFeedRow.set_unread_count(Feed.getUnread());
						if(settings_general.get_boolean("feedlist-only-show-unread"))
						{
							if(tmpFeedRow.getUnreadCount() == 0)
								tmpFeedRow.reveal(false);
							else if(isCategorieExpanded(tmpFeedRow.getCatID()))
								tmpFeedRow.reveal(true);
						}


						break;
					}
				}
			}
		}

		// update categories
		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpCatRow = row as categorieRow;
			if(tmpCatRow != null)
			{
				foreach(category cat in categories)
				{
					if(tmpCatRow.getID() == cat.getCatID())
					{
						tmpCatRow.set_unread_count(cat.getUnreadCount());
						if(settings_general.get_boolean("feedlist-only-show-unread"))
						{
							if(tmpCatRow.getUnreadCount() == 0)
								tmpCatRow.reveal(false);
							else
								tmpCatRow.reveal(true);
						}

						break;
					}
				}
			}
		}

		if(dataBase.haveFeedsWithoutCat())
		{
			foreach(Gtk.Widget row in FeedChildList)
			{
				var tmpCatRow = row as categorieRow;
				if(tmpCatRow != null && (tmpCatRow.getID() == "" || tmpCatRow.getID() == "0"))
				{
					tmpCatRow.set_unread_count(dataBase.get_unread_uncategorized());
					if(settings_general.get_boolean("feedlist-only-show-unread") && tmpCatRow.getUnreadCount() != 0)
						tmpCatRow.reveal(true);

					break;
				}
			}
		}
	}



	private void initCollapseCategories()
	{
		logger.print(LogMessage.DEBUG, "initCollapseCategories");
		var FeedChildList = m_list.get_children();
		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpCatRow = row as categorieRow;
			if(tmpCatRow != null && !tmpCatRow.isExpanded())
			{
				collapseCategorieInternal(tmpCatRow.getID());
			}
		}
	}


	private void collapseCategorieInternal(string catID, bool selectParent = true)
	{
		var FeedChildList = m_list.get_children();
		var selected_row = m_list.get_selected_row();

		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpFeedRow = row as FeedRow;
			var tmpCatRow = row as categorieRow;
			var tmpTagRow = row as TagRow;
			if(tmpFeedRow != null && tmpFeedRow.getCatID() == catID)
			{
				tmpFeedRow.reveal(false, m_expand_collapse_time);
			}
			if(tmpCatRow != null && tmpCatRow.getParent() == catID)
			{
				tmpCatRow.reveal(false, m_expand_collapse_time);
				collapseCategorieInternal(tmpCatRow.getID(), selectParent);
			}
			if(tmpTagRow != null && catID == CategoryID.TAGS.to_string())
			{
				tmpTagRow.reveal(false, m_expand_collapse_time);
			}
		}

		if(selectParent)
		{
			var selected_feed = selected_row as FeedRow;
			var selected_cat = selected_row as categorieRow;
			var selected_tag = selected_row as TagRow;

			if((selected_feed != null && !selected_feed.isRevealed())
			|| (selected_cat != null && !selected_cat.isRevealed())
			|| (selected_tag != null && !selected_tag.isRevealed()))
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
	}


	private void expandCategorieInternal(string catID)
	{
		var FeedChildList = m_list.get_children();

		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpFeedRow = row as FeedRow;
			var tmpCatRow = row as categorieRow;
			var tmpTagRow = row as TagRow;
			if(tmpFeedRow != null && tmpFeedRow.getCatID() == catID)
			{
				if(!settings_general.get_boolean("feedlist-only-show-unread") || tmpFeedRow.getUnreadCount() != 0)
					tmpFeedRow.reveal(true, m_expand_collapse_time);
			}
			if(tmpCatRow != null && tmpCatRow.getParent() == catID)
			{
				if(!settings_general.get_boolean("feedlist-only-show-unread") || tmpCatRow.getUnreadCount() != 0)
				{
					tmpCatRow.reveal(true, m_expand_collapse_time);
					if(tmpCatRow.isExpanded())
						expandCategorieInternal(tmpCatRow.getID());
				}
			}
			if(tmpTagRow != null && catID == CategoryID.TAGS.to_string())
			{
				tmpTagRow.reveal(true, m_expand_collapse_time);
			}
		}
	}

	public void expand_collapse_category(string catID, bool expand = true)
	{
		var FeedChildList = m_list.get_children();
		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpCatRow = row as categorieRow;
			if(tmpCatRow != null && tmpCatRow.getID() == catID)
			{
				if((!expand && tmpCatRow.isExpanded())
				||(expand && !tmpCatRow.isExpanded()))
					tmpCatRow.expand_collapse(false);
			}
		}
	}


	private bool isCategorieExpanded(string catID)
	{
		var FeedChildList = m_list.get_children();

		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpCatRow = row as categorieRow;
			if(tmpCatRow != null && tmpCatRow.getID() == catID && tmpCatRow.isExpanded())
				return true;
		}

		return false;
	}


	public string getSelectedFeed()
	{
		FeedRow selected_row = m_list.get_selected_row() as FeedRow;
		if(selected_row != null)
			return selected_row.getID();

		return "";
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
					e += tmpCatRow.getID();
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


	private void markSelectedRead(FeedListType type, string id)
	{
		logger.print(LogMessage.DEBUG, "FeedList: mark all articles as read");

		try
		{
			if(type == FeedListType.FEED)
			{
				if(id == FeedID.ALL.to_string())
				{
					feedDaemon_interface.markAllItemsRead();
				}
				else
				{
					feedDaemon_interface.markFeedAsRead(id, false);
				}
			}
			else if(type == FeedListType.CATEGORY)
			{
				if(id == "")
				{
					var feeds = dataBase.read_feeds_without_cat();
					foreach(feed Feed in feeds)
					{
						feedDaemon_interface.markFeedAsRead(Feed.getFeedID(), false);
						logger.print(LogMessage.DEBUG, "MainWindow: mark all articles as read feed: %s".printf(Feed.getTitle()));
					}
				}
				else
				{
					feedDaemon_interface.markFeedAsRead(id, true);
				}
			}
		}
		catch(GLib.Error e)
		{
			logger.print(LogMessage.ERROR, "FeedList.markSelectedRead: %s".printf(e.message));
		}
	}

	private bool getCatState(string id)
	{
		string[] list = settings_state.get_strv("expanded-categories");

		foreach(string str in list)
		{
			if(id == str)
				return true;
		}

		return false;
	}

	public void updateAccountInfo()
	{
		m_branding.refresh();
	}

	public void setOffline()
	{
		m_branding.setOffline();
	}

	public void setOnline()
	{
		m_branding.setOnline();
	}

	public void moveUP()
	{
		move(false);
	}

	public void revealRow(string id, FeedListType type, bool reveal, uint time)
	{
		var FeedChildList = m_list.get_children();

		switch(type)
		{
			case FeedListType.CATEGORY:
				foreach(Gtk.Widget row in FeedChildList)
				{
					var tmpRow = row as categorieRow;
					if(tmpRow != null && tmpRow.getID() == id)
					{
						tmpRow.reveal(reveal, time);
						return;
					}
				}
				break;
			case FeedListType.FEED:
				foreach(Gtk.Widget row in FeedChildList)
				{
					var tmpRow = row as FeedRow;
					if(tmpRow != null && tmpRow.getID() == id)
					{
						tmpRow.reveal(reveal, time);
						return;
					}
				}
				break;
			case FeedListType.TAG:
				foreach(Gtk.Widget row in FeedChildList)
				{
					var tmpRow = row as TagRow;
					if(tmpRow != null && tmpRow.getID() == id)
					{
						tmpRow.reveal(reveal, time);
						return;
					}
				}
				break;
		}
	}

	public void addEmptyTagRow()
	{
		m_emptyTagRow = new TagRow (_("New Tag"), TagID.NEW, 0);
		m_emptyTagRow.moveUP.connect(moveUP);
		m_emptyTagRow.removeRow.connect(() => {
			removeRow(m_emptyTagRow);
		});
		m_list.insert(m_emptyTagRow, -1);
		m_emptyTagRow.reveal(true, 250);
		m_emptyTagRow.opacity = 0.5;
	}

	public void removeEmptyTagRow()
	{
		logger.print(LogMessage.DEBUG, "removeEmptyTagRow");

		if(m_busy)
		{
			logger.print(LogMessage.DEBUG, "FeedList: busy");
			return;
		}

		if(m_emptyTagRow != null)
		{
			removeRow(m_emptyTagRow, 250);
			m_emptyTagRow = null;
		}
	}

	public void deselectRow()
	{
		m_list.select_row(null);
		clearSelected();
	}

	private void removeRow(Gtk.Widget? row, int duration = 700)
	{
		if(row != null)
		{
			var tagRow = row as TagRow;
			var catRow = row as categorieRow;
			var feedRow = row as FeedRow;

			if(tagRow != null)
			{
				tagRow.reveal(false, duration);
				GLib.Timeout.add(duration + 20, () => {
				    m_list.remove(tagRow);
					return false;
				});
			}
			else if(catRow != null)
			{
				catRow.reveal(false, duration);
				GLib.Timeout.add(duration + 20, () => {
				    m_list.remove(catRow);
					return false;
				});
			}
			else if(feedRow != null)
			{
				feedRow.reveal(false, duration);
				GLib.Timeout.add(duration + 20, () => {
				    m_list.remove(feedRow);
					return false;
				});
			}
		}
	}

	private void onDragBegin(Gdk.DragContext context)
	{
		logger.print(LogMessage.DEBUG, "FeedList: onDragBegin");

		// save current state
		var window = ((FeedApp)GLib.Application.get_default()).getWindow();
		window.writeInterfaceState();

		// collapse all feeds and show all Categories
		var FeedChildList = m_list.get_children();
		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpCat = row as categorieRow;
			var tmpFeed = row as FeedRow;
			var tmpTag = row as TagRow;

			if(tmpCat != null)
			{
				tmpCat.reveal(true);
			}
			else if(tmpFeed != null)
			{
				if(tmpFeed.getID() != FeedID.SEPARATOR.to_string()
				&& tmpFeed.getID() != FeedID.ALL.to_string())
				{
					tmpFeed.reveal(false);
				}
			}
			else if(tmpTag != null)
			{
				tmpTag.reveal(false);
			}
		}
	}

	private void showNewCategory()
	{
		int level = 1;
		int pos = -1;

		try
		{
			if(feedDaemon_interface.supportTags())
			{
				var FeedChildList = m_list.get_children();
				foreach(Gtk.Widget row in FeedChildList)
				{
					pos++;
					var tmpCat = row as categorieRow;
					if(tmpCat != null && tmpCat.getID() == CategoryID.TAGS.to_string())
					{
						level = 2;
						break;
					}
				}
			}
			else
			{
				level = 1;
			}
		}
		catch(GLib.Error e)
		{
			logger.print(LogMessage.ERROR, "FeedList.showNewCategory: %s".printf(e.message));
		}

		var newRow = new categorieRow(_("New Category"), CategoryID.NEW.to_string(), 99, 0, CategoryID.MASTER.to_string(), level, false);
		newRow.drag_failed.connect(onDragEnd);
		m_list.insert(newRow, pos);
		newRow.opacity = 0.5;
		newRow.reveal(true);
	}

	private bool onDragEnd(Gdk.DragContext context, Gtk.DragResult result)
	{
		logger.print(LogMessage.DEBUG, "FeedList: onDragBegin");
		var FeedChildList = m_list.get_children();
		foreach(Gtk.Widget row in FeedChildList)
		{
			var tmpCat = row as categorieRow;
			var tmpFeed = row as FeedRow;
			var tmpTag = row as TagRow;

			if(tmpCat != null)
			{
				if(tmpCat.getID() == CategoryID.NEW.to_string())
				{
					removeRow(tmpCat, 250);
					continue;
				}

				if(tmpCat.getID() != CategoryID.MASTER.to_string()
				&& tmpCat.getID() != CategoryID.TAGS.to_string()
				&& tmpCat.getParent() != CategoryID.MASTER.to_string()
				&& !isCategorieExpanded(tmpCat.getParent()))
				{
					tmpCat.reveal(false);
				}
			}
			else if(tmpFeed != null)
			{
				if(tmpFeed.getID() != FeedID.SEPARATOR.to_string()
				&& tmpFeed.getID() != FeedID.ALL.to_string())
				{
					if(isCategorieExpanded(tmpFeed.getCatID()))
						tmpFeed.reveal(true);
				}
			}
			else if(tmpTag != null && isCategorieExpanded(CategoryID.TAGS.to_string()))
			{
				tmpTag.reveal(true);
			}
		}

		return false;
	}

}
