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
	private FeedServerInterface m_plugin;
	public signal void newFeedList();
	public signal void updateFeedList();
	public signal void updateArticleList();
	public signal void writeInterfaceState();
	public signal void showArticleListOverlay();

	public FeedServer(string plug_name)
	{
		var engine = Peas.Engine.get_default();
		engine.add_search_path(InstallPrefix + "/share/FeedReader/plugins/", null);
		engine.enable_loader("python3");

		var extensions = new Peas.ExtensionSet(engine, typeof(FeedServerInterface),
			"m_dataBase", dataBase,
			"m_logger", logger);

		extensions.extension_added.connect((info, extension) => {
			m_plugin = (extension as FeedServerInterface);
			m_plugin.init();
			m_plugin.newFeedList.connect(() => { newFeedList(); });
			m_plugin.updateFeedList.connect(() => { updateFeedList(); });
			m_plugin.updateArticleList.connect(() => { updateArticleList(); });
			m_plugin.writeInterfaceState.connect(() => { writeInterfaceState(); });
			m_plugin.showArticleListOverlay.connect(() => { showArticleListOverlay(); });
			m_plugin.setNewRows.connect((before) => { setNewRows(before); });
			m_plugin.writeArticlesInChunks.connect((articles, chunksize) => { writeArticlesInChunks(articles, chunksize); });
		});

		extensions.extension_removed.connect((info, extension) => {

		});

		var plugin = engine.get_plugin_info(plug_name);

		if(plugin != null)
			m_pluginLoaded = engine.try_load_plugin(plugin);
		else
			m_pluginLoaded = false;
	}

	public bool pluginLoaded()
	{
		return m_pluginLoaded;
	}

	public void syncContent()
	{
		if(!serverAvailable())
		{
			logger.print(LogMessage.DEBUG, "FeedServer: can't snyc - not logged in or unreachable");
			return;
		}

		int before = dataBase.getHighestRowID();

		var categories = new Gee.LinkedList<category>();
		var feeds      = new Gee.LinkedList<feed>();
		var tags       = new Gee.LinkedList<tag>();

		getFeedsAndCats(feeds, categories, tags);

		// write categories
		dataBase.reset_exists_flag();
		dataBase.write_categories(categories);
		dataBase.delete_nonexisting_categories();

		// write feeds
		dataBase.reset_subscribed_flag();
		dataBase.write_feeds(feeds);
		dataBase.delete_articles_without_feed();
		dataBase.delete_unsubscribed_feeds();

		// write tags
		dataBase.reset_exists_tag();
		dataBase.write_tags(tags);
		dataBase.update_tags(tags);
		dataBase.delete_nonexisting_tags();

		newFeedList();

		int unread = getUnreadCount();
		int max = ArticleSyncCount();

		if(unread > max && useMaxArticles())
		{
			getArticles(20, ArticleStatus.MARKED);
			getArticles(unread, ArticleStatus.UNREAD);
		}
		else
		{
			getArticles(max);
		}


		//update fulltext table
		dataBase.updateFTS();

		int after = dataBase.getHighestRowID();
		int newArticles = after-before;
		if(newArticles > 0)
		{
			sendNotification(newArticles);
			showArticleListOverlay();
		}

		switch(settings_general.get_enum("drop-articles-after"))
		{
			case DropArticles.NEVER:
	            break;

			case DropArticles.ONE_WEEK:
				dataBase.dropOldArtilces(1);
				break;

			case DropArticles.ONE_MONTH:
				dataBase.dropOldArtilces(4);
				break;

			case DropArticles.SIX_MONTHS:
				dataBase.dropOldArtilces(24);
				break;
		}

		var now = new DateTime.now_local();
		settings_state.set_int("last-sync", (int)now.to_unix());

		dataBase.checkpoint();

		return;
	}

	public void InitSyncContent()
	{
		logger.print(LogMessage.DEBUG, "FeedServer: initial sync");

		var categories = new Gee.LinkedList<category>();
		var feeds      = new Gee.LinkedList<feed>();
		var tags       = new Gee.LinkedList<tag>();

		getFeedsAndCats(feeds, categories, tags);

		// write categories
		dataBase.write_categories(categories);

		// write feeds
		dataBase.write_feeds(feeds);

		// write tags
		dataBase.write_tags(tags);

		newFeedList();

		// get marked articles
		getArticles(settings_general.get_int("max-articles"), ArticleStatus.MARKED);

		// get articles for each tag
		foreach(var tag_item in tags)
		{
			getArticles((settings_general.get_int("max-articles")/8), ArticleStatus.ALL, tag_item.getTagID(), true);
		}

		if(useMaxArticles())
		{
			//get max-articls amunt like normal sync
			getArticles(settings_general.get_int("max-articles"));
		}

		// get unread articles
		getArticles(getUnreadCount(), ArticleStatus.UNREAD);

		//update fulltext table
		dataBase.updateFTS();

		settings_general.reset("content-grabber");

		var now = new DateTime.now_local();
		settings_state.set_int("last-sync", (int)now.to_unix());

		return;
	}

	private void writeArticlesInChunks(Gee.LinkedList<article> articles, int chunksize)
	{
		if(articles.size > 0)
		{
			string last = articles.first().getArticleID();
			dataBase.update_articles(articles);
			updateFeedList();
			updateArticleList();
			var new_articles = new Gee.LinkedList<article>();

			var it = articles.bidir_list_iterator();
			for (var has_next = it.last(); has_next; has_next = it.previous())
			{
				article Article = it.get();
				FeedServer.grabContent(Article);
				new_articles.add(Article);

				if(new_articles.size == chunksize || Article.getArticleID() == last)
				{
					int before = dataBase.getHighestRowID();
					dataBase.write_articles(new_articles);
					new_articles = new Gee.LinkedList<article>();
					setNewRows(before);
				}
			}
		}
	}

	private void setNewRows(int before)
	{
		int after = dataBase.getHighestRowID();
		int newArticles = after-before;

		if(newArticles > 0)
		{
			logger.print(LogMessage.DEBUG, "FeedServer: new articles: %i".printf(newArticles));
			writeInterfaceState();
			updateFeedList();
			updateArticleList();

			if(settings_state.get_boolean("no-animations"))
			{
				logger.print(LogMessage.DEBUG, "UI NOT running: setting \"articlelist-new-rows\"");
				int newCount = settings_state.get_int("articlelist-new-rows") + (int)Utils.getRelevantArticles(newArticles);
				settings_state.set_int("articlelist-new-rows", newCount);
			}
		}
	}


	private void sendNotification(uint newArticles)
	{
		try{
			string message = "";
			string summary = _("New Articles");
			uint unread = dataBase.get_unread_total();

			if(!Notify.is_initted())
			{
				logger.print(LogMessage.ERROR, "notification: libnotifiy not initialized");
				return;
			}

			if(newArticles > 0)
			{
				if(unread == 1)
					message = _("There is 1 new article (%u unread)").printf(unread);
				else
					message = _("There are %u new articles (%u unread)").printf(newArticles, unread);


				if(notification == null)
				{
					notification = new Notify.Notification(summary, message, AboutInfo.iconName);
					notification.set_urgency(Notify.Urgency.NORMAL);
					notification.set_app_name(AboutInfo.programmName);
					notification.set_hint("desktop-entry", new Variant ("(s)", "feedreader"));

					if(m_notifyActionSupport)
					{
						notification.add_action ("default", "Show FeedReader", (notification, action) => {
							logger.print(LogMessage.DEBUG, "notification: default action");
							try {
								notification.close();
							} catch (Error e) {
								logger.print(LogMessage.ERROR, e.message);
							}

							string[] spawn_args = {"feedreader"};
							try{
								GLib.Process.spawn_async("/", spawn_args, null , GLib.SpawnFlags.SEARCH_PATH, null, null);
							}catch(GLib.SpawnError e){
								logger.print(LogMessage.ERROR, "spawning command line: %s".printf(e.message));
							}
						});
					}
				}
				else
				{
					notification.update(summary, message, AboutInfo.iconName);
				}

				notification.show();
			}
		}catch (GLib.Error e) {
			logger.print(LogMessage.ERROR, e.message);
		}
	}


	public static void grabContent(article Article)
	{
		if(!dataBase.article_exists(Article.getArticleID()))
		{
			if(settings_general.get_boolean("content-grabber"))
			{
				var grabber = new Grabber(Article.getURL(), Article.getArticleID(), Article.getFeedID());
				if(grabber.process())
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

					return;
				}
			}

			downloadImages(Article);
		}
	}

	private static void downloadImages(article Article)
	{
		var html_cntx = new Html.ParserCtxt();
        html_cntx.use_options(Html.ParserOption.NOERROR + Html.ParserOption.NOWARNING);
        Html.Doc* doc = html_cntx.read_doc(Article.getHTML(), "");
        if (doc == null)
        {
            logger.print(LogMessage.DEBUG, "Grabber: parsing failed");
    		return;
    	}
		grabberUtils.repairURL("//img", "src", doc, Article.getURL());
		grabberUtils.stripNode(doc, "//a[not(node())]");
		grabberUtils.removeAttributes(doc, null, "style");
        grabberUtils.removeAttributes(doc, "a", "onclick");
        grabberUtils.removeAttributes(doc, "img", "srcset");
        grabberUtils.removeAttributes(doc, "img", "sizes");
		grabberUtils.saveImages(doc, Article.getArticleID(), Article.getFeedID());

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

		return settings_general.get_int("max-articles");
	}

	public static void grabArticle(string url)
	{
		var grabber = new Grabber(url, null, null);
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

			string path = GLib.Environment.get_home_dir() + "/debug-article/%s.html".printf(title);

			if(FileUtils.test(path, GLib.FileTest.EXISTS))
				GLib.FileUtils.remove(path);

			var file = GLib.File.new_for_path(path);
			var stream = file.create(FileCreateFlags.REPLACE_DESTINATION);

			stream.write(html.data);
			logger.print(LogMessage.DEBUG, "Grabber: article html written to " + path);

			string output = libVilistextum.parse(html, 1);

			if(output == "" || output == null)
			{
				logger.print(LogMessage.ERROR, "could not generate preview text");
				return;
			}

			output = output.replace("\n"," ");
			output = output.replace("_"," ");

			path = GLib.Environment.get_home_dir() + "/debug-article/%s.txt".printf(title);

			if(FileUtils.test(path, GLib.FileTest.EXISTS))
				GLib.FileUtils.remove(path);

			file = GLib.File.new_for_path(path);
			stream = file.create(FileCreateFlags.REPLACE_DESTINATION);

			stream.write(output.data);
			logger.print(LogMessage.DEBUG, "Grabber: preview written to " + path);
		}
		else
		{
			logger.print(LogMessage.ERROR, "Grabber: article could not be processed " + url);
		}
	}

	public static void grabImages(string htmlFile, string url)
	{
		var html_cntx = new Html.ParserCtxt();
        html_cntx.use_options(Html.ParserOption.NOERROR + Html.ParserOption.NOWARNING);
        Html.Doc* doc = html_cntx.read_file(htmlFile);
        if (doc == null)
        {
            logger.print(LogMessage.DEBUG, "Grabber: parsing failed");
    		return;
    	}
		grabberUtils.repairURL("//img", "src", doc, url);
		grabberUtils.saveImages(doc, "", "");

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

		var file = GLib.File.new_for_path(GLib.Environment.get_home_dir() + "/debug-article/ArticleLocalImages.html");
		var stream = file.create(FileCreateFlags.REPLACE_DESTINATION);
		stream.write(html.data);
		delete doc;
	}

	public bool supportTags()
	{
		if(!m_pluginLoaded)
			return false;

		return m_plugin.supportTags();
	}

	public string? symbolicIcon()
	{
		if(!m_pluginLoaded)
			return null;

		return m_plugin.symbolicIcon();
	}

	public string? accountName()
	{
		if(!m_pluginLoaded)
			return null;

		return m_plugin.accountName();
	}

	public string? getServerURL()
	{
		if(!m_pluginLoaded)
			return null;

		return m_plugin.getServerURL();
	}

	public string uncategorizedID()
	{
		if(!m_pluginLoaded)
			return "";

		return m_plugin.uncategorizedID();
	}

	public bool hideCagetoryWhenEmtpy(string catID)
	{
		if(!m_pluginLoaded)
			return false;

		return m_plugin.hideCagetoryWhenEmtpy(catID);
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

	public void setCategorieRead(string catID)
	{
		if(!m_pluginLoaded)
			return;

		m_plugin.setCategorieRead(catID);
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

	public void addFeed(string feedURL, string? catID = null, string? newCatName = null)
	{
		if(!m_pluginLoaded)
			return;

		m_plugin.addFeed(feedURL, catID, newCatName);
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

	public void getFeedsAndCats(Gee.LinkedList<feed> feeds, Gee.LinkedList<category> categories, Gee.LinkedList<tag> tags)
	{
		if(!m_pluginLoaded)
			return;

		m_plugin.getFeedsAndCats(feeds, categories, tags);
	}

	public int getUnreadCount()
	{
		if(!m_pluginLoaded)
			return 0;

		return m_plugin.getUnreadCount();
	}

	public void getArticles(int count, ArticleStatus whatToGet = ArticleStatus.ALL, string? feedID = null, bool isTagID = false)
	{
		if(!m_pluginLoaded)
			return;

		m_plugin.getArticles(count, whatToGet, feedID, isTagID);
	}

}
