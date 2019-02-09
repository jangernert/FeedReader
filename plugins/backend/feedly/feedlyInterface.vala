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

public class FeedReader.feedlyInterface : FeedServerInterface {

private FeedlyAPI m_api;
private FeedlyUtils m_utils;

public override void init(GLib.SettingsBackend? settings_backend, Secret.Collection secrets)
{
	m_utils = new FeedlyUtils(settings_backend);
	m_api = new FeedlyAPI(m_utils);
}

public override string getWebsite()
{
	return "http://feedly.com/";
}

public override BackendFlags getFlags()
{
	return (BackendFlags.HOSTED | BackendFlags.PROPRIETARY | BackendFlags.PAID_PREMIUM);
}

public override string getID()
{
	return "feedly";
}

public override string iconName()
{
	return "feed-service-feedly";
}

public override string serviceName()
{
	return "feedly";
}

public override bool needWebLogin()
{
	return true;
}

public override Gtk.Box? getWidget()
{
	return null;
}

public override void showHtAccess()
{
	return;
}

public override void writeData()
{
	return;
}

public override async void postLoginAction()
{
	return;
}

public override bool extractCode(string redirectURL)
{
	if(redirectURL.has_prefix(FeedlySecret.apiRedirectUri))
	{
		int start = redirectURL.index_of("=")+1;
		int end = redirectURL.index_of("&");
		string code = redirectURL.substring(start, end-start);
		m_utils.setApiCode(code);
		Logger.debug("feedlyLoginWidget: set feedly-api-code: " + code);
		GLib.Thread.usleep(500000);
		return true;
	}

	return false;
}

public override string buildLoginURL()
{
	return FeedlySecret.base_uri + "/v3/auth/auth" + "?client_secret=" + FeedlySecret.apiClientSecret + "&client_id=" + FeedlySecret.apiClientId
	       + "&redirect_uri=" + FeedlySecret.apiRedirectUri + "&scope=" + FeedlySecret.apiAuthScope + "&response_type=code&state=getting_code";
}

public override bool supportTags()
{
	return true;
}

public override bool doInitSync()
{
	return true;
}

public override string symbolicIcon()
{
	return "feed-service-feedly-symbolic";
}

public override string accountName()
{
	return m_utils.getEmail();
}

public override string getServerURL()
{
	return "http://feedly.com/";
}

public override string uncategorizedID()
{
	return "";
}

public override bool hideCategoryWhenEmpty(string catID)
{
	return catID.has_suffix("global.must");
}

public override bool supportCategories()
{
	return true;
}

public override bool supportFeedManipulation()
{
	return true;
}

public override bool supportMultiLevelCategories()
{
	return false;
}

public override bool supportMultiCategoriesPerFeed()
{
	return true;
}

public override bool syncFeedsAndCategories()
{
	return true;
}

public override bool tagIDaffectedByNameChange()
{
	return false;
}

public override void resetAccount()
{
	m_utils.resetAccount();
}

public override bool useMaxArticles()
{
	return true;
}

public override LoginResponse login()
{
	return m_api.login();
}

public override bool logout()
{
	return true;
}

public override void setArticleIsRead(string articleIDs, ArticleStatus read)
{
	m_api.mark_as_read(articleIDs, "entries", read);
}

public override void setArticleIsMarked(string articleID, ArticleStatus marked)
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

public override bool alwaysSetReadByID()
{
	return false;
}

public override void setFeedRead(string feedID)
{
	m_api.mark_as_read(feedID, "feeds", ArticleStatus.READ);
}

public override void setCategoryRead(string catID)
{
	m_api.mark_as_read(catID, "categories", ArticleStatus.READ);
}

public override void markAllItemsRead()
{
	string catArray = "";
	string feedArray = "";

	var db = DataBase.readOnly();
	var categories = db.read_categories();
	var feeds = db.read_feeds_without_cat();

	foreach(Category cat in categories)
	{
		catArray += cat.getCatID() + ",";
	}

	foreach(Feed feed in feeds)
	{
		feedArray += feed.getFeedID() + ",";
	}

	m_api.mark_as_read(catArray.substring(0, catArray.length-1), "categories", ArticleStatus.READ);
	m_api.mark_as_read(feedArray.substring(0, feedArray.length-1), "feeds", ArticleStatus.READ);
}

public override void tagArticle(string articleID, string tagID)
{
	m_api.addArticleTag(articleID, tagID);
}

public override void removeArticleTag(string articleID, string tagID)
{
	m_api.deleteArticleTag(articleID, tagID);
}

public override string createTag(string caption)
{
	return m_api.createTag(caption);
}

public override void deleteTag(string tagID)
{
	m_api.deleteTag(tagID);
}

public override void renameTag(string tagID, string title)
{
	m_api.renameTag(tagID, title);
}

public override bool serverAvailable()
{
	return Utils.ping("http://feedly.com/");
}

public override bool addFeed(string feedURL, string? catID, string? newCatName, out string feedID, out string errmsg)
{
	feedID = "feed/" + feedURL;
	bool success = false;
	errmsg = "";

	if(catID == null && newCatName != null)
	{
		string newCatID = m_api.createCatID(newCatName);
		success = m_api.addSubscription(feedURL, null, newCatID);
	}
	else
	{
		success = m_api.addSubscription(feedURL, null, catID);
	}

	if(!success)
		errmsg = @"feedly could not add $feedURL";

	return success;
}

public override void addFeeds(Gee.List<Feed> feeds)
{
	foreach(Feed f in feeds)
	{
		m_api.addSubscription(f.getXmlUrl(), null, f.getCatIDs()[0]);
	}
}

public override void removeFeed(string feedID)
{
	m_api.removeSubscription(feedID);
}

public override void renameFeed(string feedID, string title)
{
	var feed = DataBase.readOnly().read_feed(feedID);
	m_api.addSubscription(feed.getFeedID(), title, feed.getCatString());
}

public override void moveFeed(string feedID, string newCatID, string? currentCatID )
{
	m_api.moveSubscription(feedID, newCatID, currentCatID);
}

public override string createCategory(string title, string? parentID)
{
	return m_api.createCatID(title);
}

public override void renameCategory(string catID, string title)
{
	m_api.renameCategory(catID, title);
}

public override void moveCategory(string catID, string newParentID)
{
	return;
}

public override void deleteCategory(string catID)
{
	m_api.removeCategory(catID);
}

public override void removeCatFromFeed(string feedID, string catID)
{
	var feed = DataBase.readOnly().read_feed(feedID);
	m_api.addSubscription(feed.getFeedID(), feed.getTitle(), feed.getCatString().replace(catID + ",", ""));
}

public override void importOPML(string opml)
{
	m_api.importOPML(opml);
}

public override bool getFeedsAndCats(Gee.List<Feed> feeds, Gee.List<Category> categories, Gee.List<Tag> tags, GLib.Cancellable? cancellable = null)
{
	m_api.getUnreadCounts();

	if(m_api.getCategories(categories))
	{
		if(cancellable != null && cancellable.is_cancelled())
			return false;

		if(m_api.getFeeds(feeds))
		{
			if(cancellable != null && cancellable.is_cancelled())
				return false;

			if(m_api.getTags(tags))
				return true;
		}
	}

	return false;
}

public override int getUnreadCount()
{
	return m_api.getTotalUnread();
}

public override void getArticles(int count, ArticleStatus whatToGet, DateTime? since, string? feedID, bool isTagID, GLib.Cancellable? cancellable = null)
{
	string continuation = null;
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
	var articles = new Gee.LinkedList<Article>();

	while(skip > 0)
	{
		if(cancellable != null && cancellable.is_cancelled())
			return;

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

		if(continuation == null)
			break;
	}

	writeArticles(articles);
}
}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.FeedServerInterface), typeof(FeedReader.feedlyInterface));
}
