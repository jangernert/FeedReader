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
	private Gtk.Entry m_urlEntry;
	private Gtk.Entry m_userEntry;
	private Gtk.Entry m_passwordEntry;
	private Gtk.Entry m_authPasswordEntry;
	private Gtk.Entry m_authUserEntry;
	private Gtk.Revealer m_revealer;
	private bool m_need_htaccess = false;

	public void init(GLib.SettingsBackend settings_backend, Secret.Collection secrets)
	{
		m_utils = new ttrssUtils(settings_backend);
		m_api = new ttrssAPI(m_utils);
	}

	public string getWebsite()
	{
		return "https://tt-rss.org/";
	}

	public BackendFlags getFlags()
	{
		return (BackendFlags.SELF_HOSTED | BackendFlags.FREE_SOFTWARE | BackendFlags.FREE);
	}

	public string getID()
	{
		return "ttrss";
	}

	public string iconName()
	{
		return "feed-service-ttrss";
	}

	public string serviceName()
	{
		return "Tiny Tiny RSS";
	}

	public bool needWebLogin()
	{
		return false;
	}

	public Gtk.Box? getWidget()
	{
		var url_label = new Gtk.Label(_("Tiny Tiny RSS URL:"));
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

		var logo = new Gtk.Image.from_icon_name("feed-service-ttrss", Gtk.IconSize.MENU);

		var loginLabel = new Gtk.Label(_("Please log in to your Tiny Tiny RSS server and enjoy using FeedReader"));
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

	public bool hideCategoryWhenEmpty(string catID)
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

	public void setCategoryRead(string catID)
	{
		m_api.catchupFeed(catID, true);
	}

	public void markAllItemsRead()
	{
		var categories = DataBase.readOnly().read_categories();
		foreach(Category cat in categories)
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

	public bool addFeed(string feedURL, string? catID, string? newCatName, out string feedID, out string errmsg)
	{
		bool success = false;
		if(catID == null && newCatName != null)
		{
			var newCatID = m_api.createCategory(newCatName);
			success = m_api.subscribeToFeed(feedURL, newCatID, null, null, out errmsg);
		}
		else
		{
			success = m_api.subscribeToFeed(feedURL, catID, null, null, out errmsg);
		}

		if(success)
			feedID = (int.parse(DataBase.readOnly().getMaxID("feeds", "feed_id")) + 1).to_string();
		else
			feedID = "-98";


		return success;
	}

	public void addFeeds(Gee.List<Feed> feeds)
	{
		string? errmsg = null;
		foreach(Feed f in feeds)
		{
			m_api.subscribeToFeed(f.getXmlUrl(), f.getCatIDs()[0], null, null, out errmsg);
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

	public bool getFeedsAndCats(Gee.List<Feed> feeds, Gee.List<Category> categories, Gee.List<Tag> tags, GLib.Cancellable? cancellable = null)
	{
		if(m_api.getCategories(categories))
		{
			if(cancellable != null && cancellable.is_cancelled())
				return false;

			if(m_api.getFeeds(feeds, categories))
			{
				if(cancellable != null && cancellable.is_cancelled())
					return false;

				if(m_api.getUncategorizedFeeds(feeds))
				{
					if(cancellable != null && cancellable.is_cancelled())
						return false;

					if(m_api.getTags(tags))
						return true;
				}
			}
		}

		return false;
	}

	public int getUnreadCount()
	{
		return m_api.getUnreadCount();
	}

	public void getArticles(int count, ArticleStatus whatToGet, DateTime? since, string? feedID, bool isTagID, GLib.Cancellable? cancellable = null)
	{
		var settings_general = new GLib.Settings("org.gnome.feedreader");

		// first use newsPlus plugin to update states of 10x as much articles as we would normaly do
		var unreadIDs = m_api.NewsPlus(ArticleStatus.UNREAD, 10*settings_general.get_int("max-articles"));

		if(cancellable != null && cancellable.is_cancelled())
			return;

		if(unreadIDs != null && whatToGet == ArticleStatus.ALL)
		{
			Logger.debug("getArticles: newsplus plugin active");
			var markedIDs = m_api.NewsPlus(ArticleStatus.MARKED, settings_general.get_int("max-articles"));
			DataBase.writeAccess().updateArticlesByID(unreadIDs, "unread");
			DataBase.writeAccess().updateArticlesByID(markedIDs, "marked");
			//updateArticleList();
		}

		if(cancellable != null && cancellable.is_cancelled())
			return;

		string articleIDs = "";
		int skip = count;
		int amount = 200;

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

			var articles = new Gee.LinkedList<Article>();
			m_api.getHeadlines(articles, skip, amount, whatToGet, (feedID == null) ? ttrssUtils.TTRSSSpecialID.ALL : int.parse(feedID));

			// only update article states if they haven't been updated by the newsPlus-plugin
			if(unreadIDs == null || whatToGet != ArticleStatus.ALL)
			{
				DataBase.writeAccess().update_articles(articles);
				updateArticleList();
			}

			foreach(Article article in articles)
			{
				var id = article.getArticleID();
				if(!DataBase.readOnly().article_exists(id))
				{
					articleIDs += id + ",";
				}
			}
		}

		if(articleIDs.length > 0)
			articleIDs = articleIDs.substring(0, articleIDs.length -1);

		var articles = new Gee.LinkedList<Article>();

		if(articleIDs != "")
			m_api.getArticles(articleIDs, articles);

		articles.sort((a, b) => {
				return strcmp(a.getArticleID(), b.getArticleID());
		});

		if(cancellable != null && cancellable.is_cancelled())
			return;

		if(articles.size > 0)
		{
			DataBase.writeAccess().write_articles(articles);
			refreshFeedListCounter();
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
