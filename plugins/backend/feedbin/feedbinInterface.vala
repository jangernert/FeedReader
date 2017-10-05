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

public class FeedReader.FeedbinInterface : Peas.ExtensionBase, FeedServerInterface {

	private FeedbinAPI m_api;
	private FeedbinUtils m_utils;
	private Gtk.Entry m_userEntry;
	private Gtk.Entry m_passwordEntry;

	public void init()
	{
		m_api = new FeedbinAPI();
		m_utils = new FeedbinUtils();
	}

	public string getWebsite()
	{
		return "https://feedbin.com/";
	}

	public BackendFlags getFlags()
	{
		return (BackendFlags.HOSTED | BackendFlags.PROPRIETARY | BackendFlags.PAID);
	}

	public string getID()
	{
		return "feedbin";
	}

	public string iconName()
	{
		return "feed-service-feedbin";
	}

	public string serviceName()
	{
		return "Feedbin";
	}

	public bool needWebLogin()
	{
		return false;
	}

	public Gtk.Box? getWidget()
	{
		var user_label = new Gtk.Label(_("Username:"));
		var password_label = new Gtk.Label(_("Password:"));

		user_label.set_alignment(1.0f, 0.5f);
		password_label.set_alignment(1.0f, 0.5f);

		user_label.set_hexpand(true);
		password_label.set_hexpand(true);

		m_userEntry = new Gtk.Entry();
		m_passwordEntry = new Gtk.Entry();

		m_userEntry.activate.connect(() => { login(); });
		m_passwordEntry.activate.connect(() => { login(); });

		m_passwordEntry.set_input_purpose(Gtk.InputPurpose.PASSWORD);
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

		var logo = new Gtk.Image.from_icon_name("feed-service-feedbin", Gtk.IconSize.MENU);

		var loginLabel = new Gtk.Label(_("Please log in to Feedbin to enjoy using FeedReader"));
		loginLabel.get_style_context().add_class("h2");
		loginLabel.set_justify(Gtk.Justification.CENTER);
		loginLabel.set_lines(3);

		var loginButton = new Gtk.Button.with_label(_("Login"));
		loginButton.halign = Gtk.Align.END;
		loginButton.set_size_request(80, 30);
		loginButton.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
		loginButton.clicked.connect(() => { login(); });


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

	public void showHtAccess()
	{
		return;
	}

	public void writeData()
	{
		m_utils.setUser(m_userEntry.get_text().strip());
		m_utils.setPassword(m_passwordEntry.get_text().strip());
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
		return "feed-service-feedbin-symbolic";
	}

	public string accountName()
	{
		return m_utils.getUser();
	}

	public string getServerURL()
	{
		return "https://feedbin.com/";
	}

	public string uncategorizedID()
	{
		return "0";
	}

	public bool supportCategories()
	{
		return true;
	}

	public bool supportFeedManipulation()
	{
		return true;
	}

	public bool hideCategoryWhenEmpty(string catID)
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
		return true;
	}

	public bool serverAvailable()
	{
		return Utils.ping("https://api.feedbin.com/");
	}

	public void setArticleIsRead(string articleID, ArticleStatus read)
	{
		var articleIDs = ListUtils.single<string>(articleID);
		if(read == ArticleStatus.UNREAD)
			m_api.createUnreadEntries(articleIDs, false);
		else if(read == ArticleStatus.READ)
			m_api.createUnreadEntries(articleIDs, true);
	}

	public void setArticleIsMarked(string articleID, ArticleStatus marked)
	{
		var articleIDs = ListUtils.single<string>(articleID);
		if(marked == ArticleStatus.MARKED)
			m_api.createStarredEntries(articleIDs, true);
		else if(marked == ArticleStatus.UNMARKED)
			m_api.createStarredEntries(articleIDs, false);
	}

	private void setRead(string id, FeedListType type)
	{
		int numArticles = 0;
		uint count = 1000;
		uint offset = 0;
		do
		{
			var articles = dbDaemon.get_default().read_articles(id, type, ArticleListState.ALL, "", count, offset);

			FuncUtils.MapFunction<Article, string> articleToID = (article) => { return article.getArticleID(); };
			var articleIDs = FuncUtils.map(articles, articleToID);
			m_api.createUnreadEntries(articleIDs, true);

			offset += count;
			numArticles = articles.size;
		}
		while(numArticles > 0);
	}

	public void setFeedRead(string feedID)
	{
		setRead(feedID, FeedListType.FEED);
	}

	public void setCategoryRead(string catID)
	{
		setRead(catID, FeedListType.CATEGORY);
	}

	public void markAllItemsRead()
	{
		setRead(FeedID.ALL.to_string(), FeedListType.FEED);
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
		return;
	}

	public void renameTag(string tagID, string title)
	{
		return;
	}

	public bool addFeed(string feed_url, string? cat_id, string? category_name, out string feed_id, out string errmsg)
	{
		feed_id = "";
		var subscription_id = m_api.addSubscription(feed_url, out errmsg);
		if(subscription_id == null || errmsg != "")
			return false;

		var new_feed_id = m_api.getFeedIDForSubscription(subscription_id);
		if(new_feed_id == null)
			return false;

		feed_id = new_feed_id;
		if(category_name != null)
			m_api.addTagging(feed_id, category_name);

		return true;
	}

	public void addFeeds(Gee.List<Feed> feeds)
	{
		return;
	}

	public void removeFeed(string feedID)
	{
		m_api.deleteSubscription(feedID);
	}

	public void renameFeed(string feedID, string title)
	{
		m_api.renameFeed(feedID, title);
	}

	public void moveFeed(string feed_id, string new_category, string? old_category)
	{
		Logger.debug(@"moveFeed: $feed_id from $old_category to $new_category");
		if(old_category != null)
		{
			var taggings = m_api.getTaggings();
			foreach(var tagging in taggings)
			{
				if(tagging.name != old_category || tagging.feed_id != feed_id)
					continue;
				Logger.debug(@"moveFeed: Deleting tag $old_category from $feed_id");
				m_api.deleteTagging(tagging.id);
				break;
			}
		}
		Logger.debug(@"moveFeed: Adding tag $new_category to $feed_id");
		m_api.addTagging(feed_id, new_category);
	}

	public void renameCategory(string old_category, string new_category)
	{
		Logger.debug(@"renameCategory: From $old_category to $new_category");
		var taggings = m_api.getTaggings();
		foreach(var tagging in taggings)
		{
			if(tagging.name != old_category)
				continue;
			var feed_id = tagging.feed_id;
			Logger.debug(@"renameCategory: Tagging $feed_id with $new_category");
			m_api.deleteTagging(tagging.id);
			m_api.addTagging(feed_id, new_category);
		}
	}

	public void moveCategory(string catID, string newParentID)
	{
		// Feedbin doesn't have multi-level categories
		return;
	}

	public string createCategory(string title, string? parentID)
	{
		// Categories are created and destroyed based on feeds having them.
		// There are no empty categories in Feedbin
		return "";
	}

	public void deleteCategory(string category)
	{
		Logger.debug(@"deleteCategory: $category");
		var taggings = m_api.getTaggings();
		foreach(var tagging in taggings)
		{
			if(tagging.name != category)
				continue;
			var feed_id = tagging.feed_id;
			Logger.debug(@"deleteCategory: Deleting category $category from feed $feed_id");
			m_api.deleteTagging(tagging.id);
		}
	}

	public void removeCatFromFeed(string feed_id, string category)
	{
		Logger.debug(@"removeCatFromFeed: Feed $feed_id, category $category");
		var taggings = m_api.getTaggings();
		foreach(var tagging in taggings)
		{
			if(tagging.feed_id != feed_id || tagging.name != category)
				continue;

			Logger.debug(@"removeCatFromFeed: Deleting category $category from feed $feed_id");
			m_api.deleteTagging(tagging.id);
			break;
		}
	}

	public void importOPML(string opml)
	{
	}

	public bool getFeedsAndCats(Gee.List<Feed> feeds, Gee.List<Category> categories, Gee.List<tag> tags, GLib.Cancellable? cancellable = null)
	{
		var new_feeds = m_api.getFeeds();
		if(new_feeds == null)
			return false;
		feeds.clear();
		feeds.add_all(new_feeds);

		if(cancellable != null && cancellable.is_cancelled())
			return false;

		var taggings = m_api.getTaggings();
		if(taggings == null || (cancellable != null && cancellable.is_cancelled()))
			return false;

		// It's easier to rebuild the category list than to update it
		var category_names = new Gee.HashSet<string>();
		foreach(var tagging in taggings)
		{
			category_names.add(tagging.name);
		}
		Logger.debug("getFeedsAndCats: Got %d categories: %s".printf(category_names.size, StringUtils.join(category_names, ", ")));

		categories.clear();
		foreach(string name in category_names)
		{
			// Note: Feedbin categories *are* case sensitive, so we don't need
			// to change the case here. "articles" and "Articles" are different
			// tags.
			categories.add(
				new Category (
					name,
					name,
					0,
					0,
					CategoryID.MASTER.to_string(),
					1
				)
			);
		}

		var tag_map = new Gee.HashMultiMap<string, string>();
		foreach(var tagging in taggings)
		{
			tag_map.set(tagging.feed_id, tagging.name);
		}

		foreach(Feed feed in feeds)
		{
			var feed_id = feed.getFeedID();

			if(tag_map.contains(feed_id))
			{
				var feed_categories = tag_map.get(feed_id);
				feed.setCats(feed_categories);
			}
			else
				feed.setCategory(uncategorizedID());
		}
		return true;
	}

	public int getUnreadCount()
	{
		return m_api.unreadEntries().size;
	}

	public void getArticles(int count, ArticleStatus whatToGet, string? feedID, bool isTagID, GLib.Cancellable? cancellable = null)
	{
		if(whatToGet == ArticleStatus.READ)
		{
			return;
		}

		var settings_state = new GLib.Settings("org.gnome.feedreader.saved-state");
		DateTime? time = null;
		switch(Settings.general().get_enum("drop-articles-after"))
		{
			case DropArticles.ONE_WEEK:
				time = new DateTime.now_utc().add_weeks(-1);
				break;

			case DropArticles.ONE_MONTH:
				time = new DateTime.now_utc().add_months(-1);
				break;

			case DropArticles.SIX_MONTHS:
				time = new DateTime.now_utc().add_months(-6);
				break;
		}
		if(!dbDaemon.get_default().isTableEmpty("articles"))
		{
			var last_sync = new DateTime.from_unix_utc(settings_state.get_int("last-sync"));
			if(time == null || last_sync.to_unix() > time.to_unix())
			{
				time = last_sync;
			}
		}

		string? fID = isTagID ? null : feedID;
		bool onlyStarred = (whatToGet == ArticleStatus.MARKED);

		// The Feedbin API doesn't include read/unread/starred status in the entries.json
		var unreadIDs = new Gee.HashSet<string>();
		unreadIDs.add_all(m_api.unreadEntries());

		var starredIDs = new Gee.HashSet<string>();
		starredIDs.add_all(m_api.starredEntries());

		for(int page = 1; ; ++page)
		{
			if(cancellable != null && cancellable.is_cancelled())
				return;

			var articles = m_api.getEntries(page, onlyStarred, unreadIDs, starredIDs, time, fID);
			if(articles.size == 0)
				break;

			writeArticles(articles);
		}
	}
}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.FeedServerInterface), typeof(FeedReader.FeedbinInterface));
}
