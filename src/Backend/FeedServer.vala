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
	private string? m_plugName = null;
	private Peas.ExtensionSet m_extensions;
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
			m_plugin = (extension as FeedServerInterface);
			m_plugin.init();
			m_plugin.newFeedList.connect(() => { FeedDaemonServer.get_default().newFeedList(); });
			m_plugin.refreshFeedListCounter.connect(() => { FeedDaemonServer.get_default().refreshFeedListCounter(); });
			m_plugin.updateArticleList.connect(() => { FeedDaemonServer.get_default().updateArticleList(); });
			m_plugin.showArticleListOverlay.connect(() => { FeedDaemonServer.get_default().showArticleListOverlay(); });
			m_plugin.writeArticles.connect((articles) => { writeArticles(articles); });
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
	}

	public bool unloadPlugin()
	{
		if(m_plugName == null)
		{
			Logger.warning("feedserver.unloadPlugin: no plugin loaded");
			return false;
		}


		Logger.debug("feedserver: unload plugin %s".printf(m_plugName));
		if(m_pluginLoaded)
		{
			var plugin = m_engine.get_plugin_info(m_plugName);
			return m_engine.try_unload_plugin(plugin);
		}
		return false;
	}

	public bool loadPlugin(string plugName)
	{
		Logger.debug(@"feedserver: load plugin \"$plugName\"");
		m_plugName = plugName;
		var plugin = m_engine.get_plugin_info(plugName);

		if(plugin == null)
		{
			Logger.error(@"feedserver: failed to load info for \"$plugName\"");
			m_pluginLoaded = false;
			return false;
		}

		Logger.info("Plugin Name: " + plugin.get_name());
		Logger.info("Plugin Version: " + plugin.get_version());
		Logger.info("Plugin Website: " + plugin.get_website());
		Logger.info("Plugin Dir: " + plugin.get_module_dir());

		m_pluginLoaded = m_engine.try_load_plugin(plugin);

		if(!m_pluginLoaded)
			Logger.error("feedserver: couldn't load plugin %s".printf(m_plugName));

		return m_pluginLoaded;
	}

	public bool pluginLoaded()
	{
		return m_pluginLoaded;
	}

	public void syncContent(GLib.Cancellable? cancellable = null)
	{
		if(!serverAvailable())
		{
			Logger.debug("FeedServer: can't snyc - not logged in or unreachable");
			return;
		}

		int before = dbDaemon.get_default().getHighestRowID();

		var categories = new Gee.LinkedList<category>();
		var feeds      = new Gee.LinkedList<feed>();
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

		// download favicons for all feeds
		Utils.getFavIcons.begin(feeds, cancellable, (obj, res) => {
			Utils.getFavIcons.end(res);
			FeedDaemonServer.get_default().reloadFavIcons();
		});

		if(cancellable != null && cancellable.is_cancelled())
			return;

		// write categories
		dbDaemon.get_default().reset_exists_flag();
		dbDaemon.get_default().write_categories(categories);
		dbDaemon.get_default().delete_nonexisting_categories();

		// write feeds
		dbDaemon.get_default().reset_subscribed_flag();
		dbDaemon.get_default().write_feeds(feeds);
		dbDaemon.get_default().delete_articles_without_feed();
		dbDaemon.get_default().delete_unsubscribed_feeds();

		// write tags
		dbDaemon.get_default().reset_exists_tag();
		dbDaemon.get_default().write_tags(tags);
		dbDaemon.get_default().update_tags(tags);
		dbDaemon.get_default().delete_nonexisting_tags();

		FeedDaemonServer.get_default().newFeedList();

		if(cancellable != null && cancellable.is_cancelled())
			return;

		int unread = getUnreadCount();
		int max = ArticleSyncCount();

		syncProgress(_("Getting articles"));

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
		dbDaemon.get_default().updateFTS();

		int after = dbDaemon.get_default().getHighestRowID();
		int newArticles = after-before;
		if(newArticles > 0)
		{
			Notification.send(newArticles);
			setNewRows();
		}

		switch(Settings.general().get_enum("drop-articles-after"))
		{
			case DropArticles.NEVER:
				break;

			case DropArticles.ONE_WEEK:
				dbDaemon.get_default().dropOldArtilces(1);
				break;

			case DropArticles.ONE_MONTH:
				dbDaemon.get_default().dropOldArtilces(4);
				break;

			case DropArticles.SIX_MONTHS:
				dbDaemon.get_default().dropOldArtilces(24);
				break;
		}

		var now = new DateTime.now_local();
		Settings.state().set_int("last-sync", (int)now.to_unix());

		dbDaemon.get_default().checkpoint();

		return;
	}

	public void InitSyncContent(GLib.Cancellable? cancellable = null)
	{
		Logger.debug("FeedServer: initial sync");

		var categories = new Gee.LinkedList<category>();
		var feeds      = new Gee.LinkedList<feed>();
		var tags       = new Gee.LinkedList<tag>();

		syncProgress(_("Getting feeds and categories"));

		getFeedsAndCats(feeds, categories, tags, cancellable);

		if(cancellable != null && cancellable.is_cancelled())
			return;

		// download favicons for all feeds
		Utils.getFavIcons.begin(feeds, cancellable);

		if(cancellable != null && cancellable.is_cancelled())
			return;

		// write categories
		dbDaemon.get_default().write_categories(categories);

		// write feeds
		dbDaemon.get_default().write_feeds(feeds);

		// write tags
		dbDaemon.get_default().write_tags(tags);

		FeedDaemonServer.get_default().newFeedList();

		if(cancellable != null && cancellable.is_cancelled())
			return;

		// get marked articles
		syncProgress(_("Getting starred articles"));
		getArticles(Settings.general().get_int("max-articles"), ArticleStatus.MARKED, null, false, cancellable);

		if(cancellable != null && cancellable.is_cancelled())
			return;

		// get articles for each tag
		syncProgress(_("Getting tagged articles"));
		foreach(var tag_item in tags)
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
		dbDaemon.get_default().updateFTS();

		Settings.general().reset("content-grabber");

		var now = new DateTime.now_local();
		Settings.state().set_int("last-sync", (int)now.to_unix());

		return;
	}

	private void writeArticles(Gee.List<article> articles)
	{
		if(articles.size > 0)
		{
			dbDaemon.get_default().update_articles(articles);

			// Reverse the list
			var new_articles = new Gee.LinkedList<article>();
			foreach(var article in articles)
			{
				new_articles.insert(0, article);
			}

			dbDaemon.get_default().write_articles(new_articles);
			FeedDaemonServer.get_default().refreshFeedListCounter();
			FeedDaemonServer.get_default().updateArticleList();
		}
	}

	private void setNewRows()
	{
		if(!Settings.state().get_boolean("ui-running") && Settings.state().get_enum("show-articles") == ArticleListState.ALL)
		{
			int newCount = (int)UtilsDaemon.getRelevantArticles();
			Logger.debug(@"UI NOT running: setting \"articlelist-new-rows\" to $newCount");
			Settings.state().set_int("articlelist-new-rows", newCount);
		}
	}

	public void grabContent(GLib.Cancellable? cancellable = null)
	{
		Logger.debug("FeedServer: grabContent");
		var articles = dbDaemon.get_default().readUnfetchedArticles();
		int size = articles.size;
		int i = 0;

		if(size > 0)
		{
			var session = new Soup.Session();
			session.user_agent = Constants.USER_AGENT;
			session.timeout = 5;
			session.ssl_strict = false;

			foreach(var Article in articles)
			{
				if(cancellable != null && cancellable.is_cancelled())
					break;

				++i;
				syncProgress(_(@"Grabbing full content: $i / $size"));
				if(Settings.general().get_boolean("content-grabber"))
				{
					var grabber = new Grabber(session, Article.getURL(), Article.getArticleID(), Article.getFeedID());
					if(grabber.process(cancellable))
					{
						grabber.print();
						if(Article.getAuthor() != "" && grabber.getAuthor() != null)
						{
							Article.setAuthor(grabber.getAuthor());
						}
						if(Article.getTitle() != "" && grabber.getTitle() != null)
						{
							Article.setTitle(grabber.getTitle());
						}
						string html = grabber.getArticle();
						string xml = "<?xml";

						while(html.has_prefix(xml))
						{
							int end = html.index_of_char('>');
							html = html.slice(end+1, html.length).chug();
						}

						Article.setHTML(html);
					}
					else
					{
						downloadImages(session, Article, cancellable);
					}
				}
				else
				{
					downloadImages(session, Article, cancellable);
				}

				if(cancellable == null || !cancellable.is_cancelled())
					dbDaemon.get_default().writeContent(Article);
			}

			//update fulltext table
			dbDaemon.get_default().updateFTS();
		}
	}

	private void downloadImages(Soup.Session session, article Article, GLib.Cancellable? cancellable = null)
	{
		if(!Settings.general().get_boolean("download-images"))
			return;

		var html_cntx = new Html.ParserCtxt();
		html_cntx.use_options(Html.ParserOption.NOERROR + Html.ParserOption.NOWARNING);
		Html.Doc* doc = html_cntx.read_doc(Article.getHTML(), "");
		if(doc == null)
		{
			Logger.debug("Grabber: parsing failed");
			return;
		}
		grabberUtils.fixIframeSize(doc, "youtube.com");
		grabberUtils.repairURL("//img", "src", doc, Article.getURL());
		grabberUtils.repairURL("//iframe", "src", doc, Article.getURL());
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

		grabberUtils.saveImages(session, doc, Article.getArticleID(), Article.getFeedID(), cancellable);

		string html = "";
		doc->dump_memory_enc(out html);
		html = grabberUtils.postProcessing(ref html);
		Article.setHTML(html);
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

	public bool addFeed(string feedURL, string? catID, string? newCatName, out string feedID, out string errmsg)
	{
		if(!m_pluginLoaded)
			return false;

		return m_plugin.addFeed(feedURL, catID, newCatName, out feedID, out errmsg);
	}

	public void addFeeds(Gee.List<feed> feeds)
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

	public bool getFeedsAndCats(Gee.List<feed> feeds, Gee.List<category> categories, Gee.List<tag> tags, GLib.Cancellable? cancellable = null)
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
		FeedDaemonServer.get_default().updateSyncProgress(text);
		Settings.state().set_string("sync-status", text);
	}

}
