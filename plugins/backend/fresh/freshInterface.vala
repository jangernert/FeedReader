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


	//--------------------------------------------------------------------------------------
	// Many services have different ways of telling if a feed is uncategorized.
	// OwnCloud-News and Tiny Tiny RSS use the id "0", while feedly and InoReader
	// use an empty string ("").
	// Return what this service uses to indicate that the feed does not belong
	// to any category.
	//--------------------------------------------------------------------------------------
	public string uncategorizedID()
	{
		return "";
	}


	//--------------------------------------------------------------------------------------
	// Sone services have special categories that should not be visible when empty
	// e.g. feedly has a category called "Must Read".
	// Argument: ID of a category
	// Return: wheather the category should be visible when empty
	//--------------------------------------------------------------------------------------
	public bool hideCagetoryWhenEmtpy(string catID)
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


	//--------------------------------------------------------------------------------------
	// Delete all passwords, keys and user-information.
	// Do not delete feeds or articles from the data-base.
	//--------------------------------------------------------------------------------------
	public void resetAccount()
	{

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


	//--------------------------------------------------------------------------------------
	// Check if the service is reachable.
	// You can use the method Utils.ping() if the service doesn't provide anything.
	//--------------------------------------------------------------------------------------
	public bool serverAvailable()
	{
		return Utils.ping(m_utils.getUnmodifiedURL());
	}


	//--------------------------------------------------------------------------------------
	// Method to set the state of articles to read or unread
	// "articleIDs": comma separated string of articleIDs e.g. "id1,id2,id3"
	// "read": the state to apply. ArticleStatus.READ or ArticleStatus.UNREAD
	//--------------------------------------------------------------------------------------
	public void setArticleIsRead(string articleIDs, ArticleStatus read)
	{

	}


	//--------------------------------------------------------------------------------------
	// Method to set the state of articles to marked or unmarked
	// "articleID": single articleID
	// "read": the state to apply. ArticleStatus.MARKED or ArticleStatus.UNMARKED
	//--------------------------------------------------------------------------------------
	public void setArticleIsMarked(string articleID, ArticleStatus marked)
	{

	}


	//--------------------------------------------------------------------------------------
	// Mark all articles of the feed as read
	//--------------------------------------------------------------------------------------
	public void setFeedRead(string feedID)
	{

	}


	//--------------------------------------------------------------------------------------
	// Mark all articles of the feeds that are part of the category as read
	//--------------------------------------------------------------------------------------
	public void setCategorieRead(string catID)
	{

	}


	//--------------------------------------------------------------------------------------
	// Mark ALL articles as read
	//--------------------------------------------------------------------------------------
	public void markAllItemsRead()
	{

	}


	//--------------------------------------------------------------------------------------
	// Add an existing tag to the article
	//--------------------------------------------------------------------------------------
	public void tagArticle(string articleID, string tagID)
	{

	}


	//--------------------------------------------------------------------------------------
	// Remove an existing tag from the article
	//--------------------------------------------------------------------------------------
	public void removeArticleTag(string articleID, string tagID)
	{

	}


	//--------------------------------------------------------------------------------------
	// Create a new tag with the title of "caption" and return the id of the
	// newly added tag.
	// Hint: some services don't have API to create tags, but instead create them
	// on the fly when tagging articles. In this case just compose the tagID
	// following the schema tha service uses and return it.
	//--------------------------------------------------------------------------------------
	public string createTag(string caption)
	{
		return "";
	}


	//--------------------------------------------------------------------------------------
	// Delete a tag completely
	//--------------------------------------------------------------------------------------
	public void deleteTag(string tagID)
	{

	}


	//--------------------------------------------------------------------------------------
	// Rename the tag with the id "tagID" to the new name "title"
	//--------------------------------------------------------------------------------------
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


	//--------------------------------------------------------------------------------------
	// Get all feeds, categories and tags from the service
	// Fill up the emtpy LinkedList's that are provided with instances of the
	// model-classes category, feed and article
	//--------------------------------------------------------------------------------------
	public void getFeedsAndCats(Gee.LinkedList<feed> feeds, Gee.LinkedList<category> categories, Gee.LinkedList<tag> tags)
	{

	}


	//--------------------------------------------------------------------------------------
	// Return the total count of unread articles on the server
	//--------------------------------------------------------------------------------------
	public int getUnreadCount()
	{
		return 0;
	}


	//--------------------------------------------------------------------------------------
	// Get the requested articles and write them to the data-base
	//
	// "count":		the number of articles to get
	// "whatToGet":	the kind of articles to get (all/unread/marked/etc.)
	// "feedID":	get only articles of a secific feed or tag
	// "isTagID":	false if "feedID" is a feed-ID, true if "feedID" is a tag-ID
	//
	// It is recommended after getting the articles from the server to use the signal
	// "writeArticlesInChunks(Gee.LinkedList<article> articles, int chunksize)"
	// to automatically process them in the content-grabber, write them to the
	// data-base and send all the signals to the UI to update accordingly.
	// But if the API suggests a different approach you can everything on your
	// own (see ttrss-backend).
	//--------------------------------------------------------------------------------------
	public void getArticles(int count, ArticleStatus whatToGet, string? feedID, bool isTagID)
	{

	}

}


//--------------------------------------------------------------------------------------
// Boilerplate code for the plugin. Replace "demoInterface" with the name
// of your interface-class.
//--------------------------------------------------------------------------------------
[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.FeedServerInterface), typeof(FeedReader.freshInterface));
}
