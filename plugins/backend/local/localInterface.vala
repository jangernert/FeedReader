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

	public void init()
	{
		m_utils = new localUtils();
	}


	public bool supportTags()
	{
		return true;
	}

	public bool doInitSync()
	{
		return false;
	}

	public string? symbolicIcon()
	{
		return "feed-service-local-symbolic";
	}

	public string? accountName()
	{
		return "Local RSS";
	}

	public string? getServerURL()
	{
		return "http://localhorst/";
	}

	public string uncategorizedID()
	{
		return "0";
	}

	public bool hideCagetoryWhenEmtpy(string catID)
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
		return Utils.ping("https://www.google.com/");
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

	public void setCategorieRead(string catID)
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

	public string addFeed(string feedURL, string? catID, string? newCatName)
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

		string feedID = "feedID1";

		if(!dbDaemon.get_default().isTableEmpty("feeds"))
		{
			feedID = "feedID%i".printf(int.parse(dbDaemon.get_default().getHighestFeedID().substring(6)) + 1);
		}

		Logger.info("addFeed: ID = " + feedID);
		feed? Feed = m_utils.downloadFeed(feedURL, feedID, catIDs);

		if(Feed != null)
		{
			var list = new Gee.LinkedList<feed>();
			list.add(Feed);
			dbDaemon.get_default().write_feeds(list);
			return feedID;
		}

		return "";
	}

	public void addFeeds(Gee.LinkedList<feed> feeds)
	{
		var finishedFeeds = new Gee.LinkedList<feed>();

		int highestID = 0;

		if(!dbDaemon.get_default().isTableEmpty("feeds"))
			highestID = int.parse(dbDaemon.get_default().getHighestFeedID().substring(6)) + 1;

		foreach(feed f in feeds)
		{
			string feedID = @"feedID$highestID";
			highestID++;

			Logger.info("addFeed: ID = " + feedID);
			feed? Feed = m_utils.downloadFeed(f.getXmlUrl(), feedID, f.getCatIDs());

			if(Feed != null)
			{
				if(Feed.getTitle() != "No Title")
					Feed.setTitle(f.getTitle());

				finishedFeeds.add(Feed);
			}

			else
				Logger.error("Couldn't add Feed: " + f.getXmlUrl());
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
		string catID = "catID1";

		if(!dbDaemon.get_default().isTableEmpty("categories"))
		{
			string? id = dbDaemon.get_default().getCategoryID(title);
			if(id == null)
			{
				catID = "catID%i".printf(int.parse(dbDaemon.get_default().getMaxID("categories", "categorieID").substring(5)) + 1);
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

	public bool getFeedsAndCats(Gee.LinkedList<feed> feeds, Gee.LinkedList<category> categories, Gee.LinkedList<tag> tags)
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
			feeds.add(Feed);
		}

		return true;
	}

	public int getUnreadCount()
	{
		return 0;
	}

	public void getArticles(int count, ArticleStatus whatToGet, string? feedID, bool isTagID)
	{
		var f = dbDaemon.get_default().read_feeds();
		var articleArray = new Gee.LinkedList<article>();

		foreach(feed Feed in f)
		{
			Logger.debug("getArticles for feed: " + Feed.getTitle());
			string url = Feed.getXmlUrl().escape("");

			if(url == null || url == "" || GLib.Uri.parse_scheme(url) == null)
			{
				Logger.error("no valid URL");
				continue;
			}

			var session = new Soup.Session();
			session.user_agent = Constants.USER_AGENT;
			session.timeout = 5;
			var msg = new Soup.Message("GET", url);
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
				var date = new GLib.DateTime.now_local();

				if(item.pub_date != null)
				{
                	GLib.Time time = GLib.Time();
                	time.strptime(item.pub_date, "%a, %d %b %Y %H:%M:%S %Z");
                	date = new GLib.DateTime.local(1900 + time.year, 1 + time.month, time.day, time.hour, time.minute, time.second);

					if(date == null)
						date = new GLib.DateTime.now_local();
				}

				string content = m_utils.convert(item.description, locale);

				string media = "";
				if(item.enclosure_url != null)
					media = item.enclosure_url;

				var Article = new article
				(
									(item.guid != null) ? item.guid : Utils.string_random(16),
									(item.title != null) ? m_utils.convert(item.title, locale) : "No Title :(",
									item.link,
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
			int before = dbDaemon.get_default().getHighestRowID();
			writeInterfaceState();
			updateFeedList();
			updateArticleList();
			dbDaemon.get_default().write_articles(articleArray);
			setNewRows(before);
		}
	}

}

[ModuleInit]
public void peas_register_types(GLib.TypeModule module)
{
	var objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type(typeof(FeedReader.FeedServerInterface), typeof(FeedReader.localInterface));
}
