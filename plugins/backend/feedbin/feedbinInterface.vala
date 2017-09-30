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

public class FeedReader.FeedbinInterface : Peas.ExtensionBase, FeedServerInterface {

	private FeedbinAPI m_api;
	private FeedbinUtils m_utils;

	public void init()
	{
		m_api = new FeedbinAPI();
		m_utils = new FeedbinUtils();
	}

	public bool supportTags()
	{
		return false;
	}

	public bool doInitSync()
	{
		return true;
	}

	public string symbolicIcon()
	{
		return "feed-service-feedbin-symbolic";
	}

	public string accountName()
	{
		return m_utils.getUser();
	}

	public string getServerURL()
	{
		return "https://feedbin.com/";
	}

	public string uncategorizedID()
	{
		return "0";
	}

	public bool supportCategories()
	{
		return true;
	}

	public bool supportFeedManipulation()
	{
		return false;
	}

	public bool hideCategoryWhenEmpty(string catID)
	{
		return false;
	}

	public bool supportMultiLevelCategories()
	{
		return false;
	}

	public bool supportMultiCategoriesPerFeed()
	{
		return false;
	}

	public bool syncFeedsAndCategories()
	{
		return true;
	}

	public bool tagIDaffectedByNameChange()
	{
		return false;
	}

	public void resetAccount()
	{
		m_utils.resetAccount();
	}

	public bool useMaxArticles()
	{
		return true;
	}

	public LoginResponse login()
	{
		return m_api.login();
	}

	public bool logout()
	{
		return true;
	}

	public bool serverAvailable()
	{
		return Utils.ping("https://api.feedbin.com/");
	}

	public void setArticleIsRead(string articleID, ArticleStatus read)
	{
		var articleIDs = ListUtils.single<string>(articleID);
		if(read == ArticleStatus.UNREAD)
			m_api.createUnreadEntries(articleIDs, false);
		else if(read == ArticleStatus.READ)
			m_api.createUnreadEntries(articleIDs, true);
	}

	public void setArticleIsMarked(string articleID, ArticleStatus marked)
	{
		var articleIDs = ListUtils.single<string>(articleID);
		if(marked == ArticleStatus.MARKED)
			m_api.createStarredEntries(articleIDs, true);
		else if(marked == ArticleStatus.UNMARKED)
			m_api.createStarredEntries(articleIDs, false);
	}

	private void setRead(string id, FeedListType type)
	{
		int numArticles = 0;
		uint count = 1000;
		uint offset = 0;
		do
		{
			var articles = dbDaemon.get_default().read_articles(id, type, ArticleListState.ALL, "", count, offset);

			FuncUtils.MapFunction<Article, string> articleToID = (article) => { return article.getArticleID(); };
			var articleIDs = FuncUtils.map(articles, articleToID);
			m_api.createUnreadEntries(articleIDs, true);

			offset += count;
			numArticles = articles.size;
		}
		while(numArticles > 0);
	}

	public void setFeedRead(string feedID)
	{
		setRead(feedID, FeedListType.FEED);
	}

	public void setCategoryRead(string catID)
	{
		setRead(catID, FeedListType.CATEGORY);
	}

	public void markAllItemsRead()
	{
		setRead(FeedID.ALL.to_string(), FeedListType.FEED);
	}

	public void tagArticle(string articleID, string tagID)
	{
		return;
	}

	public void removeArticleTag(string articleID, string tagID)
	{
		return;
	}

	public string createTag(string caption)
	{
		return "";
	}

	public void deleteTag(string tagID)
	{
		return;
	}

	public void renameTag(string tagID, string title)
	{
		return;
	}

	public bool addFeed(string feed_url, string? cat_id, string? category_name, out string feed_id, out string errmsg)
	{
		feed_id = "";
		var subscription_id = m_api.addSubscription(feed_url, out errmsg);
		if(subscription_id == null || errmsg != "")
			return false;

		var new_feed_id = m_api.getFeedIDForSubscription(subscription_id);
		if(new_feed_id == null)
			return false;

		feed_id = new_feed_id;
		if(category_name != null)
			m_api.addTagging(feed_id, category_name);

		return true;
	}

	public void addFeeds(Gee.List<Feed> feeds)
	{
		return;
	}

	public void removeFeed(string feedID)
	{
		m_api.deleteSubscription(feedID);
	}

	public void renameFeed(string feedID, string title)
	{
		m_api.renameFeed(feedID, title);
	}

	public void moveFeed(string feed_id, string new_category_id, string? old_category_id)
	{
		m_api.addTagging(feed_id, new_category_id);
	}

	public void renameCategory(string old_category, string new_category)
	{
		Logger.debug(@"renameCategory: From $old_category to $new_category");
		Gee.Map<string, string> feed_category_map = m_api.getTaggings();
		foreach(var entry in feed_category_map.entries)
		{
			var feed_id = entry.key;
			var feed_category = entry.value;
			if(feed_category != old_category)
				continue;
			Logger.debug(@"renameCategory: Tagging $feed_id with $new_category");
			m_api.addTagging(feed_id, new_category);
		}
	}

	public void moveCategory(string catID, string newParentID)
	{
		// Feedbin doesn't have multi-level categories
		return;
	}

	public string createCategory(string title, string? parentID)
	{
		// Categories are created and destroyed based on feeds having them.
		// There are no empty categories in Feedbin
		return "";
	}

	public void deleteCategory(string catID)
	{
	}

	public void removeCatFromFeed(string feedID, string catID)
	{
		// TODO: Add delete tagging to m_api
	}

	public void importOPML(string opml)
	{
	}

	public bool getFeedsAndCats(Gee.List<Feed> feeds, Gee.List<Category> categories, Gee.List<tag> tags, GLib.Cancellable? cancellable = null)
	{
		var new_feeds = m_api.getFeeds();
		if(new_feeds == null)
			return false;
		feeds.clear();
		feeds.add_all(new_feeds);

		if(cancellable != null && cancellable.is_cancelled())
			return false;

		var taggings = m_api.getTaggings();
		if(taggings == null || (cancellable != null && cancellable.is_cancelled()))
			return false;

		// It's easier to rebuild the category list than to update it
		var category_names = new Gee.HashSet<string>();
		category_names.add_all(taggings.values);
		Logger.debug("getFeedsAndCats: Got %d categories: %s".printf(category_names.size, StringUtils.join(category_names, ", ")));

		categories.clear();
		foreach(string name in category_names)
		{
			// Note: Feedbin categories *are* case sensitive, so we don't need
			// to change the case here. "articles" and "Articles" are different
			// tags.
			categories.add(
				new Category (
					name,
					name,
					0,
					0,
					CategoryID.MASTER.to_string(),
					1
				)
			);
		}

		// Each feed can only have one "tag" in Feedbin, so either set or
		// remove the tag
		foreach(Feed feed in feeds)
		{
			var feed_id = feed.getFeedID();
			if(taggings.has_key(feed_id))
				feed.setCategory(taggings.get(feed_id));
			else
				feed.setCategory(uncategorizedID());
		}
		return true;
	}

	public int getUnreadCount()
	{
		return m_api.unreadEntries().size;
	}

	public void getArticles(int count, ArticleStatus whatToGet, string? feedID, bool isTagID, GLib.Cancellable? cancellable = null)
	{
		if(whatToGet == ArticleStatus.READ)
		{
			return;
		}

		var settings_state = new GLib.Settings("org.gnome.feedreader.saved-state");
		DateTime? time = null;
		switch(Settings.general().get_enum("drop-articles-after"))
		{
			case DropArticles.ONE_WEEK:
				time = new DateTime.now_utc().add_weeks(-1);
				break;

			case DropArticles.ONE_MONTH:
				time = new DateTime.now_utc().add_months(-1);
				break;

			case DropArticles.SIX_MONTHS:
				time = new DateTime.now_utc().add_months(-6);
				break;
		}
		if(!dbDaemon.get_default().isTableEmpty("articles"))
		{
			var last_sync = new DateTime.from_unix_utc(settings_state.get_int("last-sync"));
			if(time == null || last_sync.to_unix() > time.to_unix())
			{
				time = last_sync;
			}
		}

		string? fID = isTagID ? null : feedID;
		bool onlyStarred = (whatToGet == ArticleStatus.MARKED);

		// The Feedbin API doesn't include read/unread/starred status in the entries.json
		var unreadIDs = new Gee.HashSet<string>();
		unreadIDs.add_all(m_api.unreadEntries());

		var starredIDs = new Gee.HashSet<string>();
		starredIDs.add_all(m_api.starredEntries());

		for(int page = 1; ; ++page)
		{
			if(cancellable != null && cancellable.is_cancelled())
				return;

			var articles = m_api.getEntries(page, onlyStarred, unreadIDs, starredIDs, time, fID);
			if(articles.size == 0)
				break;

			writeArticles(articles);
		}
	}
}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.FeedServerInterface), typeof(FeedReader.FeedbinInterface));
}
