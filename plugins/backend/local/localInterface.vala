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

public class FeedReader.localInterface : Peas.ExtensionBase, FeedServerInterface {

	private localUtils m_utils;
	private Soup.Session m_session;
	private Gtk.ListBox m_feedlist;
	private DataBaseReadOnly m_db;
	private DataBase m_db_write;

	public void init(GLib.SettingsBackend? settings_backend, Secret.Collection secrets, DataBaseReadOnly db, DataBase db_write)
	{
		m_db = db;
		m_db_write = db_write;
		m_utils = new localUtils();
		m_session = new Soup.Session();
		m_session.user_agent = Constants.USER_AGENT;
		m_session.timeout = 5;
	}

	public string getWebsite()
	{
		return "http://jangernert.github.io/FeedReader/";
	}

	public BackendFlags getFlags()
	{
		return (BackendFlags.LOCAL | BackendFlags.FREE_SOFTWARE | BackendFlags.FREE);
	}

	public string getID()
	{
		return "local";
	}

	public string iconName()
	{
		return "feed-service-local";
	}

	public string serviceName()
	{
		return "Local RSS";
	}

	public bool needWebLogin()
	{
		return false;
	}

	public Gtk.Box? getWidget()
	{
		var doneLabel = new Gtk.Label(_("Done"));
		var waitingLabel = new Gtk.Label(_("Adding Feeds"));
		var waitingSpinner = new Gtk.Spinner();
		var waitingBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
		waitingBox.pack_start(waitingSpinner, false, false, 0);
		waitingBox.pack_start(waitingLabel, true, false, 0);
		var loginStack = new Gtk.Stack();
		loginStack.add_named(doneLabel, "label");
		loginStack.add_named(waitingBox, "waiting");
		var loginButton = new Gtk.Button();
		loginButton.add(loginStack);
		loginButton.halign = Gtk.Align.END;
		loginButton.set_size_request(80, 30);
		loginButton.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
		loginButton.clicked.connect(() => {
			tryLogin();
			loginButton.set_sensitive(false);
			waitingSpinner.start();
			loginButton.get_style_context().remove_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
			loginStack.set_visible_child_name("waiting");
		});
		loginButton.show_all();

		var headlineLabel = new Gtk.Label("Recommended Feeds:");
		headlineLabel.get_style_context().add_class("h1");
		headlineLabel.set_justify(Gtk.Justification.CENTER);

		var loginLabel = new Gtk.Label("Fill your library with feeds. Here are some recommendations.");
		loginLabel.get_style_context().add_class("h2");
		loginLabel.set_justify(Gtk.Justification.CENTER);
		loginLabel.set_lines(3);

		m_feedlist = new Gtk.ListBox();
		m_feedlist.set_selection_mode(Gtk.SelectionMode.NONE);
		m_feedlist.set_sort_func(sortFunc);
		m_feedlist.set_header_func(headerFunc);

		try
		{
			uint8[] contents;
			var file = File.new_for_uri("resource:///org/gnome/FeedReader/recommendedFeeds.json");
			file.load_contents(null, out contents, null);

			var parser = new Json.Parser();
			parser.load_from_data((string)contents);

			Json.Array array = parser.get_root().get_array();

			for (int i = 0; i < array.get_length (); i++)
			{
				Json.Object object = array.get_object_element(i);

				m_feedlist.add(
					new SuggestedFeedRow(
						object.get_string_member("url"),
						object.get_string_member("icon"),
						object.get_string_member("category"),
						object.get_string_member("name"),
						object.get_string_member("description"),
						object.get_string_member("language")
						)
				);
			}
		}
		catch(GLib.Error e)
		{
			Logger.error("localLoginWidget: loading json filed");
			Logger.error(e.message);
		}

		var scroll = new Gtk.ScrolledWindow(null, null);
		scroll.set_size_request(450, 0);
		scroll.set_halign(Gtk.Align.CENTER);
		scroll.get_style_context().add_class(Gtk.STYLE_CLASS_FRAME);
		scroll.add(m_feedlist);

		var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		box.margin = 50;
		box.valign = Gtk.Align.FILL;
		box.halign = Gtk.Align.CENTER;
		box.pack_start(headlineLabel, false, false, 0);
		box.pack_start(loginLabel, false, false, 2);
		box.pack_start(scroll, true, true, 20);
		box.pack_end(loginButton, false, false, 0);
		return box;
	}

	public void showHtAccess()
	{
		return;
	}

	public void writeData()
	{
		return;
	}

	public async void postLoginAction()
	{
		SourceFunc callback = postLoginAction.callback;
		new GLib.Thread<void*>(null, () => {
			var children = m_feedlist.get_children();
			foreach(var r in children)
			{
				var row = r as SuggestedFeedRow;
				if(row.checked())
				{
					FeedReaderBackend.get_default().addFeed(row.getURL(), row.getCategory(), false, false);
				}
			}
			Idle.add((owned) callback);
			return null;
		});
		yield;
	}

	public string buildLoginURL()
	{
		return "";
	}

	public bool extractCode(string redirectURL)
	{
		return false;
	}

	private int sortFunc(Gtk.ListBoxRow row1, Gtk.ListBoxRow row2)
	{
		var r1 = row1 as SuggestedFeedRow;
		var r2 = row2 as SuggestedFeedRow;

		string cat1 = r1.getCategory();
		string cat2 = r2.getCategory();

		string name1 = r1.getName();
		string name2 = r2.getName();

		if(cat1 != cat2)
			return cat1.collate(cat2);

		return name1.collate(name2);
	}

	private void headerFunc(Gtk.ListBoxRow row, Gtk.ListBoxRow? before)
	{
		var r1 = row as SuggestedFeedRow;
		string cat1 = r1.getCategory();

		var label = new Gtk.Label(cat1);
		label.get_style_context().add_class("bold");
		label.margin_top = 20;
		label.margin_bottom = 5;

		var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		box.pack_start(label, true, true, 0);
		box.pack_end(new Gtk.Separator(Gtk.Orientation.HORIZONTAL), false, false, 0);
		box.show_all();

		if(before == null)
		{
			row.set_header(box);
			return;
		}

		var r2 = before as SuggestedFeedRow;
		string cat2 = r2.getCategory();

		if(cat1 != cat2)
			row.set_header(box);
	}


	public bool supportTags()
	{
		return true;
	}

	public bool doInitSync()
	{
		return false;
	}

	public string symbolicIcon()
	{
		return "feed-service-local-symbolic";
	}

	public string accountName()
	{
		return "Local RSS";
	}

	public string getServerURL()
	{
		return "http://localhorst/";
	}

	public string uncategorizedID()
	{
		return "0";
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
		return true;
	}

	public bool supportMultiCategoriesPerFeed()
	{
		return false;
	}

	public bool syncFeedsAndCategories()
	{
		return false;
	}

	public bool tagIDaffectedByNameChange()
	{
		return false;
	}

	public void resetAccount()
	{
		return;
	}

	public bool useMaxArticles()
	{
		return true;
	}

	public LoginResponse login()
	{
		return LoginResponse.SUCCESS;
	}

	public bool logout()
	{
		return true;
	}

	public bool serverAvailable()
	{
		return Utils.ping("https://duckduckgo.com/");
	}

	public void setArticleIsRead(string articleIDs, ArticleStatus read)
	{
		return;
	}

	public void setArticleIsMarked(string articleID, ArticleStatus marked)
	{
		return;
	}

	public void setFeedRead(string feedID)
	{
		return;
	}

	public void setCategoryRead(string catID)
	{
		return;
	}

	public void markAllItemsRead()
	{
		return;
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
		string tagID = "1";

		if(!m_db.isTableEmpty("tags"))
			tagID = (int.parse(m_db.getMaxID("tags", "tagID")) + 1).to_string();

		Logger.info("createTag: ID = " + tagID);
		return tagID;
	}

	public void deleteTag(string tagID)
	{
		return;
	}

	public void renameTag(string tagID, string title)
	{
		return;
	}

	public bool addFeed(string feedURL, string? catID, string? newCatName, out string feedID, out string errmsg)
	{
	 	var catIDs = new Gee.ArrayList<string>();
		if(catID == null && newCatName != null)
		{
			string cID = createCategory(newCatName, null);
			var cat = new Category(cID, newCatName, 0, 99, CategoryID.MASTER.to_string(), 1);
			var list = new Gee.LinkedList<Category>();
			list.add(cat);
			m_db_write.write_categories(list);
			catIDs.add(cID);
		}
		else if(catID != null && newCatName == null)
		{
			catIDs.add(catID);
		}
		else
		{
			catIDs.add("0");
		}

		feedID = "feedID00001";

		if(!m_db.isTableEmpty("feeds"))
		{
			feedID = "feedID%05d".printf(int.parse(m_db.getMaxID("feeds", "feed_id").substring(6)) + 1);
		}

		Logger.info(@"addFeed: ID = $feedID");
		Feed? Feed = m_utils.downloadFeed(m_session, feedURL, feedID, catIDs, out errmsg);

		if(Feed != null)
		{
			if(!m_db.feed_exists(Feed.getURL())) {
				var list = new Gee.LinkedList<Feed>();
				list.add(Feed);
				m_db_write.write_feeds(list);
				return true;
			}
		}

		return false;
	}

	public void addFeeds(Gee.List<Feed> feeds)
	{
		var finishedFeeds = new Gee.LinkedList<Feed>();

		int highestID = 0;

		if(!m_db.isTableEmpty("feeds"))
			highestID = int.parse(m_db.getMaxID("feeds", "feed_id").substring(6)) + 1;

		foreach(Feed f in feeds)
		{
			string feedID = "feedID" + highestID.to_string("%05d");
			highestID++;

			Logger.info(@"addFeed: ID = $feedID");
			string errmsg = "";
			Feed? Feed = m_utils.downloadFeed(m_session, f.getXmlUrl(), feedID, f.getCatIDs(), out errmsg);

			if(Feed != null)
			{
				if(Feed.getTitle() != "No Title")
					Feed.setTitle(f.getTitle());

				finishedFeeds.add(Feed);
			}
			else
				Logger.error("Couldn't add Feed: " + f.getXmlUrl());
		}

		foreach(var feed in finishedFeeds)
		{
			Logger.debug("finishedFeed: " + feed.getTitle());
		}

		m_db_write.write_feeds(finishedFeeds);
	}

	public void removeFeed(string feedID)
	{
		m_utils.deleteIcon(feedID);
		return;
	}

	public void renameFeed(string feedID, string title)
	{
		return;
	}

	public void moveFeed(string feedID, string newCatID, string? currentCatID)
	{
		return;
	}

	public string createCategory(string title, string? parentID)
	{
		string catID = "catID00001";

		if(!m_db.isTableEmpty("categories"))
		{
			string? id = m_db.getCategoryID(title);
			if(id == null)
			{
				catID = "catID%05d".printf(int.parse(m_db.getMaxID("categories", "categorieID").substring(5)) + 1);
			}
			else
			{
				catID = id;
			}
		}

		Logger.info("createCategory: ID = " + catID);
		return catID;
	}

	public void renameCategory(string catID, string title)
	{
		return;
	}

	public void moveCategory(string catID, string newParentID)
	{
		return;
	}

	public void deleteCategory(string catID)
	{
		return;
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
		return true;
	}

	public int getUnreadCount()
	{
		return 0;
	}

	public void getArticles(int count, ArticleStatus whatToGet, DateTime? since, string? feedID, bool isTagID, GLib.Cancellable? cancellable = null)
	{
		var feeds = m_db.read_feeds();
		var articles = new Gee.ArrayList<Article>();
		GLib.Mutex mutex = GLib.Mutex();

		try
		{
			var threads = new ThreadPool<Feed>.with_owned_data((feed) => {
				if(cancellable != null && cancellable.is_cancelled())
					return;

				Logger.debug("getArticles for feed: " + feed.getTitle());
				string url = feed.getXmlUrl().escape("");

				if(url == null || url == "" || GLib.Uri.parse_scheme(url) == null)
				{
					Logger.error("no valid URL");
					return;
				}

				var msg = new Soup.Message("GET", url);
				var session = new Soup.Session();
				session.user_agent = Constants.USER_AGENT;
				session.timeout = 5;
				session.send_message(msg);
				string xml = (string)msg.response_body.flatten().data;

				// parse
				Rss.Parser parser = new Rss.Parser();
				try
				{
					parser.load_from_data(xml, xml.length);
				}
				catch(GLib.Error e)
				{
					Logger.error("localInterface.getArticles: %s".printf(e.message));
					return;
				}
				var doc = parser.get_document();

				string? locale = null;
				if(doc.encoding != null
				&& doc.encoding != "")
				{
					locale = doc.encoding;
				}

				Logger.debug("Got %u articles".printf(doc.get_items().length()));
				foreach(Rss.Item item in doc.get_items())
				{
					string? articleID = item.guid;

					if(articleID == null)
					{
						if(item.link == null)
						{
							Logger.warning("no valid id and no valid URL as well? what the hell man? I'm giving up");
							continue;
						}

						articleID = item.link;
					}

					var date = new GLib.DateTime.now_local();
					if(item.pub_date != null)
					{
						GLib.Time time = GLib.Time();
						time.strptime(item.pub_date, "%a, %d %b %Y %H:%M:%S %Z");
						date = new GLib.DateTime.local(1900 + time.year, 1 + time.month, time.day, time.hour, time.minute, time.second);

						if(date == null)
							date = new GLib.DateTime.now_local();
					}

					string? content = m_utils.convert(item.description, locale);
					if(content == null)
						content = _("Nothing to read here.");

					Gee.List<string>? media = null;
					if(item.enclosure_url != null)
					{
						media = new Gee.ArrayList<string>();
						media.add(item.enclosure_url);
					}

					string articleURL = item.link;
					if(articleURL.has_prefix("/"))
						articleURL = feed.getURL() + articleURL.substring(1);

					var article = new Article(
										articleID,
										(item.title != null) ? m_utils.convert(item.title, locale) : null,
										articleURL,
										feed.getFeedID(),
										ArticleStatus.UNREAD,
										ArticleStatus.UNMARKED,
										content,
										content,
										m_utils.convert(item.author, locale),
										date,
										0,
										null,
										media
					);

					Logger.debug("Got new article: " + article.getTitle());

					mutex.lock();
					articles.add(article);
					mutex.unlock();
				}
			}, (int)GLib.get_num_processors(), true);

			foreach(Feed feed in feeds)
			{
				try
				{
					threads.add(feed);
				}
				catch(GLib.Error e)
				{
					Logger.error("Error creating thread to download Feed %s: %s".printf(feed.getTitle(), e.message));
				}
			}

			bool immediate = false; // allow to queue up additional tasks
			bool wait = true; // function will block until all tasks are done
			ThreadPool.free((owned)threads, immediate, wait);
		}
		catch(Error e)
		{
			Logger.error("Error creating threads to download Feeds: " + e.message);
		}

		articles.sort((a, b) => {
			return strcmp(a.getArticleID(), b.getArticleID());
		});

		if(articles.size > 0)
		{
			m_db_write.write_articles(articles);
			Logger.debug("localInterface: %i articles written".printf(articles.size));
			refreshFeedListCounter();
			updateArticleList();
		}
	}

}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.FeedServerInterface), typeof(FeedReader.localInterface));
}
