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

	public void init()
	{
		m_utils = new localUtils();
		m_session = new Soup.Session();
		m_session.user_agent = Constants.USER_AGENT;
		m_session.timeout = 5;
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

		if(!dbDaemon.get_default().isTableEmpty("tags"))
			tagID = (int.parse(dbDaemon.get_default().getMaxID("tags", "tagID")) + 1).to_string();

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
		string[] catIDs = {};

		if(catID == null && newCatName != null)
		{
			string cID = createCategory(newCatName, null);
			var cat = new category(cID, newCatName, 0, 99, CategoryID.MASTER.to_string(), 1);
			var list = new Gee.LinkedList<category>();
			list.add(cat);
			dbDaemon.get_default().write_categories(list);
			catIDs += cID;
		}
		else if(catID != null && newCatName == null)
		{
			catIDs += catID;
		}
		else
		{
			catIDs += "0";
		}

		feedID = "feedID00001";

		if(!dbDaemon.get_default().isTableEmpty("feeds"))
		{
			feedID = "feedID%05d".printf(int.parse(dbDaemon.get_default().getHighestFeedID().substring(6)) + 1);
		}

		Logger.info(@"addFeed: ID = $feedID");
		feed? Feed = m_utils.downloadFeed(m_session, feedURL, feedID, catIDs, out errmsg);

		if(Feed != null)
		{
			var list = new Gee.LinkedList<feed>();
			list.add(Feed);
			dbDaemon.get_default().write_feeds(list);
			return true;
		}

		return false;
	}

	public void addFeeds(Gee.List<feed> feeds)
	{
		var finishedFeeds = new Gee.LinkedList<feed>();

		int highestID = 0;

		if(!dbDaemon.get_default().isTableEmpty("feeds"))
			highestID = int.parse(dbDaemon.get_default().getHighestFeedID().substring(6)) + 1;

		foreach(feed f in feeds)
		{
			string feedID = "feedID" + highestID.to_string("%05d");
			highestID++;

			Logger.info(@"addFeed: ID = $feedID");
			string errmsg = "";
			feed? Feed = m_utils.downloadFeed(m_session, f.getXmlUrl(), feedID, f.getCatIDs(), out errmsg);

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

		dbDaemon.get_default().write_feeds(finishedFeeds);
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

		if(!dbDaemon.get_default().isTableEmpty("categories"))
		{
			string? id = dbDaemon.get_default().getCategoryID(title);
			if(id == null)
			{
				catID = "catID%05d".printf(int.parse(dbDaemon.get_default().getMaxID("categories", "categorieID").substring(5)) + 1);
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

	public bool getFeedsAndCats(Gee.List<feed> feeds, Gee.List<category> categories, Gee.List<tag> tags, GLib.Cancellable? cancellable = null)
	{
		var cats = dbDaemon.get_default().read_categories();
		foreach(category cat in cats)
		{
			categories.add(cat);
		}

		var t = dbDaemon.get_default().read_tags();
		foreach(tag Tag in t)
		{
			tags.add(Tag);
		}

		var f = dbDaemon.get_default().read_feeds();
		foreach(feed Feed in f)
		{
			if(cancellable != null && cancellable.is_cancelled())
				return false;

			// string errmsg = "";
			// feed? tmpFeed = m_utils.downloadFeed(m_session, Feed.getXmlUrl(), Feed.getFeedID(), Feed.getCatIDs(), out errmsg);
			// if(tmpFeed != null)
			// {
			// 	Feed.setIconURL(tmpFeed.getIconURL());
			// 	Feed.setURL(tmpFeed.getURL());
			// }
			feeds.add(Feed);
		}

		return true;
	}

	public int getUnreadCount()
	{
		return 0;
	}

	public void getArticles(int count, ArticleStatus whatToGet, string? feedID, bool isTagID, GLib.Cancellable? cancellable = null)
	{
		var f = dbDaemon.get_default().read_feeds();
		var articleArray = new Gee.LinkedList<article>();

		foreach(feed Feed in f)
		{
			if(cancellable != null && cancellable.is_cancelled())
				return;

			Logger.debug("getArticles for feed: " + Feed.getTitle());
			string url = Feed.getXmlUrl().escape("");

			if(url == null || url == "" || GLib.Uri.parse_scheme(url) == null)
			{
				Logger.error("no valid URL");
				continue;
			}

			var msg = new Soup.Message("GET", url);
			m_session.send_message(msg);
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
				continue;
			}
			var doc = parser.get_document();
			string? locale = null;
			if(doc.encoding != null
			&& doc.encoding != "")
			{
				locale = doc.encoding;
			}

			var articles = doc.get_items();
			foreach(Rss.Item item in articles)
			{
				string? articleID = item.guid;

				if(articleID != null)
					articleID = articleID.replace(":", "_").replace("/", "_").replace(" ", "").replace(",", "_");
				else
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

				string media = "";
				if(item.enclosure_url != null)
					media = item.enclosure_url;

				string articleURL = item.link;
				if(articleURL.has_prefix("/"))
					articleURL = Feed.getURL() + articleURL.substring(1);


				var Article = new article
				(
									articleID,
									(item.title != null) ? m_utils.convert(item.title, locale) : "No Title :(",
									articleURL,
									Feed.getFeedID(),
									ArticleStatus.UNREAD,
									ArticleStatus.UNMARKED,
									content,
									Utils.UTF8fix(content, true),
									m_utils.convert(item.author, locale),
									date,
									0,
									"",
									media
				);

				articleArray.add(Article);
				
			}
		}

		articleArray.sort((a, b) => {
				return strcmp(a.getArticleID(), b.getArticleID());
		});

		if(articleArray.size > 0)
		{
			dbDaemon.get_default().write_articles(articleArray);
			Logger.debug("localInterface: %i articles written".printf(articleArray.size));
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
