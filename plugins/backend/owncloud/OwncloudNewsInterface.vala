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

public class FeedReader.OwncloudNewsInterface : Peas.ExtensionBase, FeedServerInterface {

	private OwncloudNewsAPI m_api;
	private OwncloudNewsUtils m_utils;

	public dbDaemon m_dataBase { get; construct set; }
	public Logger m_logger { get; construct set; }

	public void init()
	{
		m_api = new OwncloudNewsAPI();
		m_utils = new OwncloudNewsUtils();
		dataBase = m_dataBase;
		logger = m_logger;
	}

	public bool supportTags()
	{
		return false;
	}

	public bool doInitSync()
	{
		return true;
	}

	public string? symbolicIcon()
	{
		return "feed-service-owncloud-symbolic";
	}

	public string? accountName()
	{
		return m_utils.getUser();
	}

	public string? getServerURL()
	{
		return m_utils.getURL();
	}

	public string uncategorizedID()
	{
		return "0";
	}

	public bool hideCagetoryWhenEmtpy(string cadID)
	{
		return false;
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
		return false;
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
		m_api.updateArticleUnread(articleIDs, read);
	}

	public void setArticleIsMarked(string articleID, ArticleStatus marked)
	{
		m_api.updateArticleMarked(articleID, marked);
	}

	public void setFeedRead(string feedID)
	{
		m_api.markFeedRead(feedID, false);
	}

	public void setCategorieRead(string catID)
	{
		m_api.markFeedRead(catID, true);
	}

	public void markAllItemsRead()
	{
		m_api.markAllItemsRead();
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
			string newCatID = m_api.addFolder(newCatName).to_string();
			return m_api.addFeed(feedURL, newCatID).to_string();
		}

		return m_api.addFeed(feedURL, catID).to_string();
	}

	public void removeFeed(string feedID)
	{
		m_api.removeFeed(feedID);
	}

	public void renameFeed(string feedID, string title)
	{
		m_api.renameFeed(feedID, title);
	}

	public void moveFeed(string feedID, string newCatID, string? currentCatID)
	{
		m_api.moveFeed(feedID, newCatID);
	}

	public string createCategory(string title, string? parentID)
	{
		return m_api.addFolder(title).to_string();
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
		m_api.removeFolder(catID);
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
		if(m_api.getFeeds(feeds)
		&& m_api.getCategories(categories, feeds))
			return true;

		return false;
	}

	public int getUnreadCount()
	{
		return (int)dataBase.get_unread_total();
	}

	public void getArticles(int count, ArticleStatus whatToGet, string? feedID, bool isTagID)
	{
		var type = OwncloudNewsAPI.OwnCloudType.ALL;
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
				type = OwncloudNewsAPI.OwnCloudType.STARRED;
				break;
		}

		if(feedID != null)
		{
			if(isTagID == true)
				return;

			id = int.parse(feedID);
			type = OwncloudNewsAPI.OwnCloudType.FEED;
		}

		var articles = new Gee.LinkedList<article>();

		if(count == -1)
			m_api.getNewArticles(articles, dataBase.getLastModified(), type, id);
		else
			m_api.getArticles(articles, 0, -1, read, type, id);

		writeArticlesInChunks(articles, 10);
	}
}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.FeedServerInterface), typeof(FeedReader.OwncloudNewsInterface));
}
