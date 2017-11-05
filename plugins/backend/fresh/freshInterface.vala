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
	private Gtk.Entry m_urlEntry;
	private Gtk.Entry m_userEntry;
	private Gtk.Entry m_passwordEntry;
	private Gtk.Entry m_authPasswordEntry;
	private Gtk.Entry m_authUserEntry;
	private Gtk.Revealer m_revealer;
	private bool m_need_htaccess = false;

	public void init(GLib.SettingsBackend settings_backend)
	{
		m_utils = new freshUtils(settings_backend);
		m_api = new freshAPI(m_utils);
	}

	public string getWebsite()
	{
		return "https://freshrss.org/";
	}

	public BackendFlags getFlags()
	{
		return (BackendFlags.SELF_HOSTED | BackendFlags.FREE_SOFTWARE | BackendFlags.FREE);
	}

	public string getID()
	{
		return "fresh";
	}

	public string iconName()
	{
		return "feed-service-fresh";
	}

	public string serviceName()
	{
		return "freshRSS";
	}

	public bool needWebLogin()
	{
		return false;
	}

	public Gtk.Box? getWidget()
	{
		var url_label = new Gtk.Label(_("freshRSS URL:"));
		var user_label = new Gtk.Label(_("Username:"));
		var password_label = new Gtk.Label(_("Password:"));

		url_label.set_alignment(1.0f, 0.5f);
		user_label.set_alignment(1.0f, 0.5f);
		password_label.set_alignment(1.0f, 0.5f);

		url_label.set_hexpand(true);
		user_label.set_hexpand(true);
		password_label.set_hexpand(true);

		m_urlEntry = new Gtk.Entry();
		m_userEntry = new Gtk.Entry();
		m_passwordEntry = new Gtk.Entry();

		m_urlEntry.activate.connect(() => { tryLogin(); });
		m_userEntry.activate.connect(() => { tryLogin(); });
		m_passwordEntry.activate.connect(() => { tryLogin(); });

		m_passwordEntry.set_input_purpose(Gtk.InputPurpose.PASSWORD);
		m_passwordEntry.set_visibility(false);

		var grid = new Gtk.Grid();
		grid.set_column_spacing(10);
		grid.set_row_spacing(10);
		grid.set_valign(Gtk.Align.CENTER);
		grid.set_halign(Gtk.Align.CENTER);

		grid.attach(url_label, 0, 0, 1, 1);
		grid.attach(m_urlEntry, 1, 0, 1, 1);
		grid.attach(user_label, 0, 1, 1, 1);
		grid.attach(m_userEntry, 1, 1, 1, 1);
		grid.attach(password_label, 0, 2, 1, 1);
		grid.attach(m_passwordEntry, 1, 2, 1, 1);


		// http auth stuff ----------------------------------------------------
		var auth_user_label = new Gtk.Label(_("Username:"));
		var auth_password_label = new Gtk.Label(_("Password:"));

		auth_user_label.set_alignment(1.0f, 0.5f);
		auth_password_label.set_alignment(1.0f, 0.5f);

		auth_user_label.set_hexpand(true);
		auth_password_label.set_hexpand(true);

		m_authUserEntry = new Gtk.Entry();
		m_authPasswordEntry = new Gtk.Entry();
		m_authPasswordEntry.set_input_purpose(Gtk.InputPurpose.PASSWORD);
		m_authPasswordEntry.set_visibility(false);

		m_authUserEntry.activate.connect(() => { tryLogin(); });
		m_authPasswordEntry.activate.connect(() => { tryLogin(); });

		var authGrid = new Gtk.Grid();
		authGrid.margin = 10;
		authGrid.set_column_spacing(10);
		authGrid.set_row_spacing(10);
		authGrid.set_valign(Gtk.Align.CENTER);
		authGrid.set_halign(Gtk.Align.CENTER);

		authGrid.attach(auth_user_label, 0, 0, 1, 1);
		authGrid.attach(m_authUserEntry, 1, 0, 1, 1);
		authGrid.attach(auth_password_label, 0, 1, 1, 1);
		authGrid.attach(m_authPasswordEntry, 1, 1, 1, 1);

		var frame = new Gtk.Frame(_("HTTP Authorization"));
		frame.set_halign(Gtk.Align.CENTER);
		frame.add(authGrid);
		m_revealer = new Gtk.Revealer();
		m_revealer.add(frame);
		//---------------------------------------------------------------------

		var logo = new Gtk.Image.from_icon_name("feed-service-fresh", Gtk.IconSize.MENU);

		var loginLabel = new Gtk.Label(_("Please log in to your freshRSS server and enjoy using FeedReader"));
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
		box.pack_start(m_revealer, true, true, 10);
		box.pack_end(loginButton, false, false, 20);

		m_urlEntry.set_text(m_utils.getUnmodifiedURL());
		m_userEntry.set_text(m_utils.getUser());
		m_passwordEntry.set_text(m_utils.getPasswd());

		return box;
	}

	public void showHtAccess()
	{
		m_revealer.set_reveal_child(true);
	}

	public void writeData()
	{
		m_utils.setURL(m_urlEntry.get_text());
		m_utils.setUser(m_userEntry.get_text().strip());
		m_utils.setPassword(m_passwordEntry.get_text().strip());
		if(m_need_htaccess)
		{
			m_utils.setHtaccessUser(m_authUserEntry.get_text().strip());
			m_utils.setHtAccessPassword(m_authPasswordEntry.get_text().strip());
		}
	}

	public async void postLoginAction()
	{
		return;
	}

	public bool extractCode(string redirectURL)
	{
		return false;
	}

	public string buildLoginURL()
	{
		return "";
	}

	public bool supportTags()
	{
		return false;
	}

	public bool doInitSync()
	{
		return true;
	}

	public string symbolicIcon()
	{
		return "feed-service-fresh-symbolic";
	}

	public string accountName()
	{
		return m_utils.getUser();
	}

	public string getServerURL()
	{
		return m_utils.getUnmodifiedURL();
	}

	public string uncategorizedID()
	{
		return "1";
	}

	public bool hideCategoryWhenEmpty(string catID)
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

	public void setCategoryRead(string catID)
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

	public bool addFeed(string feedURL, string? catID, string? newCatName, out string feedID, out string errmsg)
	{
		string? cat = null;
		if(catID != null)
			cat = catID;
		else if(newCatName != null)
			cat = newCatName;

		cat = m_api.composeTagID(cat);

		var response = m_api.editStream("subscribe", {"feed/" + feedURL}, null, cat, null);
		if(response.status != 200)
		{
			feedID = "";
			errmsg = response.data;
			return false;
		}

		errmsg = "";
		feedID = response.data;
		return true;
	}

	public void addFeeds(Gee.List<Feed> feeds)
	{
		string cat = "";
		string[] urls = {};

		foreach(Feed f in feeds)
		{
			if(f.getCatIDs()[0] != cat)
			{
				m_api.editStream("subscribe", urls, null, cat, null);
				urls = {};
				cat = f.getCatIDs()[0];
			}

			urls += "feed/" + f.getXmlUrl();
		}

		m_api.editStream("subscribe", urls, null, cat, null);
	}

	public void removeFeed(string feedID)
	{
		m_api.editStream("unsubscribe", {feedID}, null, null, null);
	}

	public void renameFeed(string feedID, string title)
	{
		m_api.editStream("edit", {feedID}, title, null, null);
	}

	public void moveFeed(string feedID, string newCatID, string? currentCatID)
	{
		m_api.editStream("edit", {feedID}, null, newCatID, currentCatID);
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
		if(m_api.getSubscriptionList(feeds))
		{
			if(cancellable != null && cancellable.is_cancelled())
				return false;

			if(m_api.getTagList(categories))
				return true;
		}

		return false;
	}

	public int getUnreadCount()
	{
		return m_api.getUnreadCounts();
	}

	public void getArticles(int count, ArticleStatus whatToGet, DateTime? since, string? feedID, bool isTagID, GLib.Cancellable? cancellable = null)
	{
		if(whatToGet == ArticleStatus.READ)
		{
			return;
		}

		var articles = new Gee.LinkedList<Article>();
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
			if(cancellable != null && cancellable.is_cancelled())
				return;

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
		writeArticles(articles);
	}

}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.FeedServerInterface), typeof(FeedReader.freshInterface));
}
