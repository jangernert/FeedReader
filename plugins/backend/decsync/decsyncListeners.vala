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

public class FeedReader.DecsyncListeners : GLib.Object {

	public class ReadMarkListener : OnSubdirEntryUpdateListener<Unit> {

		private Gee.List<string> m_subdir;
		private bool m_is_read_entry;
		private decsyncInterface m_plugin;

		public ReadMarkListener(bool is_read_entry, decsyncInterface plugin)
		{
			this.m_subdir = toList({"articles", is_read_entry ? "read" : "marked"});
			this.m_is_read_entry = is_read_entry;
			this.m_plugin = plugin;
		}

		public override Gee.List<string> subdir()
		{
			return m_subdir;
		}

		public override void onSubdirEntryUpdate(Gee.List<string> path, Decsync.Entry entry, Unit extra)
		{
			var articleID = entry.key.get_string();
			if (articleID == null)
			{
				Logger.warning("Invalid articleID " + Json.to_string(entry.key, false));
				return;
			}
			var added = entry.value.get_boolean();
			if (m_is_read_entry)
			{
				Logger.debug((added ? "read " : "unread ") + articleID);
			}
			else
			{
				Logger.debug((added ? "mark " : "unmark ") + articleID);
			}
			Article? article = m_plugin.m_db.read_article(articleID);
			if (article == null)
			{
				Logger.info("Unkown article " + articleID);
				return;
			}
			if (m_is_read_entry)
			{
				article.setUnread(added ? ArticleStatus.READ : ArticleStatus.UNREAD);
			}
			else
			{
				article.setMarked(added ? ArticleStatus.MARKED : ArticleStatus.UNMARKED);
			}
			m_plugin.m_db_write.update_article(article);
		}
	}

	public class SubscriptionsListener : OnSubfileEntryUpdateListener<Unit> {

		private Gee.List<string> m_subfile;
		private decsyncInterface m_plugin;

		public SubscriptionsListener(decsyncInterface plugin)
		{
			this.m_subfile = toList({"feeds", "subscriptions"});
			this.m_plugin = plugin;
		}

		public override Gee.List<string> subfile()
		{
			return m_subfile;
		}

		public override void onSubfileEntryUpdate(Decsync.Entry entry, Unit extra)
		{
			var feedID = entry.key.get_string();
			if (feedID == null)
			{
				Logger.warning("Invalid feedID " + Json.to_string(entry.key, false));
				return;
			}
			var subscribed = entry.value.get_boolean();
			if (subscribed)
			{
				string outFeedID, errmsg;
				m_plugin.addFeedWithDecsync(feedID, null, null, out outFeedID, out errmsg, false);
			}
			else
			{
				m_plugin.m_db_write.delete_feed(feedID);
			}
		}
	}

	public class FeedNamesListener : OnSubfileEntryUpdateListener<Unit> {

		private Gee.List<string> m_subfile;
		private decsyncInterface m_plugin;

		public FeedNamesListener(decsyncInterface plugin)
		{
			this.m_subfile = toList({"feeds", "names"});
			this.m_plugin = plugin;
		}

		public override Gee.List<string> subfile()
		{
			return m_subfile;
		}

		public override void onSubfileEntryUpdate(Decsync.Entry entry, Unit extra)
		{
			var feedID = entry.key.get_string();
			if (feedID == null)
			{
				Logger.warning("Invalid feedID " + Json.to_string(entry.key, false));
				return;
			}
			var name = entry.value.get_string();
			if (name == null)
			{
				Logger.warning("Invalid name " + Json.to_string(entry.value, false));
				return;
			}
			m_plugin.m_db_write.rename_feed(feedID, name);
		}
	}

	public class CategoriesListener : OnSubfileEntryUpdateListener<Unit> {

		private Gee.List<string> m_subfile;
		private decsyncInterface m_plugin;

		public CategoriesListener(decsyncInterface plugin)
		{
			this.m_subfile = toList({"feeds", "categories"});
			this.m_plugin = plugin;
		}

		public override Gee.List<string> subfile()
		{
			return m_subfile;
		}

		public override void onSubfileEntryUpdate(Decsync.Entry entry, Unit extra)
		{
			var feedID = entry.key.get_string();
			if (feedID == null)
			{
				Logger.warning("Invalid feedID " + Json.to_string(entry.key, false));
				return;
			}
			var feed = m_plugin.m_db.read_feed(feedID);
			if (feed == null) return;
			var currentCatID = feed.getCatString();
			string newCatID;
			if (entry.value.is_null())
			{
				newCatID = m_plugin.uncategorizedID();
			}
			else
			{
				newCatID = entry.value.get_string();
			}
			if (newCatID == null)
			{
				Logger.warning("Invalid catID " + Json.to_string(entry.value, false));
				return;
			}
			addCategory(m_plugin, newCatID);
			m_plugin.m_db_write.move_feed(feedID, currentCatID, newCatID);
		}
	}

	public class CategoryNamesListener : OnSubfileEntryUpdateListener<Unit> {

		private Gee.List<string> m_subfile;
		private decsyncInterface m_plugin;

		public CategoryNamesListener(decsyncInterface plugin)
		{
			this.m_subfile = toList({"categories", "names"});
			this.m_plugin = plugin;
		}

		public override Gee.List<string> subfile()
		{
			return m_subfile;
		}

		public override void onSubfileEntryUpdate(Decsync.Entry entry, Unit extra)
		{
			var catID = entry.key.get_string();
			if (catID == null)
			{
				Logger.warning("Invalid catID " + Json.to_string(entry.key, false));
				return;
			}
			var name = entry.value.get_string();
			if (name == null)
			{
				Logger.warning("Invalid name " + Json.to_string(entry.value, false));
				return;
			}
			m_plugin.m_db_write.rename_category(catID, name);
			Logger.debug("Renamed category " + catID + " to " + name);
		}
	}

	public class CategoryParentsListener : OnSubfileEntryUpdateListener<Unit> {

		private Gee.List<string> m_subfile;
		private decsyncInterface m_plugin;

		public CategoryParentsListener(decsyncInterface plugin)
		{
			this.m_subfile = toList({"categories", "parents"});
			this.m_plugin = plugin;
		}

		public override Gee.List<string> subfile()
		{
			return m_subfile;
		}

		public override void onSubfileEntryUpdate(Decsync.Entry entry, Unit extra)
		{
			var catID = entry.key.get_string();
			if (catID == null)
			{
				Logger.warning("Invalid catID " + Json.to_string(entry.key, false));
				return;
			}
			string parentID;
			if (entry.value.is_null())
			{
				parentID = CategoryID.MASTER.to_string();
			}
			else
			{
				parentID = entry.value.get_string();
			}
			if (parentID == null)
			{
				Logger.warning("Invalid parentID " + Json.to_string(entry.value, false));
				return;
			}
			addCategory(m_plugin, parentID);
			m_plugin.m_db_write.move_category(catID, parentID);
			Logger.debug("Moved category " + catID + " to " + parentID);
		}
	}

	private static void addCategory(decsyncInterface plugin, string catID)
	{
		if (catID == plugin.uncategorizedID() || catID == CategoryID.MASTER.to_string() || plugin.m_db.read_category(catID) != null)
		{
			return;
		}
		var cat = new Category(catID, catID, 0, 99, CategoryID.MASTER.to_string(), 1);
		var list = new Gee.LinkedList<Category>();
		list.add(cat);
		plugin.m_db_write.write_categories(list);
		plugin.m_sync.executeStoredEntries({"categories", "names"}, new Unit(),
			stringEquals(catID)
		);
		plugin.m_sync.executeStoredEntries({"categories", "parents"}, new Unit(),
			stringEquals(catID)
		);
		Logger.debug("Added category " + catID);
	}
}
