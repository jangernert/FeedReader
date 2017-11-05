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

public class FeedReader.InoReaderInterface : Peas.ExtensionBase, FeedServerInterface {

	private InoReaderAPI m_api;
	private InoReaderUtils m_utils;

	public void init(GLib.SettingsBackend settings_backend)
	{
		m_utils = new InoReaderUtils(settings_backend);
		m_api = new InoReaderAPI(m_utils);
	}

	public string getWebsite()
	{
		return "http://www.inoreader.com/";
	}

	public BackendFlags getFlags()
	{
		return (BackendFlags.HOSTED | BackendFlags.PROPRIETARY | BackendFlags.PAID_PREMIUM);
	}

	public string getID()
	{
		return "inoreader";
	}

	public string iconName()
	{
		return "feed-service-inoreader";
	}

	public string serviceName()
	{
		return "InoReader";
	}

	public void writeData()
	{
		return;
	}

	public async void postLoginAction()
	{
		return;
	}

	public bool extractCode(string redirectURL)
	{
		if(redirectURL.has_prefix(InoReaderSecret.apiRedirectUri))
		{
			Logger.debug(redirectURL);
			int csrf_start = redirectURL.index_of("state=")+6;
			string csrf_code = redirectURL.substring(csrf_start);
			Logger.debug("InoReaderLoginWidget: csrf_code: " + csrf_code);

			if(csrf_code == InoReaderSecret.csrf_protection)
			{
				int start = redirectURL.index_of("code=")+5;
				int end = redirectURL.index_of("&", start);
				string code = redirectURL.substring(start, end-start);
				m_utils.setApiCode(code);
				Logger.debug("InoReaderLoginWidget: set inoreader-api-code: " + code);
				GLib.Thread.usleep(500000);
				return true;
			}

			Logger.error("InoReaderLoginWidget: csrf_code mismatch");
		}
		else
		{
			Logger.warning("InoReaderLoginWidget: wrong redirect_uri");
		}

		return false;
	}

	public string buildLoginURL()
	{
		return "https://www.inoreader.com/oauth2/auth"
			+ "?client_id=" + InoReaderSecret.apiClientId
			+ "&redirect_uri=" + InoReaderSecret.apiRedirectUri
			+ "&response_type=code"
			+ "&scope=read+write"
			+ "&state=" + InoReaderSecret.csrf_protection;
	}

	public bool needWebLogin()
	{
		return true;
	}

	public Gtk.Box? getWidget()
	{
		return null;
	}

	public void showHtAccess()
	{
		return;
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
		return "feed-service-inoreader-symbolic";
	}

	public string accountName()
	{
		return m_utils.getUser();
	}

	public string getServerURL()
	{
		return "http://www.inoreader.com/";
	}

	public string uncategorizedID()
	{
		return "";
	}

	public bool hideCategoryWhenEmpty(string cadID)
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
		return true;
	}

	public bool syncFeedsAndCategories()
	{
		return true;
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
		var categories = DataBase.readOnly().read_categories();
		foreach(Category cat in categories)
		{
			m_api.markAsRead(cat.getCatID());
		}

		var feeds = DataBase.readOnly().read_feeds_without_cat();
		foreach(Feed feed in feeds)
		{
			m_api.markAsRead(feed.getFeedID());
		}
		m_api.markAsRead();
	}

	public void tagArticle(string articleID, string tagID)
	{
		m_api.edidTag(articleID, tagID, true);
	}

	public void removeArticleTag(string articleID, string tagID)
	{
		m_api.edidTag(articleID, tagID, false);
	}

	public string createTag(string caption)
	{
		return m_api.composeTagID(caption);
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
		return m_api.ping();
	}

	public bool addFeed(string feedURL, string? catID, string? newCatName, out string feedID, out string errmsg)
	{
		bool success = false;
		feedID = "feed/" + feedURL;
		errmsg = "";

		if(catID == null && newCatName != null)
		{
			string newCatID = m_api.composeTagID(newCatName);
			success = m_api.editSubscription(InoReaderAPI.InoSubscriptionAction.SUBSCRIBE, {"feed/"+feedURL}, null, newCatID, null);
		}
		else
		{
			success = m_api.editSubscription(InoReaderAPI.InoSubscriptionAction.SUBSCRIBE, {"feed/"+feedURL}, null, catID, null);
		}

		if(!success)
			errmsg = "Inoreader could not add %s";

		return success;
	}

	public void addFeeds(Gee.List<Feed> feeds)
	{
		string cat = "";
		string[] urls = {};

		foreach(Feed f in feeds)
		{
			if(f.getCatIDs()[0] != cat)
			{
				m_api.editSubscription(InoReaderAPI.InoSubscriptionAction.SUBSCRIBE, urls, null, cat, null);
				urls = {};
				cat = f.getCatIDs()[0];
			}

			urls += "feed/" + f.getXmlUrl();
		}

		m_api.editSubscription(InoReaderAPI.InoSubscriptionAction.SUBSCRIBE, urls, null, cat, null);
	}

	public void removeFeed(string feedID)
	{
		m_api.editSubscription(InoReaderAPI.InoSubscriptionAction.UNSUBSCRIBE, {feedID}, null, null, null);
	}

	public void renameFeed(string feedID, string title)
	{
		m_api.editSubscription(InoReaderAPI.InoSubscriptionAction.EDIT, {feedID}, title, null, null);
	}

	public void moveFeed(string feedID, string newCatID, string? currentCatID)
	{
		m_api.editSubscription(InoReaderAPI.InoSubscriptionAction.EDIT, {feedID}, null, newCatID, currentCatID);
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
		var parser = new OPMLparser(opml);
		parser.parse();
	}

	public bool getFeedsAndCats(Gee.List<Feed> feeds, Gee.List<Category> categories, Gee.List<Tag> tags, GLib.Cancellable? cancellable = null)
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

	public void getArticles(int count, ArticleStatus whatToGet, DateTime? since, string? feedID, bool isTagID, GLib.Cancellable? cancellable = null)
	{
		if(whatToGet == ArticleStatus.READ)
		{
			return;
		}
		else if(whatToGet == ArticleStatus.ALL)
		{
			var unreadIDs = new Gee.LinkedList<string>();
			string? continuation = null;
			int left = 4*count;

			while(left > 0)
			{
				if(cancellable != null && cancellable.is_cancelled())
					return;

				if(left > 1000)
				{
					continuation = m_api.updateArticles(unreadIDs, 1000, continuation);
					left -= 1000;
				}
				else
				{
					m_api.updateArticles(unreadIDs, left, continuation);
					left = 0;
				}
			}
			DataBase.writeAccess().updateArticlesByID(unreadIDs, "unread");
			updateArticleList();
		}

		var articles = new Gee.LinkedList<Article>();
		string? continuation = null;
		int left = count;
		string? inoreader_feedID = (isTagID) ? null : feedID;
		string? inoreader_tagID = (isTagID) ? feedID : null;

		while(left > 0)
		{
			if(cancellable != null && cancellable.is_cancelled())
				return;

			if(left > 1000)
			{
				continuation = m_api.getArticles(articles, 1000, whatToGet, continuation, inoreader_tagID, inoreader_feedID);
				left -= 1000;
			}
			else
			{
				continuation = m_api.getArticles(articles, left, whatToGet, continuation, inoreader_tagID, inoreader_feedID);
				left = 0;
			}
		}
		writeArticles(articles);
	}

}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.FeedServerInterface), typeof(FeedReader.InoReaderInterface));
}
