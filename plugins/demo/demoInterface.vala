//--------------------------------------------------------------------------------------
// This is the plugin that extends the feedreader-daemon.
// It's job is to fetch all the categories, feeds, tags and articles from the server
// and write them to the data-base. And then notify the UI about the added content
//--------------------------------------------------------------------------------------

public class FeedReader.demoInterface : Peas.ExtensionBase, FeedServerInterface {

	//--------------------------------------------------------------------------------------
	// The dataBase object. Use it to gather information like current unread counts,
	// specific tags or if an article already exists.
	// It can also be used to write the content directly from the plugin.
	// But this is not necessary or recommended most of the time.
	//--------------------------------------------------------------------------------------
	public dbDaemon m_dataBase { get; construct set; }


	//--------------------------------------------------------------------------------------
	// The logger is used to output debug-information, warnings and errors to the
	// command line. All messages are also written to a log-file to make it easier
	// to trace back bugs when the daemon was not started from the shell.
	// Use like:
	// logger.print(LogMessage.DEBUG, "message");
	// Options are:
	// DEBUG, WARNING, INFO, ERROR
	//--------------------------------------------------------------------------------------
	public Logger m_logger { get; construct set; }


	//--------------------------------------------------------------------------------------
	// This method gets executed right after the plugin is loaded. Do everything
	// you need to set up the plugin here.
	//--------------------------------------------------------------------------------------
	public void init()
	{

	}


	//--------------------------------------------------------------------------------------
	// Does the service you are implementing support tags?
	// If so return "true", otherwise return "false".
	//--------------------------------------------------------------------------------------
	public bool supportTags()
	{

	}


	//--------------------------------------------------------------------------------------
	// What is the symbolic icon-name of the service-logo?
	// Return a string with the name, not the complete path.
	// For example: "feed-service-demo-symbolic"
	//--------------------------------------------------------------------------------------
	public string? symbolicIcon()
	{

	}


	//--------------------------------------------------------------------------------------
	// Return a name the account of the user can be identified with.
	// This can be the real name of the user, the email-address
	// or any other personal information that identifies the account.
	//--------------------------------------------------------------------------------------
	public string? accountName()
	{

	}


	//--------------------------------------------------------------------------------------
	// If the service can be self-hosted or has multiple providers
	// you can return the URL of the server here. Preferably without "http://www."
	//--------------------------------------------------------------------------------------
	public string? getServerURL()
	{

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

	}


	//--------------------------------------------------------------------------------------
	// Sone services have special categories that should not be visible when empty
	// e.g. feedly has a category called "Must Read".
	// Argument: ID of a category
	// Return: wheather the category should be visible when empty
	//--------------------------------------------------------------------------------------
	public bool hideCagetoryWhenEmtpy(string catID)
	{

	}


	//--------------------------------------------------------------------------------------
	// Does the service allow categories as children of other categories?
	// If so return "true", otherwise return "false".
	//--------------------------------------------------------------------------------------
	public bool supportMultiLevelCategories()
	{

	}


	//--------------------------------------------------------------------------------------
	// Can one feed be part of more than one category?
	// If so return "true", otherwise return "false".
	//--------------------------------------------------------------------------------------
	public bool supportMultiCategoriesPerFeed()
	{

	}


	//--------------------------------------------------------------------------------------
	// Does changing the name of a tag also change it's ID?
	// InoReader tagID's for example look like this:
	// "user/1005921515/label/tagName"
	// So if the name changes the ID changes accordingly. This needs special treatment.
	// Return "true" if this is the case, otherwise return "false".
	//--------------------------------------------------------------------------------------
	public bool tagIDaffectedByNameChange()
	{

	}


	//--------------------------------------------------------------------------------------
	// Delete all passwords, keys and user-information.
	// Do not delete feeds or articles from the data-base.
	//--------------------------------------------------------------------------------------
	public void resetAccount()
	{

	}


	//--------------------------------------------------------------------------------------
	// State wheater the service syncs articles based on a maximum count
	// or uses something else (OwnCloud uses the last synced articleID)
	//--------------------------------------------------------------------------------------
	public bool useMaxArticles()
	{

	}

	//--------------------------------------------------------------------------------------
	// Log in to the account of the service. If there is no need or API to sign in,
	// check all passwords or keys and make sure the service is reachable and works.
	// Possible return values are:
	// - SUCCESS
	// - MISSING_USER
	// - MISSING_PASSWD
	// - MISSING_URL
	// - ALL_EMPTY
	// - UNKNOWN_ERROR
	// - FIRST_TRY
	// - NO_BACKEND
	// - WRONG_LOGIN
	// - NO_CONNECTION
	// - NO_API_ACCESS
	// - UNAUTHORIZED
	// - CA_ERROR
	// - PLUGIN_NEEDED
	//--------------------------------------------------------------------------------------
	public LoginResponse login()
	{

	}


	//--------------------------------------------------------------------------------------
	// If it is possible to log out of the account of the service, do so here.
	// If not, do nothing and return "true".
	//--------------------------------------------------------------------------------------
	public bool logout()
	{

	}


	//--------------------------------------------------------------------------------------
	// Check if the service is reachable.
	// You can use the method Utils.ping() if the service doesn't provide anything.
	//--------------------------------------------------------------------------------------
	public bool serverAvailable()
	{

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

	}


	//--------------------------------------------------------------------------------------
	// Remove the feed with the id "feedID" completely
	//--------------------------------------------------------------------------------------
	public void removeFeed(string feedID)
	{

	}

	public void renameFeed(string feedID, string title)
	{

	}

	public void moveFeed(string feedID, string newCatID, string? currentCatID)
	{

	}

	public string createCategory(string title, string? parentID)
	{

	}

	public void renameCategory(string catID, string title)
	{

	}

	public void moveCategory(string catID, string newParentID)
	{

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

	public void getFeedsAndCats(Gee.LinkedList<feed> feeds, Gee.LinkedList<category> categories, Gee.LinkedList<tag> tags)
	{

	}

	public int getUnreadCount()
	{

	}

	public void getArticles(int count, ArticleStatus whatToGet, string? feedID, bool isTagID)
	{

	}

}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.FeedServerInterface), typeof(FeedReader.demoInterface));
}
