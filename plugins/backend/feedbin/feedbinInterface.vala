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
	private DataBaseReadOnly m_db;
	private DataBase m_db_write;

	public void init(GLib.SettingsBackend? settings_backend, Secret.Collection secrets, DataBaseReadOnly db, DataBase db_write)
	{
		m_db = db;
		m_db_write = db_write;
		m_utils = new FeedbinUtils(settings_backend, secrets);
		m_api = new FeedbinAPI(m_utils.getUser(), m_utils.getPassword(), Constants.USER_AGENT);
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
	ensures (result != null)
	{
		var user_label = new Gtk.Label(_("Username:"));
		var password_label = new Gtk.Label(_("Password:"));

		user_label.set_alignment(1.0f, 0.5f);
		password_label.set_alignment(1.0f, 0.5f);

		user_label.set_hexpand(true);
		password_label.set_hexpand(true);

		m_userEntry = new Gtk.Entry();
		m_passwordEntry = new Gtk.Entry();
		var loginButton = new Gtk.Button.with_label(_("Login"));

		m_userEntry.activate.connect(() => {
			loginButton.activate();
		});
		m_passwordEntry.activate.connect(() => {
			loginButton.activate();
		});

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

		loginButton.halign = Gtk.Align.END;
		loginButton.set_size_request(80, 30);
		loginButton.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
		loginButton.clicked.connect(() => {
			tryLogin();
		});

		var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
		box.valign = Gtk.Align.CENTER;
		box.halign = Gtk.Align.CENTER;
		box.pack_start(loginLabel, false, false, 10);
		box.pack_start(logo, false, false, 10);
		box.pack_start(grid, true, true, 10);
		box.pack_end(loginButton, false, false, 20);

		m_userEntry.set_text(m_utils.getUser());
		m_passwordEntry.set_text(m_utils.getPassword());

		return box;
	}

	public void showHtAccess()
	{
	}

	public void writeData()
	{
		m_api.username = m_userEntry.get_text().strip();
		m_utils.setUser(m_api.username);

		m_api.password = m_passwordEntry.get_text().strip();
		m_utils.setPassword(m_api.password);
	}

	public async void postLoginAction()
	{
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
		try
		{
			if(m_api.login())
				return LoginResponse.SUCCESS;
			else
				return LoginResponse.WRONG_LOGIN;
		}
		catch(FeedbinError.NO_CONNECTION e)
		{
			return LoginResponse.NO_CONNECTION;
		}
		catch(Error e)
		{
			Logger.error("Feedbin login: " + e.message);
			return LoginResponse.UNKNOWN_ERROR;
		}
	}

	public bool logout()
	{
		return true;
	}

	public bool serverAvailable()
	{
		return login() != LoginResponse.NO_CONNECTION;
	}

	public void setArticleIsRead(string article_id, ArticleStatus status)
	{
		var entry_id = int64.parse(article_id);
		var entry_ids = ListUtils.single<int64?>(entry_id);
		try
		{
			m_api.set_entries_read(entry_ids, status == ArticleStatus.READ);
		}
		catch(Error e)
		{
			Logger.error(@"FeedbinInterface.setArticleIsRead: " + e.message);
		}
	}

	public void setArticleIsMarked(string article_id, ArticleStatus status)
	{
		var entry_id = int64.parse(article_id);
		var entry_ids = ListUtils.single<int64?>(entry_id);
		try
		{
			m_api.set_entries_starred(entry_ids, status == ArticleStatus.MARKED);
		}
		catch(Error e)
		{
			Logger.error(@"FeedbinInterface.setArticleIsMarked: " + e.message);
		}
	}

	private void setRead(string id, FeedListType type)
	{
		const int count = 1000;
		int num_articles = 1; // set to any value > 0
		for(var offset = 0; num_articles > 0; offset += count)
		{
			var articles = m_db.read_articles(id, type, ArticleListState.ALL, "", count, offset);
			var entry_ids = new Gee.ArrayList<int64?>();
			foreach(var article in articles)
			{
				entry_ids.add(int64.parse(article.getArticleID()));
			}
			try
			{
				m_api.set_entries_read(entry_ids, true);
			}
			catch(Error e)
			{
				Logger.error(@"FeedbinInterface.setRead: " + e.message);
				break;
			}
		}
	}

	public void setFeedRead(string feed_id)
	{
		setRead(feed_id, FeedListType.FEED);
	}

	public void setCategoryRead(string category_id)
	{
		setRead(category_id, FeedListType.CATEGORY);
	}

	public void markAllItemsRead()
	{
		setRead(FeedID.ALL.to_string(), FeedListType.FEED);
	}

	public void tagArticle(string article_id, string tag_id)
	{
		return;
	}

	public void removeArticleTag(string article_id, string tag_id)
	{
		return;
	}

	public string createTag(string caption)
	{
		return "";
	}

	public void deleteTag(string tag_id)
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
		try
		{
			var subscription = m_api.add_subscription(feed_url);
			if (subscription == null)
			{
				errmsg = @"Feedbin could not find a feed at $(feed_url)";
				return false;
			}
			feed_id = subscription.feed_id.to_string();

			if(category_name != null)
				m_api.add_tagging(subscription.feed_id, category_name);

			errmsg = "";
			return true;
		}
		catch(Error e)
		{
			errmsg = e.message;
			Logger.error(@"FeedbinInterface.addFeed: $errmsg");
			return false;
		}
	}

	public void addFeeds(Gee.List<Feed> feeds)
	{
		return;
	}

	private FeedbinAPI.Subscription subscription_for_feed(string feed_id_str) throws FeedbinError
	{
		var feed_id = int64.parse(feed_id_str);
		var subscriptions = m_api.get_subscriptions();
		foreach(var subscription in subscriptions)
		{
			if(subscription.feed_id == feed_id)
				return subscription;
		}
		throw new FeedbinError.NOT_FOUND("No subscription found for feed $feed_id");
	}

	public void removeFeed(string feed_id_str)
	{
		try
		{
			var subscription = subscription_for_feed(feed_id_str);
			m_api.delete_subscription(subscription.id);
		}
		catch(Error e)
		{
			Logger.error(@"FeedbinInterface.removeFeed: " + e.message);
		}
	}

	public void renameFeed(string feed_id_str, string title)
	{
		try
		{
			var subscription = subscription_for_feed(feed_id_str);
			m_api.rename_subscription(subscription.id, title);
		}
		catch(Error e)
		{
			Logger.error(@"FeedbinInterface.renameFeed: " + e.message);
		}
	}

	public void moveFeed(string feed_id_str, string new_category, string? old_category)
	{
		Logger.debug(@"moveFeed: $feed_id_str from $old_category to $new_category");
		try
		{
			var subscription = subscription_for_feed(feed_id_str);
			var feed_id = subscription.feed_id;
			if(old_category != null)
			{
				var taggings = m_api.get_taggings();
				foreach(var tagging in taggings)
				{
					if(tagging.name != old_category || tagging.feed_id != feed_id)
						continue;
					Logger.debug(@"moveFeed: Deleting tag $old_category from $feed_id");
					m_api.delete_tagging(tagging.id);
					break;
				}
			}
			Logger.debug(@"moveFeed: Adding tag $new_category to $feed_id");
			m_api.add_tagging(feed_id, new_category);
		}
		catch(Error e)
		{
			Logger.error(@"FeedbinInterface.moveFeed: " + e.message);
		}
	}

	public void renameCategory(string old_category, string new_category)
	{
		Logger.debug(@"renameCategory: From $old_category to $new_category");
		try
		{
			var taggings = m_api.get_taggings();
			foreach(var tagging in taggings)
			{
				if(tagging.name != old_category)
					continue;
				var feed_id = tagging.feed_id;
				Logger.debug(@"renameCategory: Tagging $feed_id with $new_category");
				m_api.delete_tagging(tagging.id);
				m_api.add_tagging(feed_id, new_category);
			}
		}
		catch(Error e)
		{
			Logger.error(@"FeedbinInterface.renameCategory: " + e.message);
		}
	}

	public void moveCategory(string category_id, string new_parent_id)
	{
		// Feedbin doesn't have multi-level categories
	}

	public string createCategory(string title, string? parent_id)
	ensures (result == title)
	{
		// Categories are created and destroyed based on feeds having them.
		// There are no empty categories in Feedbin
		return title;
	}

	public void deleteCategory(string category)
	{
		Logger.debug(@"deleteCategory: $category");
		try
		{
			var taggings = m_api.get_taggings();
			foreach(var tagging in taggings)
			{
				if(tagging.name != category)
					continue;
				var feed_id = tagging.feed_id;
				Logger.debug(@"deleteCategory: Deleting category $category from feed $feed_id");
				m_api.delete_tagging(tagging.id);
			}
		}
		catch(Error e)
		{
			Logger.error(@"FeedbinInterface.deleteCategory: " + e.message);
		}
	}

	public void removeCatFromFeed(string feed_id_str, string category)
	{
		Logger.debug(@"removeCatFromFeed: Feed $feed_id_str, category $category");
		try
		{
			var feed_id = int64.parse(feed_id_str);
			var taggings = m_api.get_taggings();
			foreach(var tagging in taggings)
			{
				if(tagging.feed_id != feed_id || tagging.name != category)
					continue;

				Logger.debug(@"removeCatFromFeed: Deleting category $category from feed $feed_id");
				m_api.delete_tagging(tagging.id);
				break;
			}
		}
		catch(Error e)
		{
			Logger.error(@"FeedbinInterface.removeCatFromFeed: " + e.message);
		}
	}

	public void importOPML(string opml)
	{
	}

	public bool getFeedsAndCats(Gee.List<Feed> feeds, Gee.List<Category> categories, Gee.List<Tag> tags, GLib.Cancellable? cancellable = null)
	{
		try
		{
			var taggings = m_api.get_taggings();
			if(cancellable != null && cancellable.is_cancelled())
				return false;

			var favicons = m_api.get_favicons();
			if(cancellable != null && cancellable.is_cancelled())
				return false;

			// It's easier to rebuild the category list than to update it
			var category_names = new Gee.HashSet<string>();
			foreach(var tagging in taggings)
			{
				category_names.add(tagging.name);
			}
			Logger.debug("getFeedsAndCats: Got %d categories: %s".printf(category_names.size, StringUtils.join(category_names, ", ")));

			categories.clear();
			var top_category = CategoryID.MASTER.to_string();
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
						top_category,
						1
					)
				);
			}

			var tag_map = new Gee.HashMultiMap<string, string>();
			foreach(var tagging in taggings)
			{
				tag_map.set(tagging.feed_id.to_string(), tagging.name);
			}

			var subscriptions = m_api.get_subscriptions();
			feeds.clear();

			foreach(var subscription in subscriptions)
			{
				var feed_id = subscription.feed_id.to_string();
				Gee.List<string> feed_categories = new Gee.ArrayList<string>();

				if(tag_map.contains(feed_id))
					feed_categories.add_all(tag_map.get(feed_id));
				else
					feed_categories.add(uncategorizedID());

				string? favicon_uri = null;
				if(subscription.site_url != null)
				{
					var uri = new Soup.URI(subscription.site_url);
					if(uri != null)
					{
						var favicon = favicons.get(uri.host);
						if(favicon != null)
						{
							string base64 = Base64.encode(favicon.get_data());
							favicon_uri = @"data:application/octet-stream;base64,$base64";
						}
					}
				}

				feeds.add(
					new Feed(
						feed_id,
						subscription.title,
						subscription.site_url,
						0,
						feed_categories,
						favicon_uri,
						subscription.feed_url)
				);
			}
		}
		catch(Error e)
		{
			Logger.error(@"FeedbinInterface.getFeedsAndCats: " + e.message);
			return false;
		}
		return true;
	}

	public int getUnreadCount()
	ensures (result >= 0)
	{
		try
		{
			return m_api.get_unread_entries().size;
		}
		catch(Error e)
		{
			Logger.error(@"FeedbinInterface.getUnreadCount: " + e.message);
			return 0;
		}
	}

	public void getArticles(int count, ArticleStatus what_to_get, DateTime? since, string? feed_id_str, bool is_tag_id, GLib.Cancellable? cancellable = null)
	requires (count >= 0)
	{
		try
		{
			int64? feed_id = null;
			if(!is_tag_id && feed_id_str != null)
				feed_id = int64.parse(feed_id_str);
			bool only_starred = what_to_get == ArticleStatus.MARKED;

			if(cancellable != null && cancellable.is_cancelled())
				return;

			// The Feedbin API doesn't include read/unread/starred status in the entries.json
			// so look them up.
			var unread_ids = m_api.get_unread_entries();
			if(cancellable != null && cancellable.is_cancelled())
				return;

			var starred_ids = m_api.get_starred_entries();

			{
				// Update read/unread status of existing entries
				string search_feed_id;
				FeedListType search_type;
				if(feed_id == null)
				{
					search_feed_id = FeedID.ALL.to_string();
					search_type = FeedListType.ALL_FEEDS;
				}
				else if(is_tag_id)
				{
					search_feed_id = feed_id_str;
					search_type = FeedListType.TAG;
				}
				else
				{
					search_feed_id = feed_id_str;
					search_type = FeedListType.FEED;
				}

				Logger.debug(@"Checking if any articles in $search_type $search_feed_id changed state");
				for(var offset = 0, c = 1000; ; offset += c)
				{
					var articles = new Gee.ArrayList<Article>();
					var existing_articles = m_db.read_articles(search_feed_id, search_type, ArticleListState.ALL, "", c, offset);
					if(existing_articles.size == 0)
						break;

					foreach(var article in existing_articles)
					{
						var id = int64.parse(article.getArticleID());
						var marked = starred_ids.contains(id) ? ArticleStatus.MARKED : ArticleStatus.UNMARKED;
						var unread = unread_ids.contains(id) ? ArticleStatus.UNREAD : ArticleStatus.READ;
						var changed = false;
						if(article.getMarked() != marked)
						{
							article.setMarked(marked);
							changed = true;
						}
						if(article.getUnread() != unread)
						{
							article.setUnread(unread);
							changed = true;
						}
						articles.add(article);
					}
					writeArticles(articles);
				}
			}

			// Add new articles
			for(int page = 1; ; ++page)
			{
				if(cancellable != null && cancellable.is_cancelled())
					return;

				var entries = m_api.get_entries(page, only_starred, since, feed_id);
				if(entries.size == 0)
					break;

				var articles = new Gee.ArrayList<Article>();
				foreach(var entry in entries)
				{
					articles.add(
						new Article(
							entry.id.to_string(),
							entry.title,
							entry.url,
							entry.feed_id.to_string(),
							unread_ids.contains(entry.id) ? ArticleStatus.UNREAD : ArticleStatus.READ,
							starred_ids.contains(entry.id) ? ArticleStatus.MARKED : ArticleStatus.UNMARKED,
							entry.content,
							entry.summary,
							entry.author,
							entry.published != null ? entry.published : entry.created_at,
							-1,
							null,
							null)
					);
				}
				writeArticles(articles);
			}
		}
		catch(Error e)
		{
			Logger.error(@"FeedbinInterface.getArticles: " + e.message);
		}
	}
}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.FeedServerInterface), typeof(FeedReader.FeedbinInterface));
}
