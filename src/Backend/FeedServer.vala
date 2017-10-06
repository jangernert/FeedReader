//	This file is part of FeedReader.
//
//	FeedReader is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	FeedReader is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General public License for more details.
//
//	You should have received a copy of the GNU General public License
//	along with FeedReader.  If not, see <http://www.gnu.org/licenses/>.

public class FeedReader.FeedServer : GLib.Object {

	private bool m_pluginLoaded = false;
	private Peas.ExtensionSet m_extensions;
	private string? m_activeExtension = null;
	private FeedServerInterface? m_plugin;
	private Peas.Engine m_engine;

	private static FeedServer? m_server;

	public static FeedServer get_default()
	{
		if(m_server == null)
			m_server = new FeedServer();

		return m_server;
	}

	private FeedServer()
	{
		m_engine = Peas.Engine.get_default();
		m_engine.add_search_path(Constants.INSTALL_PREFIX + "/" + Constants.INSTALL_LIBDIR + "/plugins/", null);
		m_engine.enable_loader("python3");

		m_extensions = new Peas.ExtensionSet(m_engine, typeof(FeedServerInterface));

		m_extensions.extension_added.connect((info, extension) => {
			Logger.debug("feedserver: plugin loaded %s".printf(info.get_name()));
			(extension as FeedServerInterface).init();
		});

		m_extensions.extension_removed.connect((info, extension) => {
			Logger.debug("feedserver: plugin removed %s".printf(info.get_name()));
		});

		m_engine.load_plugin.connect((info) => {
			Logger.debug("feedserver: engine load %s".printf(info.get_name()));
		});

		m_engine.unload_plugin.connect((info) => {
			Logger.debug("feedserver: engine unload %s".printf(info.get_name()));
		});

		foreach(var plugin in m_engine.get_plugin_list())
		{
			m_engine.try_load_plugin(plugin);
		}
	}

	public bool pluginLoaded()
	{
		return m_pluginLoaded;
	}

	public Peas.ExtensionSet getPlugins()
	{
		return m_extensions;
	}

	public bool setActivePlugin(string pluginID)
	{
		m_pluginLoaded = false;
		m_plugin = null;

		var plugin = m_engine.get_plugin_info(pluginID);

		if(plugin == null)
		{
			Logger.error(@"feedserver: failed to load info for \"$pluginID\"");
			return m_pluginLoaded;
		}

		Logger.info("Plugin Name: " + plugin.get_name());
		Logger.info("Plugin Version: " + plugin.get_version());
		Logger.info("Plugin Website: " + plugin.get_website());
		Logger.info("Plugin Dir: " + plugin.get_module_dir());


		m_activeExtension = pluginID;
		m_extensions.foreach((extSet, info, ext) => {
			var plug = ext as FeedServerInterface;
			if(plug != null && plug.getID() == pluginID)
			{
				plug.tryLogin.connect(() => { FeedReaderBackend.get_default().tryLogin(); });
				plug.newFeedList.connect(() => { FeedReaderBackend.get_default().newFeedList(); });
				plug.refreshFeedListCounter.connect(() => { FeedReaderBackend.get_default().refreshFeedListCounter(); });
				plug.updateArticleList.connect(() => { FeedReaderBackend.get_default().updateArticleList(); });
				plug.showArticleListOverlay.connect(() => { FeedReaderBackend.get_default().showArticleListOverlay(); });
				plug.writeArticles.connect((articles) => { writeArticles(articles); });

				m_plugin = plug;
				m_pluginLoaded = true;
			}
		});
		return m_pluginLoaded;
	}

	public FeedServerInterface? getActivePlugin()
	{
		return m_plugin;
	}

	public void syncContent(GLib.Cancellable? cancellable = null)
	{
		if(!serverAvailable())
		{
			Logger.debug("FeedServer: can't snyc - not logged in or unreachable");
			return;
		}

		if(syncFeedsAndCategories())
		{
			var categories = new Gee.LinkedList<Category>();
			var feeds      = new Gee.LinkedList<Feed>();
			var tags       = new Gee.LinkedList<tag>();

			if(cancellable != null && cancellable.is_cancelled())
				return;

			syncProgress(_("Getting feeds and categories"));

			if(!getFeedsAndCats(feeds, categories, tags, cancellable))
			{
				Logger.error("FeedServer: something went wrong getting categories and feeds");
				return;
			}

			if(cancellable != null && cancellable.is_cancelled())
				return;

			if(cancellable != null && cancellable.is_cancelled())
				return;

			// write categories
			DataBase.writeAccess().reset_exists_flag();
			DataBase.writeAccess().write_categories(categories);
			DataBase.writeAccess().delete_nonexisting_categories();

			// write feeds
			DataBase.writeAccess().reset_subscribed_flag();
			DataBase.writeAccess().write_feeds(feeds);
			DataBase.writeAccess().delete_articles_without_feed();
			DataBase.writeAccess().delete_unsubscribed_feeds();

			// write tags
			DataBase.writeAccess().reset_exists_tag();
			DataBase.writeAccess().write_tags(tags);
			DataBase.writeAccess().update_tags(tags);
			DataBase.writeAccess().delete_nonexisting_tags();

			FeedReaderBackend.get_default().newFeedList();

			// download favicons for all feeds
			Utils.getFavIcons.begin(feeds, cancellable, (obj, res) => {
				Utils.getFavIcons.end(res);
				FeedReaderBackend.get_default().reloadFavIcons();
			});
		}
		else
		{
			// download favicons for all feeds
			Utils.getFavIcons.begin(DataBase.readOnly().read_feeds(), cancellable, (obj, res) => {
				Utils.getFavIcons.end(res);
				FeedReaderBackend.get_default().reloadFavIcons();
			});
		}

		if(cancellable != null && cancellable.is_cancelled())
			return;



		int unread = getUnreadCount();
		int max = ArticleSyncCount();


		syncProgress(_("Getting articles"));
		int before = DataBase.readOnly().getHighestRowID();

		if(unread > max && useMaxArticles())
		{
			getArticles(20, ArticleStatus.MARKED, null, false, cancellable);
			getArticles(unread, ArticleStatus.UNREAD, null, false, cancellable);
		}
		else
		{
			getArticles(max, ArticleStatus.ALL, null, false, cancellable);
		}

		if(cancellable != null && cancellable.is_cancelled())
			return;

		//update fulltext table
		DataBase.writeAccess().updateFTS();

		int after = DataBase.readOnly().getHighestRowID();
		int newArticles = after-before;
		if(newArticles > 0)
		{
			Notification.send(newArticles);
		}

		switch(Settings.general().get_enum("drop-articles-after"))
		{
			case DropArticles.NEVER:
				break;

			case DropArticles.ONE_WEEK:
				DataBase.writeAccess().dropOldArtilces(1);
				break;

			case DropArticles.ONE_MONTH:
				DataBase.writeAccess().dropOldArtilces(4);
				break;

			case DropArticles.SIX_MONTHS:
				DataBase.writeAccess().dropOldArtilces(24);
				break;
		}

		var now = new DateTime.now_local();
		Settings.state().set_int("last-sync", (int)now.to_unix());

		DataBase.writeAccess().checkpoint();
		FeedReaderBackend.get_default().newFeedList();
		return;
	}

	public void InitSyncContent(GLib.Cancellable? cancellable = null)
	{
		Logger.debug("FeedServer: initial sync");

		if(syncFeedsAndCategories())
		{
			var categories = new Gee.LinkedList<Category>();
			var feeds      = new Gee.LinkedList<Feed>();
			var tags       = new Gee.LinkedList<tag>();

			syncProgress(_("Getting feeds and categories"));

			getFeedsAndCats(feeds, categories, tags, cancellable);

			if(cancellable != null && cancellable.is_cancelled())
				return;

			if(cancellable != null && cancellable.is_cancelled())
				return;

			// write categories
			DataBase.writeAccess().write_categories(categories);

			// write feeds
			DataBase.writeAccess().write_feeds(feeds);

			// write tags
			DataBase.writeAccess().write_tags(tags);

			FeedReaderBackend.get_default().newFeedList();

			// download favicons for all feeds
			Utils.getFavIcons.begin(feeds, cancellable, (obj, res) => {
				Utils.getFavIcons.end(res);
				FeedReaderBackend.get_default().reloadFavIcons();
			});
		}
		else
		{
			// download favicons for all feeds
			Utils.getFavIcons.begin(DataBase.readOnly().read_feeds(), cancellable, (obj, res) => {
				Utils.getFavIcons.end(res);
				FeedReaderBackend.get_default().reloadFavIcons();
			});
		}

		if(cancellable != null && cancellable.is_cancelled())
			return;

		// get marked articles
		syncProgress(_("Getting starred articles"));
		getArticles(Settings.general().get_int("max-articles"), ArticleStatus.MARKED, null, false, cancellable);

		if(cancellable != null && cancellable.is_cancelled())
			return;

		// get articles for each tag
		syncProgress(_("Getting tagged articles"));
		foreach(var tag_item in DataBase.readOnly().read_tags())
		{
			getArticles((Settings.general().get_int("max-articles")/8), ArticleStatus.ALL, tag_item.getTagID(), true, cancellable);
			if(cancellable != null && cancellable.is_cancelled())
				return;
		}

		if(useMaxArticles())
		{
			//get max-articls amunt like normal sync
			getArticles(Settings.general().get_int("max-articles"), ArticleStatus.ALL, null, false, cancellable);
		}

		if(cancellable != null && cancellable.is_cancelled())
			return;

		// get unread articles
		syncProgress(_("Getting unread articles"));
		getArticles(getUnreadCount(), ArticleStatus.UNREAD, null, false, cancellable);

		if(cancellable != null && cancellable.is_cancelled())
			return;

		//update fulltext table
		DataBase.writeAccess().updateFTS();

		Settings.general().reset("content-grabber");

		var now = new DateTime.now_local();
		Settings.state().set_int("last-sync", (int)now.to_unix());

		return;
	}

	private void writeArticles(Gee.List<Article> articles)
	{
		if(articles.size > 0)
		{
			DataBase.writeAccess().update_articles(articles);

			// Reverse the list
			var new_articles = new Gee.LinkedList<Article>();
			foreach(var article in articles)
			{
				new_articles.insert(0, article);
			}

			DataBase.writeAccess().write_articles(new_articles);
			FeedReaderBackend.get_default().refreshFeedListCounter();
			FeedReaderBackend.get_default().updateArticleList();
		}
	}

	public async void grabContent(GLib.Cancellable? cancellable = null)
	{
		if(!Settings.general().get_boolean("download-images")
		&& !Settings.general().get_boolean("content-grabber"))
			return;

		Logger.debug("FeedServer: grabContent");
		var articles = DataBase.readOnly().readUnfetchedArticles();
		int size = articles.size;
		int i = 0;

		if(size > 0)
		{
			var session = new Soup.Session();
			session.user_agent = Constants.USER_AGENT;
			session.timeout = 5;
			session.ssl_strict = false;

			try
			{
				var threads = new ThreadPool<Article>.with_owned_data((a) => {
					if(cancellable != null && cancellable.is_cancelled())
						return;

						if(Settings.general().get_boolean("content-grabber"))
						{
							var grabber = new Grabber(session, a.getURL(), a.getArticleID(), a.getFeedID());
							if(grabber.process(cancellable))
							{
								grabber.print();
								if(a.getAuthor() != "" && grabber.getAuthor() != null)
								{
									a.setAuthor(grabber.getAuthor());
								}
								if(a.getTitle() != "" && grabber.getTitle() != null)
								{
									a.setTitle(grabber.getTitle());
								}
								string html = grabber.getArticle();
								string xml = "<?xml";

								while(html.has_prefix(xml))
								{
									int end = html.index_of_char('>');
									html = html.slice(end+1, html.length).chug();
								}

								a.setHTML(html);
							}
							else
							{
								downloadImages(session, a, cancellable);
							}
						}
						else
						{
							downloadImages(session, a, cancellable);
						}

						if(cancellable == null || !cancellable.is_cancelled())
							DataBase.writeAccess().writeContent(a);

						++i;
						syncProgress(_(@"Grabbing full content: $i / $size"));
				}, (int)GLib.get_num_processors(), true);

				foreach(var Article in articles)
				{
					threads.add(Article);
				}

				bool immediate = false; // allow to queue up additional tasks
				bool wait = true; // function will block until all tasks are done
				ThreadPool.free((owned)threads, immediate, wait);
			}
			catch(GLib.Error e)
			{
				Logger.error("FeedServer.grabContent: " + e.message);
			}

			//update fulltext table
			DataBase.writeAccess().updateFTS();
		}
	}

	private void downloadImages(Soup.Session session, Article article, GLib.Cancellable? cancellable = null)
	{
		if(!Settings.general().get_boolean("download-images"))
			return;

		var html_cntx = new Html.ParserCtxt();
		html_cntx.use_options(Html.ParserOption.NOERROR + Html.ParserOption.NOWARNING);
		Html.Doc* doc = html_cntx.read_doc(article.getHTML(), "");
		if(doc == null)
		{
			Logger.debug("Grabber: parsing failed");
			return;
		}
		grabberUtils.fixIframeSize(doc, "youtube.com");
		grabberUtils.repairURL("//img", "src", doc, article.getURL());
		grabberUtils.repairURL("//iframe", "src", doc, article.getURL());
		grabberUtils.stripNode(doc, "//a[not(node())]");
		grabberUtils.removeAttributes(doc, null, "style");
		grabberUtils.removeAttributes(doc, "a", "onclick");
		grabberUtils.removeAttributes(doc, "img", "srcset");
		grabberUtils.removeAttributes(doc, "img", "sizes");
		grabberUtils.addAttributes(doc, "a", "target", "_blank");

		if(cancellable != null && cancellable.is_cancelled())
		{
			delete doc;
			return;
		}

		grabberUtils.saveImages(session, doc, article.getArticleID(), article.getFeedID(), cancellable);

		string html = "";
		doc->dump_memory_enc(out html);
		html = grabberUtils.postProcessing(ref html);
		article.setHTML(html);
		delete doc;
	}

	private int ArticleSyncCount()
	{
		if(!useMaxArticles())
			return -1;

		return Settings.general().get_int("max-articles");
	}

	// Only used with command-line
	public static void grabArticle(string url)
	{
		var session = new Soup.Session();
		session.user_agent = Constants.USER_AGENT;
		session.timeout = 5;
		session.ssl_strict = false;

		var grabber = new Grabber(session, url, null, null);
		if(grabber.process())
		{
			grabber.print();

			string html = grabber.getArticle();
			string title = Utils.UTF8fix(grabber.getTitle());
			string xml = "<?xml";

			while(html.has_prefix(xml))
			{
				int end = html.index_of_char('>');
				html = html.slice(end+1, html.length).chug();
			}

			string path = GLib.Environment.get_user_data_dir() + "/debug-article/%s.html".printf(title);

			if(FileUtils.test(path, GLib.FileTest.EXISTS))
				GLib.FileUtils.remove(path);

			try
			{
				var file = GLib.File.new_for_path(path);
				var stream = file.create(FileCreateFlags.REPLACE_DESTINATION);

				stream.write(html.data);
				Logger.debug("Grabber: article html written to " + path);

				string output = libVilistextum.parse(html, 1);

				if(output == "" || output == null)
				{
					Logger.error("could not generate preview text");
					return;
				}

				output = output.replace("\n"," ");
				output = output.replace("_"," ");

				path = GLib.Environment.get_user_data_dir() + "/debug-article/%s.txt".printf(title);

				if(FileUtils.test(path, GLib.FileTest.EXISTS))
					GLib.FileUtils.remove(path);

				file = GLib.File.new_for_path(path);
				stream = file.create(FileCreateFlags.REPLACE_DESTINATION);

				stream.write(output.data);
				Logger.debug("Grabber: preview written to " + path);
			}
			catch(GLib.Error e)
			{
				Logger.error("FeedServer.grabArticle: %s".printf(e.message));
			}
		}
		else
		{
			Logger.error("FeedServer.grabArticle: article could not be processed " + url);
		}
	}

	// Only used with command-line
	public static void grabImages(string htmlFile, string url)
	{
		var session = new Soup.Session();
		session.user_agent = Constants.USER_AGENT;
		session.timeout = 5;
		session.ssl_strict = false;

		var html_cntx = new Html.ParserCtxt();
		html_cntx.use_options(Html.ParserOption.NOERROR + Html.ParserOption.NOWARNING);
		Html.Doc* doc = html_cntx.read_file(htmlFile);
		if (doc == null)
		{
			Logger.debug("Grabber: parsing failed");
			return;
		}
		grabberUtils.repairURL("//img", "src", doc, url);
		grabberUtils.saveImages(session, doc, "", "");

		string html = "";
		doc->dump_memory_enc(out html);
		html = html.replace("<h3/>", "<h3></h3>");

		int pos1 = html.index_of("<iframe", 0);
		int pos2 = -1;
		while(pos1 != -1)
		{
			pos2 = html.index_of("/>", pos1);
			string broken_iframe = html.substring(pos1, pos2+2-pos1);
			string fixed_iframe = broken_iframe.substring(0, broken_iframe.length) + "></iframe>";
			html = html.replace(broken_iframe, fixed_iframe);
			int pos3 = html.index_of("<iframe", pos1+7);
			if(pos3 == pos1)
				break;
			else
				pos1 = pos3;
		}

		try
		{
			var file = GLib.File.new_for_path(GLib.Environment.get_user_data_dir() + "/debug-article/ArticleLocalImages.html");
			var stream = file.create(FileCreateFlags.REPLACE_DESTINATION);
			stream.write(html.data);
		}
		catch(GLib.Error e)
		{
			Logger.error("FeedServer.grabImages: %s".printf(e.message));
		}

		delete doc;
	}

	public bool supportTags()
	{
		if(!m_pluginLoaded)
			return false;

		return m_plugin.supportTags();
	}

	public bool doInitSync()
	{
		if(!m_pluginLoaded)
			return false;

		return m_plugin.doInitSync();
	}

	public string symbolicIcon()
	{
		Logger.debug("feedserver: symbolicIcon");

		if(!m_pluginLoaded)
			return "none";

		return m_plugin.symbolicIcon();
	}

	public string accountName()
	{
		if(!m_pluginLoaded)
			return "none";

		return m_plugin.accountName();
	}

	public string getServerURL()
	{
		if(!m_pluginLoaded)
			return "none";

		return m_plugin.getServerURL();
	}

	public string uncategorizedID()
	{
		if(!m_pluginLoaded)
			return "";

		return m_plugin.uncategorizedID();
	}

	public bool hideCategoryWhenEmpty(string catID)
	{
		if(!m_pluginLoaded)
			return false;

		return m_plugin.hideCategoryWhenEmpty(catID);
	}

	public bool supportCategories()
	{
		if(!m_pluginLoaded)
			return false;

		return m_plugin.supportCategories();
	}

	public bool supportFeedManipulation()
	{
		if(!m_pluginLoaded)
			return false;

		return m_plugin.supportFeedManipulation();
	}

	public bool supportMultiLevelCategories()
	{
		if(!m_pluginLoaded)
			return false;

		return m_plugin.supportMultiLevelCategories();
	}

	public bool supportMultiCategoriesPerFeed()
	{
		if(!m_pluginLoaded)
			return false;

		return m_plugin.supportMultiCategoriesPerFeed();
	}

	public bool syncFeedsAndCategories()
	{
		if(!m_pluginLoaded)
			return false;

		return m_plugin.syncFeedsAndCategories();
	}

	// some backends (inoreader, feedly) have the tag-name as part of the ID
	// but for some of them the tagID changes when the name was changed (inoreader)
	public bool tagIDaffectedByNameChange()
	{
		if(!m_pluginLoaded)
			return false;

		return m_plugin.tagIDaffectedByNameChange();
	}

	public void resetAccount()
	{
		if(!m_pluginLoaded)
			return;

		m_plugin.resetAccount();
	}

	// whether or not to use the "max-articles"-setting
	public bool useMaxArticles()
	{
		if(!m_pluginLoaded)
			return true;

		return m_plugin.useMaxArticles();
	}

	public LoginResponse login()
	{
		return m_plugin.login();
	}

	public bool logout()
	{
		if(!m_pluginLoaded)
			return false;

		return m_plugin.logout();
	}

	public void setArticleIsRead(string articleIDs, ArticleStatus read)
	{
		if(!m_pluginLoaded)
			return;

		m_plugin.setArticleIsRead(articleIDs, read);
	}

	public void setArticleIsMarked(string articleID, ArticleStatus marked)
	{
		if(!m_pluginLoaded)
			return;

		m_plugin.setArticleIsMarked(articleID, marked);
	}

	public void setFeedRead(string feedID)
	{
		if(!m_pluginLoaded)
			return;

		m_plugin.setFeedRead(feedID);
	}

	public void setCategoryRead(string catID)
	{
		if(!m_pluginLoaded)
			return;

		m_plugin.setCategoryRead(catID);
	}

	public void markAllItemsRead()
	{
		if(!m_pluginLoaded)
			return;

		m_plugin.markAllItemsRead();
	}

	public void tagArticle(string articleID, string tagID)
	{
		if(!m_pluginLoaded)
			return;

		m_plugin.tagArticle(articleID, tagID);
	}

	public void removeArticleTag(string articleID, string tagID)
	{
		if(!m_pluginLoaded)
			return;

		m_plugin.removeArticleTag(articleID, tagID);
	}

	public string createTag(string caption)
	{
		if(!m_pluginLoaded)
			return "";

		return m_plugin.createTag(caption);
	}

	public void deleteTag(string tagID)
	{
		if(!m_pluginLoaded)
			return;

		m_plugin.deleteTag(tagID);
	}

	public void renameTag(string tagID, string title)
	{
		if(!m_pluginLoaded)
			return;

		m_plugin.renameTag(tagID, title);
	}

	public bool serverAvailable()
	{
		if(!m_pluginLoaded)
			return false;

		return m_plugin.serverAvailable();
	}

	public bool addFeed(string feedURL, string? catID, string? newCatName, out string? feedID, out string errmsg)
	{
		if(!m_pluginLoaded) {
			feedID = null;
			errmsg = "Plugin not loaded";
			return false;
		}

		return m_plugin.addFeed(feedURL, catID, newCatName, out feedID, out errmsg);
	}

	public void addFeeds(Gee.List<Feed> feeds)
	{
		if(!m_pluginLoaded)
			return;

		m_plugin.addFeeds(feeds);
	}

	public void removeFeed(string feedID)
	{
		if(!m_pluginLoaded)
			return;

		m_plugin.removeFeed(feedID);
	}

	public void renameFeed(string feedID, string title)
	{
		if(!m_pluginLoaded)
			return;

		m_plugin.renameFeed(feedID, title);
	}

	public void moveFeed(string feedID, string newCatID, string? currentCatID = null)
	{
		if(!m_pluginLoaded)
			return;

		m_plugin.moveFeed(feedID, newCatID, currentCatID);
	}

	public string createCategory(string title, string? parentID = null)
	{
		if(!m_pluginLoaded)
			return "";

		return m_plugin.createCategory(title, parentID);
	}

	public void renameCategory(string catID, string title)
	{
		if(!m_pluginLoaded)
			return;

		m_plugin.renameCategory(catID, title);
	}

	public void moveCategory(string catID, string newParentID)
	{
		if(!m_pluginLoaded)
			return;

		m_plugin.moveCategory(catID, newParentID);
	}

	public void deleteCategory(string catID)
	{
		if(!m_pluginLoaded)
			return;

		m_plugin.deleteCategory(catID);
	}

	public void removeCatFromFeed(string feedID, string catID)
	{
		if(!m_pluginLoaded)
			return;

		m_plugin.removeCatFromFeed(feedID, catID);
	}

	public void importOPML(string opml)
	{
		if(!m_pluginLoaded)
			return;

		m_plugin.importOPML(opml);
	}

	public bool getFeedsAndCats(Gee.List<Feed> feeds, Gee.List<Category> categories, Gee.List<tag> tags, GLib.Cancellable? cancellable = null)
	{
		if(!m_pluginLoaded)
			return false;

		return m_plugin.getFeedsAndCats(feeds, categories, tags);
	}

	public int getUnreadCount()
	{
		if(!m_pluginLoaded)
			return 0;

		return m_plugin.getUnreadCount();
	}

	public void getArticles(int count, ArticleStatus whatToGet = ArticleStatus.ALL, string? feedID = null, bool isTagID = false, GLib.Cancellable? cancellable = null)
	{
		if(!m_pluginLoaded)
			return;

		m_plugin.getArticles(count, whatToGet, feedID, isTagID);
	}

	private void syncProgress(string text)
	{
		FeedReaderBackend.get_default().updateSyncProgress(text);
		Settings.state().set_string("sync-status", text);
	}

}
