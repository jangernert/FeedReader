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

public class FeedReader.FeedHQInterface : Peas.ExtensionBase, FeedServerInterface {

	private FeedHQAPI m_api;
	private FeedHQUtils m_utils;

	public void init()
	{
		m_api = new FeedHQAPI();
		m_utils = new FeedHQUtils();
	}

	public bool supportTags()
	{
		return false;
	}

	public bool supportFeedManipulation()
	{
		return true;
	}

	public bool doInitSync()
	{
		return true;
	}

	public string symbolicIcon()
	{
		return "feed-service-feedhq-symbolic";
	}

	public string accountName()
	{
		return m_utils.getUser();
	}

	public string getServerURL()
	{
		return "FeedHQ.org";
	}

	public string uncategorizedID()
	{
		return "";
	}

	public bool supportCategories()
	{
		return true;
	}

	public bool hideCategoryWhenEmpty(string cadID)
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
		return true;
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

	public void setArticleIsRead(string articleIDs, ArticleStatus read)
	{
		if(read == ArticleStatus.READ)
			m_api.edidTag(articleIDs, "user/-/state/com.google/read");
		else
			m_api.edidTag(articleIDs, "user/-/state/com.google/read", false);
	}

	public void setArticleIsMarked(string articleID, ArticleStatus marked)
	{
		if(marked == ArticleStatus.MARKED)
			m_api.edidTag(articleID, "user/-/state/com.google/starred");
		else
			m_api.edidTag(articleID, "user/-/state/com.google/starred", false);
	}

	public void setFeedRead(string feedID)
	{
		m_api.markAsRead(feedID);
	}

	public void setCategoryRead(string catID)
	{
		m_api.markAsRead(catID);
	}

	public void markAllItemsRead()
	{
		var categories = dbDaemon.get_default().read_categories();
		foreach(category cat in categories)
		{
			m_api.markAsRead(cat.getCatID());
		}

		var feeds = dbDaemon.get_default().read_feeds_without_cat();
		foreach(feed Feed in feeds)
		{
			m_api.markAsRead(Feed.getFeedID());
		}
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
		return ":(";
	}

	public void deleteTag(string tagID)
	{
		return;
	}

	public void renameTag(string tagID, string title)
	{
		return;
	}

	public bool serverAvailable()
	{
		return m_api.ping();
	}

	public string addFeed(string feedURL, string? catID, string? newCatName)
	{
		if(catID == null && newCatName != null)
		{
			string newCatID = m_api.composeTagID(newCatName);
			Logger.debug(newCatID);
			m_api.editSubscription(FeedHQAPI.FeedHQSubscriptionAction.SUBSCRIBE, {"feed/"+feedURL}, null, newCatID);
		}
		else
		{
			m_api.editSubscription(FeedHQAPI.FeedHQSubscriptionAction.SUBSCRIBE, {"feed/"+feedURL}, null, catID);
		}
		return "feed/" + feedURL;
	}

	public void addFeeds(Gee.List<feed> feeds)
	{
		return;
	}

	public void removeFeed(string feedID)
	{
		m_api.editSubscription(FeedHQAPI.FeedHQSubscriptionAction.UNSUBSCRIBE, {feedID});
	}

	public void renameFeed(string feedID, string title)
	{
		m_api.editSubscription(FeedHQAPI.FeedHQSubscriptionAction.EDIT, {feedID}, title);
	}

	public void moveFeed(string feedID, string newCatID, string? currentCatID)
	{
		m_api.editSubscription(FeedHQAPI.FeedHQSubscriptionAction.EDIT, {feedID}, null, newCatID, currentCatID);
	}

	public string createCategory(string title, string? parentID)
	{
		return m_api.composeTagID(title);
	}

	public void renameCategory(string catID, string title)
	{
		m_api.renameTag(catID, title);
	}

	public void moveCategory(string catID, string newParentID)
	{
		return;
	}

	public void deleteCategory(string catID)
	{
		m_api.deleteTag(catID);
	}

	public void removeCatFromFeed(string feedID, string catID)
	{
		return;
	}

	public void importOPML(string opml)
	{
		m_api.import(opml);
	}

	public bool getFeedsAndCats(Gee.List<feed> feeds, Gee.List<category> categories, Gee.List<tag> tags, GLib.Cancellable? cancellable = null)
	{
		if(m_api.getFeeds(feeds))
		{
			if(cancellable != null && cancellable.is_cancelled())
				return false;

			if(m_api.getCategoriesAndTags(feeds, categories, tags))
				return true;
		}

		return false;
	}

	public int getUnreadCount()
	{
		return m_api.getTotalUnread();
	}

	public void getArticles(int count, ArticleStatus whatToGet, string? feedID, bool isTagID, GLib.Cancellable? cancellable = null)
	{
		if(whatToGet == ArticleStatus.READ)
		{
			return;
		}
		else if(whatToGet == ArticleStatus.ALL)
		{
			var unreadIDs = new Gee.LinkedList<string>();
			string? continuation = null;

			do
			{
				if(cancellable != null && cancellable.is_cancelled())
					return;

				continuation = m_api.updateArticles(unreadIDs, 1000, continuation);
			}
			while(continuation != null);
			dbDaemon.get_default().updateArticlesByID(unreadIDs, "unread");
		}

		var articles = new Gee.LinkedList<article>();
		string? continuation = null;
		string? FeedHQ_feedID = (isTagID) ? null : feedID;
		string? FeedHQ_tagID = (isTagID) ? feedID : null;

		do
		{
			if(cancellable != null && cancellable.is_cancelled())
				return;

			continuation = m_api.getArticles(articles, count, whatToGet, continuation, FeedHQ_tagID, FeedHQ_feedID);
		}
		while(continuation != null);

		writeArticles(articles);
	}

}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.FeedServerInterface), typeof(FeedReader.FeedHQInterface));
}
