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

public class FeedReader.ttrssInterface : Peas.ExtensionBase, FeedServerInterface {

	private ttrssAPI m_api;
	private ttrssUtils m_utils;

	public void init()
	{
		m_api = new ttrssAPI();
		m_utils = new ttrssUtils();
	}

	public bool supportTags()
	{
		return true;
	}

	public bool doInitSync()
	{
		return true;
	}

	public string symbolicIcon()
	{
		return "feed-service-ttrss-symbolic";
	}

	public string accountName()
	{
		return m_utils.getUser();
	}

	public string getServerURL()
	{
		return m_utils.getURL();
	}

	public string uncategorizedID()
	{
		return "0";
	}

	public bool hideCagetoryWhenEmtpy(string catID)
	{
		return catID == "0";
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
		return true;
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
		return m_api.logout();
	}

	public bool serverAvailable()
	{
		return m_api.ping();
	}

	public void setArticleIsRead(string articleIDs, ArticleStatus read)
	{
		m_api.updateArticleUnread(articleIDs, read);
	}

	public void setArticleIsMarked(string articleID, ArticleStatus marked)
	{
		m_api.updateArticleMarked(int.parse(articleID), marked);
	}

	public void setFeedRead(string feedID)
	{
		m_api.catchupFeed(feedID, false);
	}

	public void setCategorieRead(string catID)
	{
		m_api.catchupFeed(catID, true);
	}

	public void markAllItemsRead()
	{
		var categories = dbDaemon.get_default().read_categories();
		foreach(category cat in categories)
		{
			m_api.catchupFeed(cat.getCatID(), true);
		}
	}

	public void tagArticle(string articleID, string tagID)
	{
		m_api.setArticleLabel(int.parse(articleID), int.parse(tagID), true);
	}

	public void removeArticleTag(string articleID, string tagID)
	{
		m_api.setArticleLabel(int.parse(articleID), int.parse(tagID), false);
	}

	public string createTag(string caption)
	{
		return m_api.addLabel(caption).to_string();
	}

	public void deleteTag(string tagID)
	{
		m_api.removeLabel(int.parse(tagID));
	}

	public void renameTag(string tagID, string title)
	{
		m_api.renameLabel(int.parse(tagID), title);
	}

	public string addFeed(string feedURL, string? catID, string? newCatName)
	{
		if(catID == null && newCatName != null)
		{
			var newCatID = m_api.createCategory(newCatName);
			m_api.subscribeToFeed(feedURL, newCatID);
		}
		else
		{
			m_api.subscribeToFeed(feedURL, catID);
		}

		return (int.parse(dbDaemon.get_default().getHighestFeedID()) + 1).to_string();
	}

	public void addFeeds(Gee.LinkedList<feed> feeds)
	{
		foreach(feed f in feeds)
		{
			m_api.subscribeToFeed(f.getXmlUrl(), f.getCatIDs()[0]);
		}
	}

	public void removeFeed(string feedID)
	{
		m_api.unsubscribeFeed(int.parse(feedID));
	}

	public void renameFeed(string feedID, string title)
	{
		m_api.renameFeed(int.parse(feedID), title);
	}

	public void moveFeed(string feedID, string newCatID, string? currentCatID)
	{
		m_api.moveFeed(int.parse(feedID), int.parse(newCatID));
	}

	public string createCategory(string title, string? parentID)
	{
		if(parentID != null)
			return m_api.createCategory(title, int.parse(parentID));

		return m_api.createCategory(title);
	}

	public void renameCategory(string catID, string title)
	{
		m_api.renameCategory(int.parse(catID), title);
	}

	public void moveCategory(string catID, string newParentID)
	{
		m_api.moveCategory(int.parse(catID), int.parse(newParentID));
	}

	public void deleteCategory(string catID)
	{
		m_api.removeCategory(int.parse(catID));
	}

	public void removeCatFromFeed(string feedID, string catID)
	{
		return;
	}

	public void importOPML(string opml)
	{
		var parser = new OPMLparser(opml);
		parser.parse();
	}

	public bool getFeedsAndCats(Gee.LinkedList<feed> feeds, Gee.LinkedList<category> categories, Gee.LinkedList<tag> tags)
	{
		if(m_api.getCategories(categories)
		&& m_api.getFeeds(feeds, categories)
		&& m_api.getUncategorizedFeeds(feeds)
		&& m_api.getTags(tags))
			return true;

		return false;
	}

	public int getUnreadCount()
	{
		return m_api.getUnreadCount();
	}

	public void getArticles(int count, ArticleStatus whatToGet, string? feedID, bool isTagID)
	{
		var settings_general = new GLib.Settings("org.gnome.feedreader");

		// first use newsPlus plugin to update states of 10x as much articles as we would normaly do
		var unreadIDs = m_api.NewsPlus(ArticleStatus.UNREAD, 10*settings_general.get_int("max-articles"));
		if(unreadIDs != null && whatToGet == ArticleStatus.ALL)
		{
			Logger.debug("getArticles: newsplus plugin active");
			var markedIDs = m_api.NewsPlus(ArticleStatus.MARKED, settings_general.get_int("max-articles"));
			dbDaemon.get_default().updateArticlesByID(unreadIDs, "unread");
			dbDaemon.get_default().updateArticlesByID(markedIDs, "marked");
			updateArticleList();
		}

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
			m_api.getHeadlines(articles, skip, amount, whatToGet, (feedID == null) ? ttrssUtils.TTRSSSpecialID.ALL : int.parse(feedID));

			// only update article states if they haven't been updated by the newsPlus-plugin
			if(unreadIDs == null || whatToGet != ArticleStatus.ALL)
			{
				dbDaemon.get_default().update_articles(articles);
				updateArticleList();
			}

			foreach(article Article in articles)
			{
				if(!dbDaemon.get_default().article_exists(Article.getArticleID()))
				{
					articleIDs += Article.getArticleID() + ",";
				}
			}
		}

		if(articleIDs.length > 0)
			articleIDs = articleIDs.substring(0, articleIDs.length -1);

		var articles = new Gee.LinkedList<article>();

		if(articleIDs != "")
			m_api.getArticles(articleIDs, articles);

		articles.sort((a, b) => {
				return strcmp(a.getArticleID(), b.getArticleID());
		});


		if(articles.size > 0)
		{
			dbDaemon.get_default().write_articles(articles);
			updateFeedList();
			updateArticleList();
		}
	}

}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.FeedServerInterface), typeof(FeedReader.ttrssInterface));
}
