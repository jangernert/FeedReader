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

public class FeedReader.freshInterface : Peas.ExtensionBase, FeedServerInterface {

	private freshAPI m_api;
	private freshUtils m_utils;

	public dbDaemon m_dataBase { get; construct set; }
	public Logger m_logger { get; construct set; }

	public void init()
	{
		m_api = new freshAPI();
		m_utils = new freshUtils();
		logger = m_logger;
		dataBase = m_dataBase;
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
		return "feed-service-fresh-symbolic";
	}

	public string? accountName()
	{
		return m_utils.getUser();
	}

	public string? getServerURL()
	{
		return m_utils.getUnmodifiedURL();
	}

	public string uncategorizedID()
	{
		return "1";
	}

	public bool hideCagetoryWhenEmtpy(string catID)
	{
		return false;
	}

	public bool supportCategories()
	{
		return true;
	}

	public bool supportFeedManipulation()
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

	public bool serverAvailable()
	{
		return Utils.ping(m_utils.getUnmodifiedURL());
	}

	public void setArticleIsRead(string articleIDs, ArticleStatus read)
	{
		if(read == ArticleStatus.READ)
			m_api.editTags(articleIDs, "user/-/state/com.google/read", null);
		else
			m_api.editTags(articleIDs, null, "user/-/state/com.google/read");
	}

	public void setArticleIsMarked(string articleID, ArticleStatus marked)
	{
		if(marked == ArticleStatus.MARKED)
			m_api.editTags(articleID, "user/-/state/com.google/starred", null);
		else
			m_api.editTags(articleID, null, "user/-/state/com.google/starred");
	}

	public void setFeedRead(string feedID)
	{
		m_api.markAllAsRead(feedID);
	}

	public void setCategorieRead(string catID)
	{
		m_api.markAllAsRead(catID);
	}

	public void markAllItemsRead()
	{
		m_api.markAllAsRead("user/-/state/com.google/reading-list");
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

	}

	public void renameTag(string tagID, string title)
	{

	}


	//--------------------------------------------------------------------------------------
	// Subscribe to the URL "feedURL"
	// "catID": the category the feed should be placed into, "null" otherwise
	// "newCatName": the name of a new category the feed should be put in, "null" otherwise
	//--------------------------------------------------------------------------------------
	public string addFeed(string feedURL, string? catID, string? newCatName)
	{
		return "";
	}


	//--------------------------------------------------------------------------------------
	// Remove the feed with the id "feedID" completely
	//--------------------------------------------------------------------------------------
	public void removeFeed(string feedID)
	{

	}


	//--------------------------------------------------------------------------------------
	// Rename the feed with the id "feedID" to "title"
	//--------------------------------------------------------------------------------------
	public void renameFeed(string feedID, string title)
	{

	}


	//--------------------------------------------------------------------------------------
	// Move the feed with the id "feedID" from its current category
	// to any other category. "currentCatID" is only needed if the
	// feed can be part of multiple categories at once.
	//--------------------------------------------------------------------------------------
	public void moveFeed(string feedID, string newCatID, string? currentCatID)
	{

	}


	//--------------------------------------------------------------------------------------
	// Create a new category
	// "title": title of the new category
	// "parentID": only needed if multi-level-categories are supported
	// Hint: some services don't have API to create categories, but instead create them
	// on the fly when movin feeds over to them. In this case just compose the categoryID
	// following the schema tha service uses and return it.
	//--------------------------------------------------------------------------------------
	public string createCategory(string title, string? parentID)
	{
		return "";
	}


	//--------------------------------------------------------------------------------------
	// Rename the category with the id "catID" to "title"
	//--------------------------------------------------------------------------------------
	public void renameCategory(string catID, string title)
	{

	}


	//--------------------------------------------------------------------------------------
	// Move the category with the id "catID" into another category
	// with the id "newParentID"
	// This method is only used if multi-level-categories are supported
	//--------------------------------------------------------------------------------------
	public void moveCategory(string catID, string newParentID)
	{

	}


	//--------------------------------------------------------------------------------------
	// Delete the category with the id "catID"
	//--------------------------------------------------------------------------------------
	public void deleteCategory(string catID)
	{

	}


	//--------------------------------------------------------------------------------------
	// Rename the feed with the id "feedID" from the category with the id "catID"
	// Don't delete the feed entirely, just remove it from the category.
	// Only useful if feed can be part of multiple categories.
	//--------------------------------------------------------------------------------------
	public void removeCatFromFeed(string feedID, string catID)
	{

	}


	//--------------------------------------------------------------------------------------
	// Import the content of "opml"
	// If the service doesn't provide API to import OPML you can use the
	// OPMLparser-class
	//--------------------------------------------------------------------------------------
	public void importOPML(string opml)
	{

	}

	public bool getFeedsAndCats(Gee.LinkedList<feed> feeds, Gee.LinkedList<category> categories, Gee.LinkedList<tag> tags)
	{
		if(m_api.getSubscriptionList(feeds)
		&& m_api.getTagList(categories))
			return true;

		return false;
	}

	public int getUnreadCount()
	{
		return m_api.getUnreadCounts();
	}

	public void getArticles(int count, ArticleStatus whatToGet, string? feedID, bool isTagID)
	{
		if(whatToGet == ArticleStatus.READ)
		{
			return;
		}

		var articles = new Gee.LinkedList<article>();
		string? continuation = null;
		string? exclude = null;
		string? labelID = null;
		int left = count;
		if(whatToGet == ArticleStatus.ALL)
		{
			labelID = "user/-/state/com.google/reading-list";
		}
		else if(whatToGet == ArticleStatus.MARKED)
		{
			labelID = "user/-/state/com.google/starred";
		}
		else if(whatToGet == ArticleStatus.UNREAD)
		{
			labelID = "user/-/state/com.google/reading-list";
			exclude = "user/-/state/com.google/read";
		}


		while(left > 0)
		{
			if(left > 1000)
			{
				continuation = m_api.getStreamContents(articles, null, labelID, exclude, 1000, "d");
				left -= 1000;
			}
			else
			{
				continuation = m_api.getStreamContents(articles, null, labelID, exclude, left, "d");
				left = 0;
			}
		}
		writeArticlesInChunks(articles, 10);
	}

}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.FeedServerInterface), typeof(FeedReader.freshInterface));
}
