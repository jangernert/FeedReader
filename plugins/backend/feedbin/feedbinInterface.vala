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

public class FeedReader.feedbinInterface : Peas.ExtensionBase, FeedServerInterface {

	private feedbinAPI m_api;
	private feedbinUtils m_utils;

	public void init()
	{
		m_api = new feedbinAPI();
		m_utils = new feedbinUtils();
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
		var articleIDs = new Gee.ArrayList<string>.wrap(new string[] { articleID });
		if(read == ArticleStatus.UNREAD)
			m_api.createUnreadEntries(articleIDs, false);
		else if(read == ArticleStatus.READ)
			m_api.createUnreadEntries(articleIDs, true);
	}

	public void setArticleIsMarked(string articleID, ArticleStatus marked)
	{
		var articleIDs = new Gee.ArrayList<string>.wrap(new string[] { articleID });
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

			FuncUtils.MapFunction<article, string> articleToID = (article) => { return article.getArticleID(); };
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

	public string addFeed(string feedURL, string? catID, string? newCatName)
	{
		return "";
	}

	public void addFeeds(Gee.List<feed> feeds)
	{
		return;
	}

	public void removeFeed(string feedID)
	{
		//m_api.deleteFeed(feedID);
	}

	public void renameFeed(string feedID, string title)
	{
		//m_api.renameFeed(feedID, title);
	}

	public void moveFeed(string feedID, string newCatID, string? currentCatID)
	{

	}

	public string createCategory(string title, string? parentID)
	{
		return "";
	}

	public void renameCategory(string catID, string title)
	{

	}

	public void moveCategory(string catID, string newParentID)
	{
		return;
	}

	public void deleteCategory(string catID)
	{

	}

	public void removeCatFromFeed(string feedID, string catID)
	{

	}

	public void importOPML(string opml)
	{

	}

	public bool getFeedsAndCats(Gee.List<feed> feeds, Gee.List<category> categories, Gee.List<tag> tags, GLib.Cancellable? cancellable = null)
	{
		if(m_api.getSubscriptionList(feeds))
		{
			if(cancellable != null && cancellable.is_cancelled())
				return false;

			if(m_api.getTaggings(categories, feeds))
				return true;
		}

		return false;
	}

	public int getUnreadCount()
	{
		return 0; // =( feedbin
	}

	public void getArticles(int count, ArticleStatus whatToGet, string? feedID, bool isTagID, GLib.Cancellable? cancellable = null)
	{
		if(whatToGet == ArticleStatus.READ)
		{
			return;
		}

		var settings_state = new GLib.Settings("org.gnome.feedreader.saved-state");
		DateTime? time = null;
		if(!dbDaemon.get_default().isTableEmpty("articles"))
			time = new DateTime.from_unix_utc(settings_state.get_int("last-sync"));

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
	objmodule.register_extension_type(typeof(FeedReader.FeedServerInterface), typeof(FeedReader.feedbinInterface));
}
