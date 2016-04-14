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

public class FeedReader.FeedServer : GLib.Object {
	private ttrss_interface m_ttrss;
	private FeedlyAPI m_feedly;
	private OwncloudNewsAPI m_owncloud;
	private InoReaderAPI m_inoreader;
	private OfflineActionManager m_offlineActions;
	private int m_type;
	private bool m_supportTags;
	private bool m_offline = false;
	public signal void newFeedList();
	public signal void updateFeedList();
	public signal void updateArticleList();
	public signal void writeInterfaceState();
	public signal void showArticleListOverlay();

	public FeedServer(Backend type)
	{
		m_type = type;
		m_supportTags = false;
		m_offlineActions = new OfflineActionManager();
		logger.print(LogMessage.DEBUG, "FeedServer: new with type %i".printf(type));

		switch(m_type)
		{
			case Backend.TTRSS:
				m_ttrss = new ttrss_interface();
				break;

			case Backend.FEEDLY:
				m_feedly = new FeedlyAPI();
				break;

			case Backend.OWNCLOUD:
				m_owncloud = new OwncloudNewsAPI();
				break;
			case Backend.INOREADER:
				m_inoreader = new InoReaderAPI();
				break;
		}
	}

	public int getType()
	{
		return m_type;
	}

	public bool supportTags()
	{
		return m_supportTags;
	}

	public bool supportMultiLevelCategories()
	{
		switch(m_type)
		{
			case Backend.TTRSS:
				return true;

			case Backend.FEEDLY:
			case Backend.OWNCLOUD:
			case Backend.INOREADER:
			default:
				return false;
		}
	}

	public LoginResponse login()
	{
		switch(m_type)
		{
			case Backend.NONE:
				return LoginResponse.NO_BACKEND;

			case Backend.TTRSS:
				var response = m_ttrss.login();
				m_supportTags = false;
				m_ttrss.supportTags.begin((obj, res) => {
					m_supportTags = m_ttrss.supportTags.end(res);
				});
				return response;

			case Backend.FEEDLY:
				if(m_feedly.ping())
				{
					m_supportTags = true;
					return m_feedly.login();
				}
				break;

			case Backend.OWNCLOUD:
				return m_owncloud.login();

			case Backend.INOREADER:
				m_supportTags = true;
				return m_inoreader.login();
		}
		return LoginResponse.UNKNOWN_ERROR;
	}

	public bool logout()
	{
		switch(m_type)
		{
			case Backend.TTRSS:
				return m_ttrss.logout();
				break;

			case Backend.FEEDLY:
				//FIXME: add feedly
				break;

			case Backend.OWNCLOUD:
				// no need to log out
				return true;

			case Backend.INOREADER:
				//FIXME: add inoreader
				break;
		}

		return false;
	}

	public async void syncContent()
	{
		SourceFunc callback = syncContent.callback;

		ThreadFunc<void*> run = () => {

			if(!serverAvailable())
			{
				logger.print(LogMessage.DEBUG, "FeedServer: can't snyc - not logged in or unreachable");
				Idle.add((owned) callback);
				return null;
			}

			int before = dataBase.getHighestRowID();

			var categories = new Gee.LinkedList<category>();
			var feeds      = new Gee.LinkedList<feed>();
			var tags       = new Gee.LinkedList<tag>();

			getFeedsAndCats(feeds, categories, tags);

			// write categories
			dataBase.reset_exists_flag();
			dataBase.write_categories(categories);
			dataBase.delete_nonexisting_categories();

			// write feeds
			dataBase.reset_subscribed_flag();
			dataBase.write_feeds(feeds);
			dataBase.delete_articles_without_feed();
			dataBase.delete_unsubscribed_feeds();

			// write tags
			dataBase.reset_exists_tag();
			dataBase.write_tags(tags);
			dataBase.update_tags(tags);
			dataBase.delete_nonexisting_tags();

			newFeedList();

			int unread = getUnreadCount();
			int max = ArticleSyncCount();

			if(unread > max && settings_general.get_enum("account-type") != Backend.OWNCLOUD)
			{
				getArticles(20, ArticleStatus.MARKED);
				getArticles(unread, ArticleStatus.UNREAD);
			}
			else
			{
				getArticles(max);
			}


			//update fulltext table
			dataBase.updateFTS();

			int after = dataBase.getHighestRowID();
			int newArticles = after-before;
			if(newArticles > 0)
			{
				sendNotification(newArticles);
				showArticleListOverlay();
			}

			switch(settings_general.get_enum("drop-articles-after"))
			{
				case DropArticles.NEVER:
	                break;

				case DropArticles.ONE_WEEK:
					dataBase.dropOldArtilces(1);
					break;

				case DropArticles.ONE_MONTH:
					dataBase.dropOldArtilces(4);
					break;

				case DropArticles.SIX_MONTHS:
					dataBase.dropOldArtilces(24);
					break;
			}

			var now = new DateTime.now_local();
			settings_state.set_int("last-sync", (int)now.to_unix());

			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("syncContent", run);
		yield;

		return;
	}

	public async void InitSyncContent()
	{
		SourceFunc callback = InitSyncContent.callback;

		ThreadFunc<void*> run = () => {
			logger.print(LogMessage.DEBUG, "FeedServer: initial sync");

			var categories = new Gee.LinkedList<category>();
			var feeds      = new Gee.LinkedList<feed>();
			var tags       = new Gee.LinkedList<tag>();

			getFeedsAndCats(feeds, categories, tags);

			// write categories
			dataBase.write_categories(categories);

			// write feeds
			dataBase.write_feeds(feeds);

			// write tags
			dataBase.write_tags(tags);

			newFeedList();

			// get marked articles
			getArticles(settings_general.get_int("max-articles"), ArticleStatus.MARKED);

			// get articles for each tag
			foreach(var tag_item in tags)
			{
				getArticles((settings_general.get_int("max-articles")/8), ArticleStatus.ALL, tag_item.getTagID(), true);
			}

			if(settings_general.get_enum("account-type") != Backend.OWNCLOUD)
			{
				//get max-articls amunt like normal sync
				getArticles(settings_general.get_int("max-articles"));
			}

			// get unread articles
			getArticles(getUnreadCount(), ArticleStatus.UNREAD);

			//update fulltext table
			dataBase.updateFTS();

			settings_general.reset("content-grabber");

			var now = new DateTime.now_local();
			settings_state.set_int("last-sync", (int)now.to_unix());

			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("InitSyncContent", run);
		yield;

		return;
	}


	public async void setArticleIsRead(string articleIDs, ArticleStatus read)
	{
		if(m_offline)
		{
			var idArray = articleIDs.split(",");
			foreach(string id in idArray)
			{
				m_offlineActions.markArticleRead(id, read);
			}
			return;
		}

		SourceFunc callback = setArticleIsRead.callback;
		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.updateArticleUnread(articleIDs, read);
					break;

				case Backend.FEEDLY:
					m_feedly.mark_as_read(articleIDs, "entries", read);
					break;

				case Backend.OWNCLOUD:
					m_owncloud.updateArticleUnread(articleIDs, read);
					break;

				case Backend.INOREADER:
					if(read == ArticleStatus.READ)
						m_inoreader.edidTag(articleIDs, "user/-/state/com.google/read");
					else
						m_inoreader.edidTag(articleIDs, "user/-/state/com.google/read", false);
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("setArticleIsRead", run);
		yield;
	}

	public async void setArticleIsMarked(string articleID, ArticleStatus marked)
	{
		if(m_offline)
		{
			m_offlineActions.markArticleStarred(articleID, marked);
			return;
		}

		SourceFunc callback = setArticleIsMarked.callback;
		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.updateArticleMarked(int.parse(articleID), marked);
					break;

				case Backend.FEEDLY:
					m_feedly.setArticleIsMarked(articleID, marked);
					break;

				case Backend.OWNCLOUD:
					m_owncloud.updateArticleMarked(articleID, marked);
					break;
				case Backend.INOREADER:
					if(marked == ArticleStatus.MARKED)
						m_inoreader.edidTag(articleID, "user/-/state/com.google/starred");
					else
						m_inoreader.edidTag(articleID, "user/-/state/com.google/starred", false);
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("setArticleIsMarked", run);
		yield;
	}

	public async void setFeedRead(string feedID)
	{
		if(m_offline)
		{
			m_offlineActions.markFeedRead(feedID);
			return;
		}

		SourceFunc callback = setFeedRead.callback;
		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.markFeedRead(feedID, false);
					break;

				case Backend.FEEDLY:
					m_feedly.mark_as_read(feedID, "feeds", ArticleStatus.READ);
					break;

				case Backend.OWNCLOUD:
					m_owncloud.markFeedRead(feedID, false);
					break;

				case Backend.INOREADER:
					m_inoreader.markAsRead(feedID);
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("setFeedRead", run);
		yield;
	}

	public async void setCategorieRead(string catID)
	{
		if(m_offline)
		{
			m_offlineActions.markCategoryRead(catID);
			return;
		}

		SourceFunc callback = setCategorieRead.callback;
		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.markFeedRead(catID, true);
					break;

				case Backend.FEEDLY:
					m_feedly.mark_as_read(catID, "categories", ArticleStatus.READ);
					break;

				case Backend.OWNCLOUD:
					m_owncloud.markFeedRead(catID, true);
					break;

				case Backend.INOREADER:
					m_inoreader.markAsRead(catID);
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("setCategorieRead", run);
		yield;
	}

	public async void markAllItemsRead()
	{
		if(m_offline)
		{
			m_offlineActions.markAllRead();
			return;
		}

		SourceFunc callback = markAllItemsRead.callback;
		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.markAllItemsRead();
					break;

				case Backend.FEEDLY:
					var categories = dataBase.read_categories();
					foreach(category cat in categories)
					{
						m_feedly.mark_as_read(cat.getCatID(), "categories", ArticleStatus.READ);
					}

					var feeds = dataBase.read_feeds_without_cat();
					foreach(feed Feed in feeds)
					{
						m_feedly.mark_as_read(Feed.getFeedID(), "feeds", ArticleStatus.READ);
					}
					break;

				case Backend.OWNCLOUD:
					m_owncloud.markAllItemsRead();
					break;

				case Backend.INOREADER:
					var categories = dataBase.read_categories();
					foreach(category cat in categories)
					{
						m_inoreader.markAsRead(cat.getCatID());
					}

					var feeds = dataBase.read_feeds_without_cat();
					foreach(feed Feed in feeds)
					{
						m_inoreader.markAsRead(Feed.getFeedID());
					}
					m_inoreader.markAsRead();
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("markAllItemsRead", run);
		yield;
	}


	public async void addArticleTag(string articleID, string tagID)
	{
		if(m_offline)
			return;

		SourceFunc callback = addArticleTag.callback;
		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.addArticleTag(int.parse(articleID), int.parse(tagID), true);
					break;

				case Backend.FEEDLY:
					m_feedly.addArticleTag(articleID, tagID);
					break;

				case Backend.INOREADER:
					m_inoreader.edidTag(articleID, tagID);
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("addArticleTag", run);
		yield;
	}


	public async void removeArticleTag(string articleID, string tagID)
	{
		if(m_offline)
			return;

		SourceFunc callback = removeArticleTag.callback;
		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.addArticleTag(int.parse(articleID), int.parse(tagID), false);
					break;

				case Backend.FEEDLY:
					m_feedly.deleteArticleTag(articleID, tagID);
					break;

				case Backend.INOREADER:
					m_inoreader.edidTag(articleID, tagID, false);
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("removeArticleTag", run);
		yield;
	}

	public string createTag(string caption)
	{
		if(m_offline)
			return ":(";

		switch(m_type)
		{
			case Backend.TTRSS:
				return m_ttrss.createTag(caption).to_string();

			case Backend.FEEDLY:
				return m_feedly.createTag(caption);

			case Backend.INOREADER:
				return m_inoreader.composeTagID(caption);
		}

		return ":(";
	}

	public async void deleteTag(string tagID)
	{
		if(m_offline)
			return;

		SourceFunc callback = deleteTag.callback;
		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.deleteTag(int.parse(tagID));
					break;

				case Backend.FEEDLY:
					m_feedly.deleteTag(tagID);
					break;

				case Backend.INOREADER:
					m_inoreader.deleteTag(tagID);
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("deleteTag", run);
		yield;
	}

	public async void renameTag(string tagID, string title)
	{
		if(m_offline)
			return;

		SourceFunc callback = renameTag.callback;
		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.renameTag(int.parse(tagID), title);
					break;
				case Backend.FEEDLY:
					m_feedly.renameTag(tagID, title);
					break;

				case Backend.INOREADER:
					m_inoreader.renameTag(tagID, title);
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("renameTag", run);
		yield;
	}

	public bool serverAvailable()
	{
		switch(m_type)
		{
			case Backend.TTRSS:
				return m_ttrss.ping();

			case Backend.FEEDLY:
				return m_feedly.ping();

			case Backend.OWNCLOUD:
				return m_owncloud.ping();
				return true;

			case Backend.INOREADER:
				return m_inoreader.ping();
		}

		return false;
	}

	public async string addFeed(string feedURL, string? catID = null, string? newCatName = null)
	{
		string feedID = "";

		SourceFunc callback = addFeed.callback;
		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					if(catID == null && newCatName != null)
					{
						var newCatID = m_ttrss.createCategory(newCatName);
						m_ttrss.subscribeToFeed(feedURL, newCatID);
					}
					else
					{
						m_ttrss.subscribeToFeed(feedURL, catID);
					}
					feedID = (dataBase.getHighestFeedID() + 1).to_string();
					break;

				case Backend.FEEDLY:
					if(catID == null && newCatName != null)
					{
						string newCatID = m_feedly.createCatID(newCatName);
						m_feedly.addSubscription(feedURL, null, newCatID);
					}
					else
					{
						m_feedly.addSubscription(feedURL, null, catID);
					}
					feedID = "feed/" + feedURL;
					break;

				case Backend.OWNCLOUD:
					string newFeedID = "";
					if(catID == null && newCatName != null)
					{
						string newCatID = m_owncloud.addFolder(newCatName).to_string();
						newFeedID = m_owncloud.addFeed(feedURL, newCatID).to_string();
					}
					else
					{
						newFeedID = m_owncloud.addFeed(feedURL, catID).to_string();
					}
					feedID = newFeedID;
					break;

				case Backend.INOREADER:
					if(catID == null && newCatName != null)
					{
						string newCatID = m_inoreader.composeTagID(newCatName);
						m_inoreader.editSubscription(InoSubscriptionAction.SUBSCRIBE, "feed/"+feedURL, null, newCatID);
					}
					else
					{
						m_inoreader.editSubscription(InoSubscriptionAction.SUBSCRIBE, "feed/"+feedURL, null, catID);
					}
					feedID = "feed/" + feedURL;
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("addFeed", run);
		yield;

		return feedID;
	}

	public async void removeFeed(string feedID)
	{
		SourceFunc callback = removeFeed.callback;

		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.unsubscribeFeed(feedID);
					break;

				case Backend.FEEDLY:
					m_feedly.removeSubscription(feedID);
					break;

				case Backend.OWNCLOUD:
					m_owncloud.removeFeed(feedID);
					break;

				case Backend.INOREADER:
					m_inoreader.editSubscription(InoSubscriptionAction.UNSUBSCRIBE, feedID);
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("removeFeed", run);
		yield;
	}

	public async void renameFeed(string feedID, string title)
	{
		SourceFunc callback = renameFeed.callback;

		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.renameFeed(feedID, title);
					break;

				case Backend.FEEDLY:
					var feed = dataBase.read_feed(feedID);
					m_feedly.addSubscription(feed.getFeedID(), title, feed.getCatString());
					break;

				case Backend.OWNCLOUD:
					m_owncloud.reameFeed(feedID, title);
					break;

				case Backend.INOREADER:
					m_inoreader.editSubscription(InoSubscriptionAction.EDIT, feedID, title);
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("renameFeed", run);
		yield;
	}

	public string createCategory(string title)
	{
		switch(m_type)
		{
			case Backend.TTRSS:
				return m_ttrss.createCategory(title);

			case Backend.FEEDLY:
				return m_feedly.createCatID(title);

			case Backend.OWNCLOUD:
				return m_owncloud.addFolder(title).to_string();

			case Backend.INOREADER:
				return m_inoreader.composeTagID(title);
		}

		return "fail";
	}

	public async void renameCategory(string catID, string title)
	{
		SourceFunc callback = renameCategory.callback;

		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.renameCategory(catID, title);
					break;

				case Backend.FEEDLY:
					m_feedly.renameCategory(catID, title);
					break;

				case Backend.OWNCLOUD:
					m_owncloud.reameFolder(catID, title);
					break;

				case Backend.INOREADER:
					m_inoreader.renameTag(catID, title);
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("renameCategory", run);
		yield;
	}

	public async void deleteCategory(string catID)
	{
		SourceFunc callback = deleteCategory.callback;

		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.removeCategory(catID);
					break;

				case Backend.FEEDLY:
					m_feedly.removeCategory(catID);
					break;

				case Backend.OWNCLOUD:
					m_owncloud.removeFolder(catID);
					break;

				case Backend.INOREADER:
					m_inoreader.deleteTag(catID);
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("deleteCategory", run);
		yield;
	}

	public async void removeCatFromFeed(string feedID, string catID)
	{
		SourceFunc callback = removeCatFromFeed.callback;

		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
				case Backend.OWNCLOUD:
				case Backend.INOREADER:
					return null;

				// only feedly supports multiple categories atm
				case Backend.FEEDLY:
					var feed = dataBase.read_feed(feedID);
					m_feedly.addSubscription(feed.getFeedID(), feed.getTitle(), feed.getCatString().replace(catID + ",", ""));
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("removeCatFromFeed", run);
		yield;
	}

	public async void importOPML(string opml)
	{
		SourceFunc callback = importOPML.callback;

		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
				case Backend.OWNCLOUD:
				case Backend.INOREADER:
					var parser = new OPMLparser(opml);
					parser.parse();
					break;

				case Backend.FEEDLY:
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("importOPML", run);
		yield;
	}

	private void getFeedsAndCats(Gee.LinkedList<feed> feeds, Gee.LinkedList<category> categories, Gee.LinkedList<tag> tags)
	{
		switch(m_type)
		{
			case Backend.TTRSS:
				m_ttrss.getCategories(categories);
				m_ttrss.getFeeds(feeds, categories);
				m_ttrss.getTags(tags);
				return;

			case Backend.FEEDLY:
				m_feedly.getUnreadCounts();
				m_feedly.getCategories(categories);
				m_feedly.getFeeds(feeds);
				m_feedly.getTags(tags);
				return;

			case Backend.OWNCLOUD:
				m_owncloud.getFeeds(feeds);
				m_owncloud.getCategories(categories, feeds);
				return;

			case Backend.INOREADER:
				m_inoreader.getFeeds(feeds);
				m_inoreader.getCategoriesAndTags(feeds, categories, tags);
				return;
		}
	}

	private int getUnreadCount()
	{
		switch(m_type)
		{
			case Backend.TTRSS:
				return m_ttrss.getUnreadCount();

			case Backend.FEEDLY:
				return m_feedly.getTotalUnread();

			case Backend.OWNCLOUD:
				return (int)dataBase.get_unread_total();

			case Backend.INOREADER:
				return m_inoreader.getTotalUnread();
		}

		return 0;
	}

	private void getArticles(int count, ArticleStatus whatToGet = ArticleStatus.ALL, string? feedID = null, bool isTagID = false)
	{
		switch(m_type)
		{
			case Backend.TTRSS:
				// first update read and marked status of (nearly) all existing articles
				if(settings_tweaks.get_boolean("ttrss-newsplus") && whatToGet != ArticleStatus.MARKED)
				{
					logger.print(LogMessage.DEBUG, "getArticles: newsplus plugin active");
					var unreadIDs = m_ttrss.NewsPlusUpdateUnread(10*settings_general.get_int("max-articles"));
					if(unreadIDs != null)
					{
						dataBase.updateArticlesByID(unreadIDs, "unread");
					}

					var markedIDs = m_ttrss.NewsPlusUpdateMarked(settings_general.get_int("max-articles"));
					if(markedIDs != null)
					{
						dataBase.updateArticlesByID(markedIDs, "marked");
					}
					updateArticleList();
				}

				int ttrss_feedID = 0;
				if(feedID == null)
					ttrss_feedID = TTRSSSpecialID.ALL;
				else
					ttrss_feedID = int.parse(feedID);


				string articleIDs = "";
				int skip = count;
				int amount = 200;

				while(skip > 0)
				{
					if(skip >= amount)
					{
						skip -= amount;
					}
					else
					{
						amount = skip;
						skip = 0;
					}

					var articles = new Gee.LinkedList<article>();
					m_ttrss.getHeadlines(articles, skip, amount, whatToGet, ttrss_feedID);

					if(!settings_tweaks.get_boolean("ttrss-newsplus"))
					{
						dataBase.update_articles(articles);
						updateArticleList();
					}

					foreach(article Article in articles)
					{
						if(!dataBase.article_exists(Article.getArticleID()))
						{
							articleIDs += Article.getArticleID() + ",";
						}
					}
				}

				if(articleIDs.length > 0)
					articleIDs = articleIDs.substring(0, articleIDs.length -1);

				var articles = new Gee.LinkedList<article>();

				if(articleIDs != "")
					m_ttrss.getArticles(articleIDs, articles);

				articles.sort((a, b) => {
						return strcmp(a.getArticleID(), b.getArticleID());
				});


				if(articles.size > 0)
				{
					var new_articles = new Gee.LinkedList<article>();
					string last = articles.last().getArticleID();

					foreach(article Article in articles)
					{
						int before = dataBase.getHighestRowID();
						FeedServer.grabContent(Article);
						new_articles.add(Article);

						if(new_articles.size == 10 || Article.getArticleID() == last)
						{
							writeInterfaceState();
							logger.print(LogMessage.DEBUG, "FeedServer: write batch of %i articles to db".printf(new_articles.size));
							dataBase.write_articles(new_articles);
							updateFeedList();
							updateArticleList();
							new_articles = new Gee.LinkedList<article>();
							setNewRows(before);
						}
					}
				}
				break;

			case Backend.FEEDLY:
				string continuation = "";
				string feedly_tagID = "";
				string feedly_feedID = "";
				if(feedID != null)
				{
					if(isTagID)
					{
						feedly_tagID = feedID;
					}
					else
					{
						feedly_feedID = feedID;
					}
				}

				int skip = count;
				int amount = 200;
				var articles = new Gee.LinkedList<article>();

				while(skip > 0)
				{
					if(skip >= amount)
					{
						skip -= amount;
					}
					else
					{
						amount = skip;
						skip = 0;
					}

					continuation = m_feedly.getArticles(articles, amount, continuation, whatToGet, feedly_tagID, feedly_feedID);

					if(continuation == "")
						break;
				}

				writeArticlesInChunks(articles, 10);
				break;

			case Backend.OWNCLOUD:
				OwnCloudType type = OwnCloudType.ALL;
				bool read = true;
				int id = 0;

				switch(whatToGet)
				{
					case ArticleStatus.ALL:
						break;
					case ArticleStatus.UNREAD:
						read = false;
						break;
					case ArticleStatus.MARKED:
						type = OwnCloudType.STARRED;
						break;
				}

				if(feedID != null)
				{
					if(isTagID == true)
						return;

					id = int.parse(feedID);
					type = OwnCloudType.FEED;
				}

				var articles = new Gee.LinkedList<article>();

				if(count == -1)
					m_owncloud.getNewArticles(articles, dataBase.getLastModified(), type, id);
				else
					m_owncloud.getArticles(articles, 0, -1, read, type, id);

				writeArticlesInChunks(articles, 10);
				break;

			case Backend.INOREADER:
				if(whatToGet == ArticleStatus.READ)
				{
					return;
				}
				else if(whatToGet == ArticleStatus.ALL)
				{
					var unreadIDs = new Gee.LinkedList<string>();
					string? continuation = null;
					int left = 4*count;

					while(left > 0)
					{
						if(left > 1000)
						{
							continuation = m_inoreader.updateArticles(unreadIDs, 1000, continuation);
							left -= 1000;
						}
						else
						{
							m_inoreader.updateArticles(unreadIDs, left, continuation);
							left = 0;
						}
					}
					dataBase.updateArticlesByID(unreadIDs, "unread");
					updateArticleList();
				}

				var articles = new Gee.LinkedList<article>();
				string? continuation = null;
				int left = count;
				string? inoreader_feedID = (isTagID) ? null : feedID;
				string? inoreader_tagID = (isTagID) ? feedID : null;

				while(left > 0)
				{
					if(left > 1000)
					{
						continuation = m_inoreader.getArticles(articles, 1000, whatToGet, continuation, inoreader_tagID, inoreader_feedID);
						left -= 1000;
					}
					else
					{
						continuation = m_inoreader.getArticles(articles, left, whatToGet, continuation, inoreader_tagID, inoreader_feedID);
						left = 0;
					}
				}
				//m_inoreader.getArticles(articles, 1, ArticleStatus.READ, null, null, null);
				//m_inoreader.getArticles(articles, 1, ArticleStatus.UNREAD, null, null, null);
				//m_inoreader.getArticles(articles, 1, ArticleStatus.MARKED, null, null, null);
				writeArticlesInChunks(articles, 10);
				break;
		}
	}

	private void writeArticlesInChunks(Gee.LinkedList<article> articles, int chunksize)
	{
		if(articles.size > 0)
		{
			string last = articles.first().getArticleID();
			dataBase.update_articles(articles);
			var new_articles = new Gee.LinkedList<article>();

			var it = articles.bidir_list_iterator();
			for (var has_next = it.last(); has_next; has_next = it.previous())
			{
				article Article = it.get();
				int before = dataBase.getHighestRowID();
				FeedServer.grabContent(Article);
				new_articles.add(Article);

				if(new_articles.size == chunksize || Article.getArticleID() == last)
				{
					writeInterfaceState();
					dataBase.write_articles(new_articles);
					updateFeedList();
					updateArticleList();
					new_articles = new Gee.LinkedList<article>();
					setNewRows(before);
				}
			}
		}
	}

	private void setNewRows(int before)
	{
		int after = dataBase.getHighestRowID();
		int newArticles = after-before;
		logger.print(LogMessage.DEBUG, "FeedServer: new articles: %i".printf(newArticles));

		if(newArticles > 0 && settings_state.get_boolean("no-animations"))
		{
			logger.print(LogMessage.DEBUG, "UI NOT running: setting \"articlelist-new-rows\"");
			int newCount = settings_state.get_int("articlelist-new-rows") + (int)Utils.getRelevantArticles(newArticles);
			settings_state.set_int("articlelist-new-rows", newCount);
		}
	}


	private void sendNotification(uint newArticles)
	{
		try{
			string message = "";
			string summary = _("New Articles");
			uint count = dataBase.get_unread_total();

			if(!Notify.is_initted())
			{
				logger.print(LogMessage.ERROR, "notification: libnotifiy not initialized");
				return;
			}

			if(count > 0 && newArticles > 0)
			{
				if(count == 1)
					message = _("There is 1 new article");
				else
					message = _("There are %u new articles").printf(count);


				if(notification == null)
				{
					notification = new Notify.Notification(summary, message, AboutInfo.iconName);
					notification.set_urgency(Notify.Urgency.NORMAL);
					notification.set_app_name(AboutInfo.programmName);
					notification.set_hint("desktop-entry", new Variant ("(s)", "feedreader"));

					if(m_notifyActionSupport)
					{
						notification.add_action ("default", "Show FeedReader", (notification, action) => {
							logger.print(LogMessage.DEBUG, "notification: default action");
							try {
								notification.close();
							} catch (Error e) {
								logger.print(LogMessage.ERROR, e.message);
							}

							string[] spawn_args = {"feedreader"};
							try{
								GLib.Process.spawn_async("/", spawn_args, null , GLib.SpawnFlags.SEARCH_PATH, null, null);
							}catch(GLib.SpawnError e){
								logger.print(LogMessage.ERROR, "spawning command line: %s".printf(e.message));
							}
						});
					}
				}
				else
				{
					notification.update(summary, message, AboutInfo.iconName);
				}

				notification.show();
			}
		}catch (GLib.Error e) {
			logger.print(LogMessage.ERROR, e.message);
		}
	}


	public static void grabContent(article Article)
	{
		if(!dataBase.article_exists(Article.getArticleID()))
		{
			if(settings_general.get_enum("content-grabber") == ContentGrabber.BUILTIN)
			{
				var grabber = new Grabber(Article.getURL(), Article.getArticleID(), Article.getFeedID());
				if(grabber.process())
				{
					grabber.print();
					if(Article.getAuthor() != "" && grabber.getAuthor() != null)
					{
						Article.setAuthor(grabber.getAuthor());
					}
					if(Article.getTitle() != "" && grabber.getTitle() != null)
					{
						Article.setTitle(grabber.getTitle());
					}
					string html = grabber.getArticle();
					string xml = "<?xml";

					while(html.has_prefix(xml))
					{
						int end = html.index_of_char('>');
						html = html.slice(end+1, html.length).chug();
					}

					Article.setHTML(html);

					return;
				}
			}
			else if(settings_general.get_enum("content-grabber") == ContentGrabber.READABILITY)
			{
				var grabber = new ReadabilityParserAPI(Article.getURL());
				grabber.process();
				Article.setAuthor(grabber.getAuthor());
				Article.setHTML(grabber.getContent());
				Article.setPreview(grabber.getPreview());
			}

			downloadImages(Article);
		}
	}

	private static void downloadImages(article Article)
	{
		var html_cntx = new Html.ParserCtxt();
        html_cntx.use_options(Html.ParserOption.NOERROR + Html.ParserOption.NOWARNING);
        Html.Doc* doc = html_cntx.read_doc(Article.getHTML(), "");
        if (doc == null)
        {
            logger.print(LogMessage.DEBUG, "Grabber: parsing failed");
    		return;
    	}
		grabberUtils.repairURL("//img", "src", doc, Article.getURL());
		grabberUtils.stripNode(doc, "//a[not(node())]");
		grabberUtils.removeAttributes(doc, null, "style");
        grabberUtils.removeAttributes(doc, "a", "onclick");
        grabberUtils.removeAttributes(doc, "img", "srcset");
        grabberUtils.removeAttributes(doc, "img", "sizes");
		grabberUtils.saveImages(doc, Article.getArticleID(), Article.getFeedID());

		string html = "";
		doc->dump_memory_enc(out html);
        html = grabberUtils.postProcessing(ref html);
		Article.setHTML(html);
		delete doc;
	}

	private static int ArticleSyncCount()
	{
		if(settings_general.get_enum("account-type") == Backend.OWNCLOUD)
			return -1;

		return settings_general.get_int("max-articles");
	}

	public void setOffline()
	{
		logger.print(LogMessage.DEBUG, "FeedServer: setOffline");
		m_offline = true;
	}

	public void setOnline()
	{
		logger.print(LogMessage.DEBUG, "FeedServer: setOnline");
		m_offline = false;
		if(serverAvailable())
		{
			logger.print(LogMessage.DEBUG, "FeedServer: server is available again");
			m_offlineActions.goOnline();
			dataBase.resetOfflineActions();
		}
	}
}
