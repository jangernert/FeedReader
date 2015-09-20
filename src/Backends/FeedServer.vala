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

public class FeedReader.FeedServer : GLib.Object {
	private ttrss_interface m_ttrss;
	private FeedlyAPI m_feedly;
	private OwncloudNewsAPI m_owncloud;
	private int m_type;
	private bool m_supportTags;
	public signal void newFeedList();
	public signal void newArticleList();

	public FeedServer(Backend type)
	{
		m_type = type;
		m_supportTags = false;
		logger.print(LogMessage.DEBUG, "FeedServer: new with type %i".printf(type));

		switch(m_type)
		{
			case Backend.TTRSS:
				m_ttrss = new ttrss_interface();
				break;

			case Backend.FEEDLY:
				m_feedly = new FeedlyAPI();
				break;

			case Backend.OWNCLOUD:
				m_owncloud = new OwncloudNewsAPI();
				break;
		}
	}

	public int getType()
	{
		return m_type;
	}

	public bool supportTags()
	{
		return m_supportTags;
	}

	public LoginResponse login()
	{
		switch(m_type)
		{
			case Backend.NONE:
				return LoginResponse.NO_BACKEND;

			case Backend.TTRSS:
				var response = m_ttrss.login();
				m_supportTags = false;
				m_ttrss.supportTags.begin((obj, res) => {
					m_supportTags = m_ttrss.supportTags.end(res);
				});

				return response;

			case Backend.FEEDLY:
				if(m_feedly.ping())
				{
					m_supportTags = true;
					return m_feedly.login();
				}
				break;

			case Backend.OWNCLOUD:
				return m_owncloud.login();
		}
		return LoginResponse.UNKNOWN_ERROR;
	}

	public async void syncContent()
	{
		SourceFunc callback = syncContent.callback;

		ThreadFunc<void*> run = () => {

			if(!serverAvailable())
			{
				logger.print(LogMessage.DEBUG, "FeedServer: can't snyc - not logged in or unreachable");
				Idle.add((owned) callback);
				return null;
			}

			int before = dataBase.getHighestRowID();

			var categories = new GLib.List<category>();
			var feeds      = new GLib.List<feed>();
			var tags       = new GLib.List<tag>();
			var articles   = new GLib.List<article>();

			getFeedsAndCats(ref feeds, ref categories, ref tags);

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
				dataBase.update_tag(tag_item.getTagID());
			dataBase.delete_nonexisting_tags();

			newFeedList();

			getArticles(settings_general.get_int("max-articles")-10);

			//update fulltext table
			dataBase.updateFTS();

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

			var now = new DateTime.now_local();
			settings_state.set_int("last-sync", (int)now.to_unix());

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
		int max = settings_general.get_int("max-articles")-10;

		if(!useGrabber)
			settings_general.set_enum("content-grabber", ContentGrabber.NONE);

		ThreadFunc<void*> run = () => {
			logger.print(LogMessage.DEBUG, "FeedServer: initial sync");

			var categories = new GLib.List<category>();
			var feeds      = new GLib.List<feed>();
			var tags       = new GLib.List<tag>();

			getFeedsAndCats(ref feeds, ref categories, ref tags);

			// write categories
			dataBase.write_categories(ref categories);
			if(m_type == Backend.TTRSS)
				m_ttrss.updateCategorieUnread();

			// write feeds
			dataBase.write_feeds(ref feeds);

			// write tags
			dataBase.write_tags(ref tags);

			newFeedList();

			// get unread articles
			//getArticles(getUnreadCount()-10, ArticleStatus.UNREAD);

			// get marked articles
			getArticles(settings_general.get_int("max-articles")-10, ArticleStatus.MARKED);

			// get articles for each tag
			foreach(var tag_item in tags)
			{
				getArticles((settings_general.get_int("max-articles")/8)-10, ArticleStatus.ALL, tag_item.getTagID(), true);
			}

			// get articles for each feed
			//foreach(var feed_item in feeds)
			//{
			//	getArticles((settings_general.get_int("max-articles")/8)-10, ArticleStatus.ALL, feed_item.getFeedID());
			//}

			//update fulltext table
			dataBase.updateFTS();

			settings_general.reset("content-grabber");

			var now = new DateTime.now_local();
			settings_state.set_int("last-sync", (int)now.to_unix());

			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("InitSyncContent", run);
		yield;

		return;
	}


	public async void setArticleIsRead(string articleIDs, ArticleStatus read)
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

				case Backend.OWNCLOUD:
					m_owncloud.updateArticleUnread(articleIDs, read);
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("setArticleIsRead", run);
		yield;
	}

	public async void setArticleIsMarked(string articleID, ArticleStatus marked)
	{
		SourceFunc callback = setArticleIsMarked.callback;

		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.updateArticleMarked(int.parse(articleID), marked);
					break;

				case Backend.FEEDLY:
					m_feedly.setArticleIsMarked(articleID, marked);
					break;

				case Backend.OWNCLOUD:
					m_owncloud.updateArticleMarked(articleID, marked);
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

				case Backend.OWNCLOUD:
					m_owncloud.markFeedRead(feedID, false);
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

				case Backend.OWNCLOUD:
					m_owncloud.markFeedRead(catID, true);
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("setCategorieRead", run);
		yield;
	}

	public async void markAllItemsRead()
	{
		SourceFunc callback = markAllItemsRead.callback;

		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.markAllItemsRead();
					break;

				case Backend.FEEDLY:
					var categories = dataBase.read_categories();
					foreach(category cat in categories)
					{
						m_feedly.mark_as_read(cat.getCatID(), "categories", ArticleStatus.READ);
					}

					var feeds = dataBase.read_feeds_without_cat();
					foreach(feed Feed in feeds)
					{
						m_feedly.mark_as_read(Feed.getFeedID(), "feeds", ArticleStatus.READ);
					}
					break;

				case Backend.OWNCLOUD:
					m_owncloud.markAllItemsRead();
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("markAllItemsRead", run);
		yield;
	}


	public async void addArticleTag(string articleID, string tagID)
	{
		SourceFunc callback = addArticleTag.callback;

		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.addArticleTag(int.parse(articleID), int.parse(tagID), true);
					break;

				case Backend.FEEDLY:
					m_feedly.addArticleTag(articleID, tagID);
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("addArticleTag", run);
		yield;
	}


	public async void removeArticleTag(string articleID, string tagID)
	{
		SourceFunc callback = removeArticleTag.callback;

		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.addArticleTag(int.parse(articleID), int.parse(tagID), false);
					break;

				case Backend.FEEDLY:
					m_feedly.deleteArticleTag(articleID, tagID);
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("removeArticleTag", run);
		yield;
	}

	public string createTag(string caption)
	{
		string tagID = "";
		switch(m_type)
		{
			case Backend.TTRSS:
				tagID = m_ttrss.createTag(caption).to_string();
				break;

			case Backend.FEEDLY:
				tagID = m_feedly.createTag(caption);
				break;
		}
		return tagID;
	}

	public async void deleteTag(string tagID)
	{
		SourceFunc callback = deleteTag.callback;

		ThreadFunc<void*> run = () => {
			switch(m_type)
			{
				case Backend.TTRSS:
					m_ttrss.deleteTag(int.parse(tagID));
					break;

				case Backend.FEEDLY:
					m_feedly.deleteTag(tagID);
					break;
			}
			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("deleteTag", run);
		yield;
	}


	private bool serverAvailable()
	{
		switch(m_type)
		{
			case Backend.TTRSS:
				return m_ttrss.isloggedin();

			case Backend.FEEDLY:
				return m_feedly.ping();

			case Backend.OWNCLOUD:
				//return m_owncloud.ping();
				return true;
		}

		return false;
	}

	private void getFeedsAndCats(ref GLib.List<feed> feeds, ref GLib.List<category> categories, ref GLib.List<tag> tags)
	{
		switch(m_type)
		{
			case Backend.TTRSS:
				m_ttrss.getCategories(ref categories);
				m_ttrss.getFeeds(ref feeds, ref categories);
				m_ttrss.getTags(ref tags);
				return;

			case Backend.FEEDLY:
				m_feedly.getUnreadCounts();
				m_feedly.getCategories(ref categories);
				m_feedly.getFeeds(ref feeds);
				m_feedly.getTags(ref tags);
				return;

			case Backend.OWNCLOUD:
				m_owncloud.getFeeds(ref feeds);
				m_owncloud.getCategories(ref categories, ref feeds);
				return;
		}
	}

	private int getUnreadCount()
	{
		switch(m_type)
		{
			case Backend.TTRSS:
				return m_ttrss.getUnreadCount();

			case Backend.FEEDLY:
				return m_feedly.getTotalUnread();

			case Backend.OWNCLOUD:
				return -1;
		}

		return 0;
	}

	private void getArticles(int count, ArticleStatus whatToGet = ArticleStatus.ALL, string feedID = "", bool isTagID = false)
	{
		string continuation = "";

		for(int i = count; i >= 0; i=i-10)
		{
			var articles = new GLib.List<article>();

			switch(m_type)
			{
				case Backend.TTRSS:
					int ttrss_feedID = 0;
					if(feedID == "")
						ttrss_feedID = TTRSSSpecialID.ALL;
					else
						ttrss_feedID = int.parse(feedID);

					m_ttrss.getArticles(ref articles, i, 10, whatToGet, ttrss_feedID);
					break;

				case Backend.FEEDLY:
					string feedly_tagID = "";
					string feedly_feedID = "";
					if(feedID != "")
					{
						if(isTagID)
						{
							feedly_tagID = feedID;
						}
						else
						{
							feedly_feedID = feedID;
						}
					}
					continuation = m_feedly.getArticles(ref articles, 10, continuation, whatToGet, feedly_tagID, feedly_feedID);
					break;

				case Backend.OWNCLOUD:
					OwnCloudType type = OwnCloudType.ALL;
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
							type = OwnCloudType.STARRED;
							break;
					}

					if(feedID != "")
					{
						if(isTagID == true)
							return;

						id = int.parse(feedID);
						type = OwnCloudType.FEED;
					}

					m_owncloud.getArticles(ref articles, i, 10, read, type, id);
					break;
			}

			// write articles
			articles.reverse();
			dataBase.write_articles(ref articles);

			newArticleList();

			if(m_type == Backend.FEEDLY && continuation == "")
				break;
		}
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
		if(settings_general.get_enum("content-grabber") == ContentGrabber.BUILTIN)
		{
			var grabber = new Grabber(Article.getURL(), Article.getArticleID(), Article.getFeedID());
			if(grabber.process())
			{
				grabber.print();
				if(Article.getAuthor() != "" && grabber.getAuthor() != null)
				{
					Article.setAuthor(grabber.getAuthor());
				}
				Article.setHTML(grabber.getArticle());

				return;
			}
		}
		else if(settings_general.get_enum("content-grabber") == ContentGrabber.READABILITY)
		{
			var grabber = new ReadabilityParserAPI(Article.getURL());
			grabber.process();
			Article.setAuthor(grabber.getAuthor());
			Article.setHTML(grabber.getContent());
			Article.setPreview(grabber.getPreview());
		}

		downloadImages(ref Article);
	}

	private static void downloadImages(ref article Article)
	{
		var html_cntx = new Html.ParserCtxt();
        html_cntx.use_options(Html.ParserOption.NOERROR + Html.ParserOption.NOWARNING);
        var doc = html_cntx.read_doc(Article.getHTML(), "");
        if (doc == null)
        {
            logger.print(LogMessage.DEBUG, "Grabber: parsing failed");
    		return;
    	}

		grabberUtils.saveImages(doc, Article.getArticleID(), Article.getFeedID());

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

		Article.setHTML(html);
		delete doc;
	}
}
