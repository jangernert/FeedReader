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

public class FeedReader.feedlyInterface : Peas.ExtensionBase, FeedServerInterface {

	private FeedlyAPI m_api;
	private FeedlyUtils m_utils;

	public void init()
	{
		m_api = new FeedlyAPI();
		m_utils = new FeedlyUtils();
	}

	public bool supportTags()
	{
		return true;
	}

	public bool doInitSync()
	{
		return true;
	}

	public string? symbolicIcon()
	{
		return "feed-service-feedly-symbolic";
	}

	public string? accountName()
	{
		return m_utils.getEmail();
	}

	public string? getServerURL()
	{
		return "http://feedly.com/";
	}

	public string uncategorizedID()
	{
		return "";
	}

	public bool hideCagetoryWhenEmtpy(string catID)
	{
		return catID.has_suffix("global.must");
	}

	public bool supportCategories()
	{
		return true;
	}

	public bool supportFeedManipulation()
	{
		return true;
	}

	public bool supportMultiLevelCategories()
	{
		return false;
	}

	public bool supportMultiCategoriesPerFeed()
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

	public void setArticleIsRead(string articleIDs, ArticleStatus read)
	{
		m_api.mark_as_read(articleIDs, "entries", read);
	}

	public void setArticleIsMarked(string articleID, ArticleStatus marked)
	{
		if(marked == ArticleStatus.MARKED)
		{
			m_api.addArticleTag(articleID, m_api.getMarkedID());
		}
		else if(marked == ArticleStatus.UNMARKED)
		{
			m_api.deleteArticleTag(articleID, m_api.getMarkedID());
		}
	}

	public void setFeedRead(string feedID)
	{
		m_api.mark_as_read(feedID, "feeds", ArticleStatus.READ);
	}

	public void setCategorieRead(string catID)
	{
		m_api.mark_as_read(catID, "categories", ArticleStatus.READ);
	}

	public void markAllItemsRead()
	{
		string catArray = "";
		string feedArray = "";

		var categories = dbDaemon.get_default().read_categories();
		var feeds = dbDaemon.get_default().read_feeds_without_cat();

		foreach(category cat in categories)
		{
			catArray += cat.getCatID() + ",";
		}

		foreach(feed Feed in feeds)
		{
			feedArray += Feed.getFeedID() + ",";
		}

		m_api.mark_as_read(catArray.substring(0, catArray.length-1), "categories", ArticleStatus.READ);
		m_api.mark_as_read(feedArray.substring(0, feedArray.length-1), "feeds", ArticleStatus.READ);
	}

	public void tagArticle(string articleID, string tagID)
	{
		m_api.addArticleTag(articleID, tagID);
	}

	public void removeArticleTag(string articleID, string tagID)
	{
		m_api.deleteArticleTag(articleID, tagID);
	}

	public string createTag(string caption)
	{
		return m_api.createTag(caption);
	}

	public void deleteTag(string tagID)
	{
		m_api.deleteTag(tagID);
	}

	public void renameTag(string tagID, string title)
	{
		m_api.renameTag(tagID, title);
	}

	public bool serverAvailable()
	{
		return Utils.ping("http://feedly.com/");
	}

	public string addFeed(string feedURL, string? catID, string? newCatName)
	{
		if(catID == null && newCatName != null)
		{
			string newCatID = m_api.createCatID(newCatName);
			m_api.addSubscription(feedURL, null, newCatID);
		}
		else
		{
			m_api.addSubscription(feedURL, null, catID);
		}

		return "feed/" + feedURL;
	}

	public void removeFeed(string feedID)
	{
		m_api.removeSubscription(feedID);
	}

	public void renameFeed(string feedID, string title)
	{
		var feed = dbDaemon.get_default().read_feed(feedID);
		m_api.addSubscription(feed.getFeedID(), title, feed.getCatString());
	}

	public void moveFeed(string feedID, string newCatID, string? currentCatID )
	{
		m_api.moveSubscription(feedID, newCatID, currentCatID);
	}

	public string createCategory(string title, string? parentID)
	{
		return m_api.createCatID(title);
	}

	public void renameCategory(string catID, string title)
	{
		m_api.renameCategory(catID, title);
	}

	public void moveCategory(string catID, string newParentID)
	{
		return;
	}

	public void deleteCategory(string catID)
	{
		m_api.removeCategory(catID);
	}

	public void removeCatFromFeed(string feedID, string catID)
	{
		var feed = dbDaemon.get_default().read_feed(feedID);
		m_api.addSubscription(feed.getFeedID(), feed.getTitle(), feed.getCatString().replace(catID + ",", ""));
	}

	public void importOPML(string opml)
	{
		m_api.importOPML(opml);
	}

	public bool getFeedsAndCats(Gee.LinkedList<feed> feeds, Gee.LinkedList<category> categories, Gee.LinkedList<tag> tags)
	{
		m_api.getUnreadCounts();

		if(m_api.getCategories(categories)
		&& m_api.getFeeds(feeds)
		&& m_api.getTags(tags))
			return true;

		return false;
	}

	public int getUnreadCount()
	{
		return m_api.getTotalUnread();
	}

	public void getArticles(int count, ArticleStatus whatToGet, string? feedID, bool isTagID)
	{
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

			continuation = m_api.getArticles(articles, amount, continuation, whatToGet, feedly_tagID, feedly_feedID);

			if(continuation == "")
				break;
		}

		writeArticlesInChunks(articles, 10);
	}
}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.FeedServerInterface), typeof(FeedReader.feedlyInterface));
}
