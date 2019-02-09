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

public class FeedReader.OldReaderInterface : FeedServerInterface {

private OldReaderAPI m_api;
private OldReaderUtils m_utils;
private Gtk.Entry m_userEntry;
private Gtk.Entry m_passwordEntry;

public override void init(GLib.SettingsBackend? settings_backend, Secret.Collection secrets)
{
	m_utils = new OldReaderUtils(settings_backend, secrets);
	m_api = new OldReaderAPI(m_utils);
}

public override string getWebsite()
{
	return "https://theoldreader.com/";
}

public override BackendFlags getFlags()
{
	return (BackendFlags.HOSTED | BackendFlags.PROPRIETARY | BackendFlags.PAID_PREMIUM);
}

public override string getID()
{
	return "oldreader";
}

public override string iconName()
{
	return "feed-service-oldreader";
}

public override string serviceName()
{
	return "The Old Reader";
}

public override bool needWebLogin()
{
	return false;
}

public override Gtk.Box? getWidget()
{
	var user_label = new Gtk.Label(_("Username:"));
	var password_label = new Gtk.Label(_("Password:"));

	user_label.set_alignment(1.0f, 0.5f);
	password_label.set_alignment(1.0f, 0.5f);

	user_label.set_hexpand(true);
	password_label.set_hexpand(true);

	m_userEntry = new Gtk.Entry();
	m_passwordEntry = new Gtk.Entry();

	m_userEntry.activate.connect(() => { tryLogin(); });
	m_passwordEntry.activate.connect(() => { tryLogin(); });

	m_passwordEntry.set_invisible_char('*');
	m_passwordEntry.set_visibility(false);

	var grid = new Gtk.Grid();
	grid.set_column_spacing(10);
	grid.set_row_spacing(10);
	grid.set_valign(Gtk.Align.CENTER);
	grid.set_halign(Gtk.Align.CENTER);

	grid.attach(user_label, 0, 0, 1, 1);
	grid.attach(m_userEntry, 1, 0, 1, 1);
	grid.attach(password_label, 0, 1, 1, 1);
	grid.attach(m_passwordEntry, 1, 1, 1, 1);

	var logo = new Gtk.Image.from_icon_name("feed-service-oldreader", Gtk.IconSize.MENU);

	var loginLabel = new Gtk.Label(_("Please log in to the Old Reader and enjoy using FeedReader"));
	loginLabel.get_style_context().add_class("h2");
	loginLabel.set_justify(Gtk.Justification.CENTER);
	loginLabel.set_lines(3);

	var loginButton = new Gtk.Button.with_label(_("Login"));
	loginButton.halign = Gtk.Align.END;
	loginButton.set_size_request(80, 30);
	loginButton.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
	loginButton.clicked.connect(() => { tryLogin(); });

	var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
	box.valign = Gtk.Align.CENTER;
	box.halign = Gtk.Align.CENTER;
	box.pack_start(loginLabel, false, false, 10);
	box.pack_start(logo, false, false, 10);
	box.pack_start(grid, true, true, 10);
	box.pack_end(loginButton, false, false, 20);

	m_userEntry.set_text(m_utils.getUser());
	m_passwordEntry.set_text(m_utils.getPasswd());

	return box;
}

public override void showHtAccess()
{
	return;
}

public override void writeData()
{
	m_utils.setUser(m_userEntry.get_text().strip());
	m_utils.setPassword(m_passwordEntry.get_text().strip());
}

public override async void postLoginAction()
{
	return;
}

public override string buildLoginURL()
{
	return "";
}

public override bool extractCode(string redirectURL)
{
	return false;
}

public override bool supportTags()
{
	return false;
}

public override bool doInitSync()
{
	return true;
}

public override string symbolicIcon()
{
	return "feed-service-oldreader-symbolic";
}

public override string accountName()
{
	return m_utils.getUser();
}

public override string getServerURL()
{
	return "https://theoldreader.com/";
}

public override string uncategorizedID()
{
	return "";
}

public override bool hideCategoryWhenEmpty(string cadID)
{
	return false;
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
	return false;
}

public override bool syncFeedsAndCategories()
{
	return true;
}

public override bool tagIDaffectedByNameChange()
{
	return true;
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
	if(read == ArticleStatus.READ)
		m_api.edidTag(articleIDs, "user/-/state/com.google/read");
	else
		m_api.edidTag(articleIDs, "user/-/state/com.google/read", false);
}

public override void setArticleIsMarked(string articleID, ArticleStatus marked)
{
	if(marked == ArticleStatus.MARKED)
		m_api.edidTag(articleID, "user/-/state/com.google/starred");
	else
		m_api.edidTag(articleID, "user/-/state/com.google/starred", false);
}

public override bool alwaysSetReadByID()
{
	return false;
}

public override void setFeedRead(string feedID)
{
	m_api.markAsRead(feedID);
}

public override void setCategoryRead(string catID)
{
	m_api.markAsRead(catID);
}

public override void markAllItemsRead()
{
	var db = DataBase.readOnly();
	var categories = db.read_categories();
	foreach(Category cat in categories)
	{
		m_api.markAsRead(cat.getCatID());
	}

	var feeds = db.read_feeds_without_cat();
	foreach(Feed feed in feeds)
	{
		m_api.markAsRead(feed.getFeedID());
	}
	m_api.markAsRead();
}

public override void tagArticle(string articleID, string tagID)
{
	m_api.edidTag(articleID, tagID, true);
}

public override void removeArticleTag(string articleID, string tagID)
{
	m_api.edidTag(articleID, tagID, false);
}

public override string createTag(string caption)
{
	return m_api.composeTagID(caption);
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
	return m_api.ping();
}

public override bool addFeed(string feedURL, string? catID, string? newCatName, out string feedID, out string errmsg)
{
	feedID = "feed/" + feedURL;
	errmsg = "";
	bool success = false;

	if(catID == null && newCatName != null)
	{
		string newCatID = m_api.composeTagID(newCatName);
		success = m_api.editSubscription(OldReaderAPI.OldreaderSubscriptionAction.SUBSCRIBE, {"feed/"+feedURL}, null, newCatID);
	}
	else
	{
		success = m_api.editSubscription(OldReaderAPI.OldreaderSubscriptionAction.SUBSCRIBE, {"feed/"+feedURL}, null, catID);
	}

	if(!success)
		errmsg = @"The old reader could not add $feedURL";

	return success;
}

public override void addFeeds(Gee.List<Feed> feeds)
{
	string cat = "";
	string[] urls = {};

	foreach(Feed f in feeds)
	{
		if(f.getCatIDs()[0] != cat)
		{
			m_api.editSubscription(OldReaderAPI.OldreaderSubscriptionAction.SUBSCRIBE, urls, null, cat);
			urls = {};
			cat = f.getCatIDs()[0];
		}

		urls += "feed/" + f.getXmlUrl();
	}

	m_api.editSubscription(OldReaderAPI.OldreaderSubscriptionAction.SUBSCRIBE, urls, null, cat);
}

public override void removeFeed(string feedID)
{
	m_api.editSubscription(OldReaderAPI.OldreaderSubscriptionAction.UNSUBSCRIBE, {feedID});
}

public override void renameFeed(string feedID, string title)
{
	m_api.editSubscription(OldReaderAPI.OldreaderSubscriptionAction.EDIT, {feedID}, title);
}

public override void moveFeed(string feedID, string newCatID, string? currentCatID)
{
	m_api.editSubscription(OldReaderAPI.OldreaderSubscriptionAction.EDIT, {feedID}, null, newCatID, currentCatID);
}

public override string createCategory(string title, string? parentID)
{
	return m_api.composeTagID(title);
}

public override void renameCategory(string catID, string title)
{
	m_api.renameTag(catID, title);
}

public override void moveCategory(string catID, string newParentID)
{
	return;
}

public override void deleteCategory(string catID)
{
	m_api.deleteTag(catID);
}

public override void removeCatFromFeed(string feedID, string catID)
{
	return;
}

public override void importOPML(string opml)
{
	var parser = new OPMLparser(opml);
	parser.parse();
}

public override bool getFeedsAndCats(Gee.List<Feed> feeds, Gee.List<Category> categories, Gee.List<Tag> tags, GLib.Cancellable? cancellable = null)
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

public override int getUnreadCount()
{
	return m_api.getTotalUnread();
}

public override void getArticles(int count, ArticleStatus whatToGet, DateTime? since, string? feedID, bool isTagID, GLib.Cancellable? cancellable = null)
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
	string? OldReader_feedID = (isTagID) ? null : feedID;
	string? OldReader_tagID = (isTagID) ? feedID : null;

	while(left > 0)
	{
		if(cancellable != null && cancellable.is_cancelled())
			return;

		if(left > 1000)
		{
			continuation = m_api.getArticles(articles, 1000, whatToGet, continuation, OldReader_tagID, OldReader_feedID);
			left -= 1000;
		}
		else
		{
			continuation = m_api.getArticles(articles, left, whatToGet, continuation, OldReader_tagID, OldReader_feedID);
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
	objmodule.register_extension_type(typeof(FeedReader.FeedServerInterface), typeof(FeedReader.OldReaderInterface));
}
