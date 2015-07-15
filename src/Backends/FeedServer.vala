public class FeedReader.FeedServer : GLib.Object {
	private ttrss_interface m_ttrss;
	private FeedlyAPI m_feedly;
	private int m_type;
	public signal void initSyncStage(int stage);
	public signal void initSyncTag(string tagName);
	public signal void initSyncFeed(string feedName);

	public FeedServer(int type)
	{
		m_type = type;
		logger.print(LogMessage.DEBUG, "FeedServer: new with type %i".printf(type));

		switch(m_type)
		{
			case Backend.TTRSS:
				m_ttrss = new ttrss_interface();
				break;

			case Backend.FEEDLY:
				m_feedly = new FeedlyAPI();
				break;
		}
	}

	public int getType()
	{
		return m_type;
	}

	public LoginResponse login()
	{
		switch(m_type)
		{
			case Backend.NONE:
				return LoginResponse.NO_BACKEND;

			case Backend.TTRSS:
				return m_ttrss.login();

			case Backend.FEEDLY:
				if(m_feedly.ping())
				{
					return m_feedly.login();
				}
				break;
		}
		return LoginResponse.UNKNOWN_ERROR;
	}

	public async void syncContent()
	{
		SourceFunc callback = syncContent.callback;

		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					if(!m_ttrss.isloggedin())
					{
						logger.print(LogMessage.DEBUG, "FeedServer: can't snyc - ttrss not logged in or unreachable");
						return null;
					}
					break;

				case Backend.FEEDLY:
					if(!m_feedly.ping())
					{
						logger.print(LogMessage.DEBUG, "FeedServer: can't snyc - feedly not reachable");
						return null;
					}
					break;
			}

			int before = dataBase.getHighestRowID();
			//dataBase.markReadAllArticles();

			var categories = new GLib.List<category>();
			var feeds      = new GLib.List<feed>();
			var tags       = new GLib.List<tag>();
			var articles   = new GLib.List<article>();

			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.getCategories(ref categories);
					m_ttrss.getFeeds(ref feeds, ref categories);
					m_ttrss.getTags(ref tags);
					m_ttrss.getArticles(ref articles, settings_general.get_int("max-articles"));
					break;

				case Backend.FEEDLY:
					m_feedly.getUnreadCounts();
					m_feedly.getCategories(ref categories);
					m_feedly.getFeeds(ref feeds);
					m_feedly.getTags(ref tags);
					m_feedly.getArticles(ref articles, settings_general.get_int("max-articles"));
					break;
			}

			// write categories
			dataBase.reset_exists_flag();
			dataBase.write_categories(ref categories);
			dataBase.delete_nonexisting_categories();
			if(m_type == Backend.TTRSS)
				m_ttrss.updateCategorieUnread();

			// write feeds
			dataBase.reset_subscribed_flag();
			dataBase.write_feeds(ref feeds);
			dataBase.delete_articles_without_feed();
			dataBase.delete_unsubscribed_feeds();

			// write tags
			dataBase.reset_exists_tag();
			dataBase.write_tags(ref tags);
			foreach(var tag_item in tags)
				dataBase.update_tag(tag_item.m_tagID);
			dataBase.delete_nonexisting_tags();

			// write articles
			articles.reverse();
			dataBase.write_articles(ref articles);

			int after = dataBase.getHighestRowID();
			int newArticles = after-before;
			if(newArticles > 0)
			{
				sendNotification(newArticles);
				int newCount = settings_state.get_int("articlelist-new-rows") + (int)Utils.getRelevantArticles(newArticles);
				settings_state.set_int("articlelist-new-rows", newCount);
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

			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("syncContent", run);
		yield;

		return;
	}

	public async void InitSyncContent(bool useGrabber)
	{
		SourceFunc callback = InitSyncContent.callback;
		if(!useGrabber)
			settings_general.set_enum("content-grabber", ContentGrabber.NONE);

		ThreadFunc<void*> run = () => {
			logger.print(LogMessage.DEBUG, "FeedServer: initial sync");

			var categories = new GLib.List<category>();
			var feeds      = new GLib.List<feed>();
			var tags       = new GLib.List<tag>();
			var articles   = new GLib.List<article>();

			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.getCategories(ref categories);
					initSyncStage(1);
					m_ttrss.getFeeds(ref feeds, ref categories);
					initSyncStage(2);
					m_ttrss.getTags(ref tags);
					initSyncStage(3);

					// get ALL unread articles
					m_ttrss.getArticles(ref articles, m_ttrss.getUnreadCount(), ArticleStatus.UNREAD);
					initSyncStage(4);

					// get max-articles-count of marked articles
					logger.print(LogMessage.DEBUG, "FeedServer: get marked");
					m_ttrss.getArticles(ref articles, settings_general.get_int("max-articles")/2, ArticleStatus.MARKED);
					initSyncStage(5);

					// get max-articles-count of articles for each tag
					foreach(var tag_item in tags)
					{
						initSyncTag(tag_item.m_title);
						m_ttrss.getArticles(ref articles, settings_general.get_int("max-articles")/8, ArticleStatus.ALL, int.parse(tag_item.m_tagID));
					}
					initSyncTag("");
					initSyncStage(6);

					// get max-articles-count of articles for each feed
					foreach(var feed_item in feeds)
					{
						initSyncFeed(feed_item.m_title);
						m_ttrss.getArticles(ref articles, settings_general.get_int("max-articles")/8, ArticleStatus.ALL, int.parse(feed_item.m_feedID));
					}
					initSyncFeed("");
					initSyncStage(7);
					break;

				case Backend.FEEDLY:
					m_feedly.getUnreadCounts();
					m_feedly.getCategories(ref categories);
					initSyncStage(1);
					m_feedly.getFeeds(ref feeds);
					initSyncStage(2);
					m_feedly.getTags(ref tags);
					initSyncStage(3);

					// get ALL unread articles
					m_feedly.getArticles(ref articles, m_feedly.getTotalUnread(), ArticleStatus.UNREAD);
					initSyncStage(4);

					// get max-articles-count of marked articles
					m_feedly.getArticles(ref articles, settings_general.get_int("max-articles")/2, ArticleStatus.MARKED);
					initSyncStage(5);

					// get max-articles-count of articles for each tag
					foreach(var tag_item in tags)
					{
						initSyncTag(tag_item.m_title);
						m_feedly.getArticles(ref articles, settings_general.get_int("max-articles")/8, ArticleStatus.ALL, tag_item.m_tagID);
					}
					initSyncTag("");
					initSyncStage(6);

					// get max-articles-count of articles for each feed
					foreach(var feed_item in feeds)
					{
						initSyncFeed(feed_item.m_title);
						m_feedly.getArticles(ref articles, settings_general.get_int("max-articles")/8, ArticleStatus.ALL, feed_item.m_feedID);
					}
					initSyncFeed("");
					initSyncStage(7);
					break;
			}


			// write categories
			dataBase.write_categories(ref categories);
			if(m_type == Backend.TTRSS)
				m_ttrss.updateCategorieUnread();

			// write feeds
			dataBase.write_feeds(ref feeds);

			// write tags
			dataBase.write_tags(ref tags);

			// write articles
			articles.reverse();
			dataBase.write_articles(ref articles);

			if(!useGrabber)
				settings_state.set_int("initial-sync-level", 0);
			settings_general.reset("content-grabber");


			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("InitSyncContent", run);
		yield;

		return;
	}


	public async void setArticleIsRead(string articleIDs, int read)
	{
		SourceFunc callback = setArticleIsRead.callback;

		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.updateArticleUnread(articleIDs, read);
					break;

				case Backend.FEEDLY:
					m_feedly.mark_as_read(articleIDs, "entries", read);
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("setArticleIsRead", run);
		yield;
	}

	public async void setArticleIsMarked(string articleID, int marked)
	{
		SourceFunc callback = setArticleIsMarked.callback;

		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.updateArticleMarked(int.parse(articleID), marked);
					break;

				case Backend.FEEDLY:

					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("setArticleIsMarked", run);
		yield;
	}

	public async void setFeedRead(string feedID)
	{
		SourceFunc callback = setFeedRead.callback;

		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.markFeedRead(feedID, false);
					break;

				case Backend.FEEDLY:
					m_feedly.mark_as_read(feedID, "feeds", ArticleStatus.READ);
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("setFeedRead", run);
		yield;
	}

	public async void setCategorieRead(string catID)
	{
		SourceFunc callback = setCategorieRead.callback;

		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.markFeedRead(catID, true);
					break;

				case Backend.FEEDLY:
					m_feedly.mark_as_read(catID, "categories", ArticleStatus.READ);
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("setCategorieRead", run);
		yield;
	}


	public static void sendNotification(uint headline_count)
	{
		try{
			string message;

			if(!Notify.is_initted())
			{
				logger.print(LogMessage.ERROR, "notification: libnotifiy not initialized");
				return;
			}

			if(headline_count > 0)
			{
				if(headline_count == 1)
					message = _("There is 1 new article");
				else if(headline_count == 200)
					message = _("There are >200 new articles");
				else
					message = _("There are %u new articles").printf(headline_count);

				notification = new Notify.Notification(_("New Articles"), message, "internet-news-reader");
				notification.set_urgency(Notify.Urgency.NORMAL);

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

				notification.closed.connect(() => {
					logger.print(LogMessage.DEBUG, "notification: closed");
				});

				try {
					notification.show();
				} catch (GLib.Error e) {
					logger.print(LogMessage.ERROR, e.message);
				}
			}
		}catch (GLib.Error e) {
			logger.print(LogMessage.ERROR, e.message);
		}
	}


	public static void grabContent(ref article Article)
	{
		if(settings_general.get_enum("content-grabber") == ContentGrabber.NONE)
		{
			return;
		}
		else if(settings_general.get_enum("content-grabber") == ContentGrabber.BUILTIN)
		{
			var grabber = new Grabber(Article.m_url);
			if(grabber.process())
			{
				grabber.print();
				if(Article.getAuthor() != "" && grabber.getAuthor() != null)
				{
					Article.setAuthor(grabber.getAuthor());
				}
				Article.setHTML(grabber.getArticle());
			}
		}
		else if(settings_general.get_enum("content-grabber") == ContentGrabber.READABILITY)
		{
			var grabber = new ReadabilityParserAPI(Article.m_url);
			grabber.process();
			Article.setAuthor(grabber.getAuthor());
			Article.setHTML(grabber.getContent());
			Article.setPreview(grabber.getPreview());
		}
	}
}
