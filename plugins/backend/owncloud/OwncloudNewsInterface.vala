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
	private Gtk.Entry m_urlEntry;
	private Gtk.Entry m_userEntry;
	private Gtk.Entry m_passwordEntry;
	private Gtk.Entry m_AuthUserEntry;
	private Gtk.Entry m_AuthPasswordEntry;
	private Gtk.Revealer m_revealer;
	private bool m_need_htaccess = false;

	public void init()
	{
		m_api = new OwncloudNewsAPI();
		m_utils = new OwncloudNewsUtils();
	}

	public string getWebsite()
	{
		return "https://github.com/nextcloud/news";
	}

	public BackendFlags getFlags()
	{
		return (BackendFlags.SELF_HOSTED | BackendFlags.FREE_SOFTWARE | BackendFlags.FREE);
	}

	public string getID()
	{
		return "owncloud";
	}

	public string iconName()
	{
		return "feed-service-owncloud";
	}

	public string serviceName()
	{
		return "ownCloud News";
	}

	public void writeData()
	{
		m_utils.setURL(m_urlEntry.get_text());
		m_utils.setUser(m_userEntry.get_text().strip());
		m_utils.setPassword(m_passwordEntry.get_text().strip());
		if(m_need_htaccess)
		{
			m_utils.setHtaccessUser(m_AuthUserEntry.get_text().strip());
			m_utils.setHtAccessPassword(m_AuthPasswordEntry.get_text().strip());
		}
	}

	public async void postLoginAction()
	{
		return;
	}

	public void showHtAccess()
	{
		m_revealer.set_reveal_child(true);
	}

	public bool needWebLogin()
	{
		return false;
	}

	public Gtk.Box? getWidget()
	{
		var urlLabel = new Gtk.Label(_("OwnCloud URL:"));
		var userLabel = new Gtk.Label(_("Username:"));
		var passwordLabel = new Gtk.Label(_("Password:"));

		urlLabel.set_alignment(1.0f, 0.5f);
		userLabel.set_alignment(1.0f, 0.5f);
		passwordLabel.set_alignment(1.0f, 0.5f);

		urlLabel.set_hexpand(true);
		userLabel.set_hexpand(true);
		passwordLabel.set_hexpand(true);

		m_urlEntry = new Gtk.Entry();
		m_userEntry = new Gtk.Entry();
		m_passwordEntry = new Gtk.Entry();

		m_urlEntry.activate.connect(writeData);
		m_userEntry.activate.connect(writeData);
		m_passwordEntry.activate.connect(writeData);

		m_passwordEntry.set_input_purpose(Gtk.InputPurpose.PASSWORD);
		m_passwordEntry.set_visibility(false);

		var grid = new Gtk.Grid();
		grid.set_column_spacing(10);
		grid.set_row_spacing(10);
		grid.set_valign(Gtk.Align.CENTER);
		grid.set_halign(Gtk.Align.CENTER);

		var logo = new Gtk.Image.from_icon_name("feed-service-owncloud", Gtk.IconSize.MENU);

		grid.attach(urlLabel, 0, 0, 1, 1);
		grid.attach(m_urlEntry, 1, 0, 1, 1);
		grid.attach(userLabel, 0, 1, 1, 1);
		grid.attach(m_userEntry, 1, 1, 1, 1);
		grid.attach(passwordLabel, 0, 2, 1, 1);
		grid.attach(m_passwordEntry, 1, 2, 1, 1);

		// http auth stuff ----------------------------------------------------
		var authUserLabel = new Gtk.Label(_("Username:"));
		var authPasswordLabel = new Gtk.Label(_("Password:"));

		authUserLabel.set_alignment(1.0f, 0.5f);
		authPasswordLabel.set_alignment(1.0f, 0.5f);

		authUserLabel.set_hexpand(true);
		authPasswordLabel.set_hexpand(true);

		m_AuthUserEntry = new Gtk.Entry();
		m_AuthPasswordEntry = new Gtk.Entry();
		m_AuthPasswordEntry.set_input_purpose(Gtk.InputPurpose.PASSWORD);
		m_AuthPasswordEntry.set_visibility(false);

		m_AuthUserEntry.activate.connect(writeData);
		m_AuthPasswordEntry.activate.connect(writeData);

		var authGrid = new Gtk.Grid();
		authGrid.margin = 10;
		authGrid.set_column_spacing(10);
		authGrid.set_row_spacing(10);
		authGrid.set_valign(Gtk.Align.CENTER);
		authGrid.set_halign(Gtk.Align.CENTER);

		authGrid.attach(authUserLabel, 0, 0, 1, 1);
		authGrid.attach(m_AuthUserEntry, 1, 0, 1, 1);
		authGrid.attach(authPasswordLabel, 0, 1, 1, 1);
		authGrid.attach(m_AuthPasswordEntry, 1, 1, 1, 1);

		var frame = new Gtk.Frame(_("HTTP Authorization"));
		frame.set_halign(Gtk.Align.CENTER);
		frame.add(authGrid);
		m_revealer = new Gtk.Revealer();
		m_revealer.add(frame);
		//---------------------------------------------------------------------

		var loginLabel = new Gtk.Label(_("Please log in to your ownCloud News instance and enjoy using FeedReader"));
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
		return "feed-service-owncloud-symbolic";
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
		return false;
	}

	public bool syncFeedsAndCategories()
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

	public void setCategoryRead(string catID)
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

	public bool addFeed(string feedURL, string? catID, string? newCatName, out string feedID, out string errmsg)
	{
		bool success = false;
		int64 id = 0;
		if(catID == null && newCatName != null)
		{
			string newCatID = m_api.addFolder(newCatName).to_string();
			success = m_api.addFeed(feedURL, newCatID, out id, out errmsg);
		}
		else
		{
			success = m_api.addFeed(feedURL, catID, out id, out errmsg);
		}


		feedID = id.to_string();
		return success;
	}

	public void addFeeds(Gee.List<Feed> feeds)
	{
		int64 id = 0;
		string errmsg = "";
		foreach(Feed f in feeds)
		{
			m_api.addFeed(f.getXmlUrl(), f.getCatIDs()[0], out id, out errmsg);
		}
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

	public bool getFeedsAndCats(Gee.List<Feed> feeds, Gee.List<Category> categories, Gee.List<Tag> tags, GLib.Cancellable? cancellable = null)
	{
		if(m_api.getFeeds(feeds))
		{
			if(cancellable != null && cancellable.is_cancelled())
				return false;

			if(m_api.getCategories(categories, feeds))
				return true;
		}

		return false;
	}

	public int getUnreadCount()
	{
		return (int)DataBase.readOnly().get_unread_total();
	}

	public void getArticles(int count, ArticleStatus whatToGet, DateTime? since, string? feedID, bool isTagID, GLib.Cancellable? cancellable = null)
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

		var articles = new Gee.LinkedList<Article>();

		if(count == -1)
			m_api.getNewArticles(articles, DataBase.readOnly().getLastModified(), type, id);
		else
			m_api.getArticles(articles, 0, -1, read, type, id);

		writeArticles(articles);
	}
}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.FeedServerInterface), typeof(FeedReader.OwncloudNewsInterface));
}
