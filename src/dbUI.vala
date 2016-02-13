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

public class FeedReader.dbUI : GLib.Object {

	protected Sqlite.Database sqlite_db;
	public signal void updateBadge();

	public dbUI(string dbFile = "feedreader-03.db")
	{
		string db_path = GLib.Environment.get_home_dir() + "/.local/share/feedreader/data/";
		var path = GLib.File.new_for_path(db_path);
		if(!path.query_exists())
		{
			try{
				path.make_directory_with_parents();
			}
			catch(GLib.Error e){
				logger.print(LogMessage.ERROR, "Can't create directory for database: %s".printf(e.message));
			}
		}
		int rc = Sqlite.Database.open_v2(db_path + dbFile, out sqlite_db);
		if (rc != Sqlite.OK) {
			logger.print(LogMessage.ERROR, "Can't open database: %d: %s".printf(sqlite_db.errcode(), sqlite_db.errmsg()));
		}
		sqlite_db.busy_timeout(1000);
	}

	public void init()
	{
			executeSQL("PRAGMA journal_mode = WAL");
			executeSQL("PRAGMA page_size = 4096");

			executeSQL(					"""CREATE  TABLE  IF NOT EXISTS "main"."feeds"
											(
												"feed_id" TEXT PRIMARY KEY NOT NULL UNIQUE,
												"name" TEXT NOT NULL,
												"url" TEXT NOT NULL,
												"has_icon" INTEGER NOT NULL,
												"category_id" TEXT,
												"subscribed" INTEGER DEFAULT 1
											)""");

			executeSQL(					"""CREATE  TABLE  IF NOT EXISTS "main"."categories"
											(
												"categorieID" TEXT PRIMARY KEY NOT NULL UNIQUE,
												"title" TEXT NOT NULL,
												"orderID" INTEGER,
												"exists" INTEGER,
												"Parent" TEXT,
												"Level" INTEGER
												)""");

			executeSQL(					"""CREATE  TABLE  IF NOT EXISTS "main"."articles"
											(
												"articleID" TEXT PRIMARY KEY NOT NULL UNIQUE,
												"feedID" TEXT NOT NULL,
												"title" TEXT NOT NULL,
												"author" TEXT,
												"url" TEXT NOT NULL,
												"html" TEXT NOT NULL,
												"preview" TEXT NOT NULL,
												"unread" INTEGER NOT NULL,
												"marked" INTEGER NOT NULL,
												"tags" TEXT,
												"date" DATETIME NOT NULL,
												"guidHash" TEXT,
												"lastModified" INTEGER
											)""");

			executeSQL(					   """CREATE  TABLE  IF NOT EXISTS "main"."tags"
											(
												"tagID" TEXT PRIMARY KEY NOT NULL UNIQUE,
												"title" TEXT NOT NULL,
												"exists" INTEGER,
												"color" INTEGER
											)""");

			executeSQL(					   """CREATE  TABLE  IF NOT EXISTS "main"."OfflineActions"
											(
												"action" INTEGER NOT NULL,
												"id" TEXT NOT NULL,
												"argument" INTEGER
											)""");

			executeSQL(			 			"""CREATE INDEX IF NOT EXISTS "index_articles" ON "articles" ("feedID" DESC, "unread" ASC, "marked" ASC)""");
			executeSQL(						"""CREATE VIRTUAL TABLE fts_table USING fts4 (content='articles', articleID, preview, title, author)""");
	}

	protected void executeSQL(string sql)
	{
		string errmsg;
		int ec = sqlite_db.exec (sql, null, out errmsg);
		if (ec != Sqlite.OK) {
			logger.print(LogMessage.ERROR, sql);
			logger.print(LogMessage.ERROR, errmsg);
		}
	}

	public bool isEmpty()
	{
		if(!isTableEmpty("articles"))
		{
			return false;
		}

		if(!isTableEmpty("categories"))
		{
			return false;
		}

		if(!isTableEmpty("feeds"))
		{
			return false;
		}

		if(!isTableEmpty("tags"))
		{
			return false;
		}

		return true;
	}

	public bool isTableEmpty(string table)
	{
		var query = new QueryBuilder(QueryType.SELECT, "main.%s".printf(table));
		query.selectField("count(*)");
		query.build();

		int count = -1;
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, "%d: %s".printf(sqlite_db.errcode (), sqlite_db.errmsg ()));


		int cols = stmt.column_count ();
		while (stmt.step () == Sqlite.ROW) {
			for (int i = 0; i < cols; i++) {
				count = stmt.column_int(i);
			}
		}
		stmt.reset ();

		if(count > 0)
			return false;
		else
			return true;
	}

	public int getArticelCount()
	{
		int count = -1;

		var query = new QueryBuilder(QueryType.SELECT, "main.articles");
		query.selectField("count(*)");
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, "%d: %s".printf(sqlite_db.errcode (), sqlite_db.errmsg ()));

		int cols = stmt.column_count ();
		while (stmt.step () == Sqlite.ROW) {
			for (int i = 0; i < cols; i++) {
				count = stmt.column_int(i);
			}
		}
		stmt.reset ();

		return count;
	}

	public uint get_unread_total()
	{
		var query = new QueryBuilder(QueryType.SELECT, "main.articles");
		query.selectField("count(*)");
		query.addEqualsCondition("unread", ArticleStatus.UNREAD.to_string());
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, "%d: %s".printf(sqlite_db.errcode(), sqlite_db.errmsg()));

		uint unread = 0;
		while (stmt.step () == Sqlite.ROW) {
			unread = stmt.column_int(0);
		}

		stmt.reset ();
		return unread;
	}

	public uint get_unread_uncategorized()
	{
		var query = new QueryBuilder(QueryType.SELECT, "main.articles");
		query.selectField("count(*)");
		query.addEqualsCondition("unread", ArticleStatus.UNREAD.to_string());
		query.addCustomCondition(getUncategorizedFeedsQuery());
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, "%d: %s".printf(sqlite_db.errcode(), sqlite_db.errmsg()));

		int unread = 0;
		while (stmt.step() == Sqlite.ROW) {
			unread = stmt.column_int(0);
		}
		stmt.reset();
		return unread;
	}

	public int getTagColor()
	{
		var query = new QueryBuilder(QueryType.SELECT, "main.tags");
		query.selectField("count(*)");
		query.addCustomCondition("instr(tagID, \"global.\") = 0");
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		int tagCount = 0;
		while (stmt.step () == Sqlite.ROW) {
			tagCount = stmt.column_int(0);
		}
		stmt.reset ();

		return (tagCount % COLORS.length);
	}

	public string read_preview(string articleID)
	{
		var query = new QueryBuilder(QueryType.SELECT, "main.articles");
		query.selectField("preview");
		query.addEqualsCondition("articleID", articleID, true, true);
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, "reading preview - %s".printf(sqlite_db.errmsg()));

		string result = "";

		while (stmt.step () == Sqlite.ROW) {
			result = stmt.column_text(0);
		}

		return result;
	}

	public string getFeedName(string feedID)
	{
		if(feedID == "")
			return "unknown Feed";
		var query = new QueryBuilder(QueryType.SELECT, "main.feeds");
		query.selectField("name");
		query.addEqualsCondition("feed_id", feedID, true, true);
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, "getFeedName - %s".printf(sqlite_db.errmsg()));

		string result = "";

		while (stmt.step () == Sqlite.ROW) {
			result = stmt.column_text(0);
		}

		return result;
	}


	public string? getTagName(string tagID)
	{
		var query = new QueryBuilder(QueryType.SELECT, "main.tags");
		query.selectField("title");
		query.addEqualsCondition("tagID", tagID, true, true);
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, "getTagName - %s".printf(sqlite_db.errmsg()));

		string result = null;

		while (stmt.step () == Sqlite.ROW) {
			result = stmt.column_text(0);
		}

		return result;
	}

	public int getLastModified()
	{
		var query = new QueryBuilder(QueryType.SELECT, "main.articles");
		query.selectField("MAX(lastModified)");
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, "getLastModified - %s".printf(sqlite_db.errmsg()));

		int result = 0;

		while (stmt.step () == Sqlite.ROW) {
			result = stmt.column_int(0);
		}

		return result;
	}


	public string getCategoryName(string catID)
	{
		if(catID == CategoryID.TAGS)
			return "Tags";

		var query = new QueryBuilder(QueryType.SELECT, "main.categories");
		query.selectField("title");
		query.addEqualsCondition("categorieID", catID, true, true);
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, "getCategoryName - %s".printf(sqlite_db.errmsg()));

		string result = "";

		while (stmt.step () == Sqlite.ROW) {
			result = stmt.column_text(0);
		}

		if(result == "")
			result = _("Uncategorized");

		return result;
	}


	public bool preview_empty(string articleID)
	{
		var query = new QueryBuilder(QueryType.SELECT, "main.articles");
		query.selectField("count(*)");
		query.addEqualsCondition("articleID", articleID, true, true);
		query.addEqualsCondition("preview", "", false, true);
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, "checking for empty preview - %s".printf(sqlite_db.errmsg()));

		int result = 1;

		while (stmt.step () == Sqlite.ROW) {
			result = stmt.column_int(0);
		}

		if(result == 1)
			return false;
		if(result == 0)
			return true;

		return true;
	}

	public article read_article(string articleID)
	{
		article tmp = null;

		var query = new QueryBuilder(QueryType.SELECT, "main.articles");
		query.selectField("ROWID");
		query.selectField("*");
		query.addEqualsCondition("articleID", articleID, true, true);
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, "reading preview - %s".printf(sqlite_db.errmsg()));

		while (stmt.step () == Sqlite.ROW) {
			tmp = new article(
								articleID,
								stmt.column_text(3),
								stmt.column_text(5),
								stmt.column_text(2),
								(ArticleStatus)stmt.column_int(8),
								(ArticleStatus)stmt.column_int(9),
								stmt.column_text(6),
								stmt.column_text(7),
								stmt.column_text(4),
								Utils.convertStringToDate(stmt.column_text(11)),
								stmt.column_int(0),
								stmt.column_text(10),
								stmt.column_text(12)
							);
		}
		stmt.reset ();
		return tmp;
	}


	public string read_article_tags(string articleID)
	{
		var query = new QueryBuilder(QueryType.SELECT, "main.articles");
		query.selectField("tags");
		query.addEqualsCondition("articleID", articleID, true, true);
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, "reading preview - %s".printf(sqlite_db.errmsg()));

		while (stmt.step () == Sqlite.ROW) {
			return stmt.column_text(0);
		}
		stmt.reset ();
		return "";
	}

	public int getMaxCatLevel()
	{
		int maxCatLevel = 0;

		var query = new QueryBuilder(QueryType.SELECT, "main.categories");
		query.selectField("max(Level)");
		query.addCustomCondition("categorieID >= 0");
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		while (stmt.step () == Sqlite.ROW) {
			maxCatLevel = stmt.column_int(0);
		}

		if(maxCatLevel == 0)
		{
			maxCatLevel = 1;
		}

		return maxCatLevel;
	}

	public bool haveFeedsWithoutCat()
	{
		var query = new QueryBuilder(QueryType.SELECT, "main.feeds");
		query.selectField("count(*)");
		query.addCustomCondition(getUncategorizedQuery());
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}

		while (stmt.step () == Sqlite.ROW) {
			int count = stmt.column_int(0);

			if(count > 0)
				return true;
		}
		return false;
	}

	public bool haveCategories()
	{
		var query = new QueryBuilder(QueryType.SELECT, "main.categories");
		query.selectField("count(*)");
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}

		while (stmt.step () == Sqlite.ROW) {
			int count = stmt.column_int(0);

			if(count > 0)
				return true;
		}

		return false;
	}

	public bool article_exists(string articleID)
	{
		int result = 0;
		string query = "SELECT EXISTS(SELECT 1 FROM main.articles WHERE articleID = \"" + articleID + "\" LIMIT 1)";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		while (stmt.step () == Sqlite.ROW) {
			result = stmt.column_int(0);
		}
		if(result == 1)
			return true;

		return false;
	}


	public int getRowCountHeadlineByDate(string date)
	{
		int result = 0;

		var query = new QueryBuilder(QueryType.SELECT, "main.articles");
		query.selectField("count(*)");
		query.addCustomCondition("date > \"%s\"".printf(date));
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		while (stmt.step () == Sqlite.ROW) {
			result = stmt.column_int(0);
		}

		return result;
	}


	public int getRowCountHeadlineByRowID(string id)
	{
		int result = 0;

		var query = new QueryBuilder(QueryType.SELECT, "main.articles");
		query.selectField("rowid");
		query.addEqualsCondition("articleID", id, true, true);
		query.build();

		var query2 = new QueryBuilder(QueryType.SELECT, "main.articles");
		query2.selectField("count(*)");
		query2.addCustomCondition("rowid > (%s)".printf(query.get()));
		query2.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query2.get(), query2.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		while (stmt.step () == Sqlite.ROW) {
			result = stmt.column_int(0);
		}

		return result;
	}


	protected Gee.ArrayList<string> getFeedIDofCategorie(string categorieID)
	{
		var feedIDs = new Gee.ArrayList<string>();

		var query = new QueryBuilder(QueryType.SELECT, "main.feeds");
		query.selectField("feed_id, category_id");
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2(query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		while (stmt.step() == Sqlite.ROW) {
			string catString = stmt.column_text(1);
			string[] categories = catString.split(",");

			if(categorieID == "")
			{
				if((categories.length == 0)
				||(categories.length == 1 && categories[0].contains("global.must")))
				{
					feedIDs.add(stmt.column_text(0));
				}
			}
			else
			{
				foreach(string cat in categories)
				{
					if(cat == categorieID)
					{
						feedIDs.add(stmt.column_text(0));
					}
				}
			}
		}
		return feedIDs;
	}

	protected string getUncategorizedQuery()
	{
		string sql = "0";

		if(settings_general.get_enum("account-type") == Backend.FEEDLY)
		{
			sql = "instr(category_id, \",\") = 0";
		}
		else if(settings_general.get_enum("account-type") == Backend.OWNCLOUD)
		{
			sql = "category_id = 0";
		}


		return sql;
	}

	protected string getUncategorizedFeedsQuery()
	{
		string sql = "feedID IN (%s)";

		var query = new QueryBuilder(QueryType.SELECT, "main.feeds");
		query.selectField("feed_id");
		query.addCustomCondition(getUncategorizedQuery());
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}

		string feedIDs = "";
		while (stmt.step () == Sqlite.ROW) {
			feedIDs += "\"" + stmt.column_text(0) + "\"" + ",";
		}

		return sql.printf(feedIDs.substring(0, feedIDs.length-1));
	}


	public string getFeedIDofArticle(string articleID)
	{
		string query = "SELECT feedID FROM \"main\".\"articles\" WHERE \"articleID\" = " + "\"" + articleID + "\"";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		string id = "";
		while (stmt.step () == Sqlite.ROW) {
			id = stmt.column_text(0);
		}
		return id;
	}


	public string getNewestArticle()
	{
		string result = "";

		var query = new QueryBuilder(QueryType.SELECT, "main.articles");
		query.selectField("articleID");
		query.addEqualsCondition("rowid", "%i".printf(getHighestRowID()));
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		while (stmt.step () == Sqlite.ROW) {
			result = stmt.column_text(0);
		}
		return result;
	}

	public int getHighestRowID()
	{
		int result = 0;

		var query = new QueryBuilder(QueryType.SELECT, "main.articles");
		query.selectField("max(rowid)");
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		while (stmt.step () == Sqlite.ROW) {
			result = stmt.column_int(0);
		}
		return result;
	}


	public Gee.ArrayList<feed> read_feeds()
	{
		Gee.ArrayList<feed> tmp = new Gee.ArrayList<feed>();
		feed tmpfeed;

		var query = new QueryBuilder(QueryType.SELECT, "main.feeds");
		query.selectField("*");
		if(settings_general.get_enum("feedlist-sort-by") == FeedListSort.ALPHABETICAL)
		{
			query.orderBy("name", true);
		}
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		while (stmt.step () == Sqlite.ROW) {
			string feedID = stmt.column_text(0);
			tmpfeed = new feed(feedID, stmt.column_text(1), stmt.column_text(2), ((stmt.column_int(3) == 1) ? true : false), getFeedUnread(feedID), stmt.column_text(4).split(","));
			tmp.add(tmpfeed);
		}

		return tmp;
	}


	protected uint getFeedUnread(string feedID)
	{
		uint count = 0;

		var query = new QueryBuilder(QueryType.SELECT, "main.articles");
		query.selectField("count(*)");
		query.addEqualsCondition("unread", ArticleStatus.UNREAD.to_string());
		query.addEqualsCondition("feedID", feedID, true, true);
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		while (stmt.step () == Sqlite.ROW) {
			count = (uint)stmt.column_int(0);
		}
		return count;
	}


	public Gee.ArrayList<feed> read_feeds_without_cat()
	{
		Gee.ArrayList<feed> tmp = new Gee.ArrayList<feed>();
		feed tmpfeed;

		var query = new QueryBuilder(QueryType.SELECT, "main.feeds");
		query.selectField("*");
		query.addCustomCondition(getUncategorizedQuery());
		if(settings_general.get_enum("feedlist-sort-by") == FeedListSort.ALPHABETICAL)
		{
			query.orderBy("name", true);
		}
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		while (stmt.step () == Sqlite.ROW) {
			tmpfeed = new feed(stmt.column_text(0), stmt.column_text(1), stmt.column_text(2), ((stmt.column_int(3) == 1) ? true : false), (uint)stmt.column_int(4), stmt.column_text(4).split(","));
			tmp.add(tmpfeed);
		}

		return tmp;
	}

	public Gee.ArrayList<category> read_categories(Gee.ArrayList<feed>? feeds = null)
	{
		Gee.ArrayList<category> tmp = new Gee.ArrayList<category>();
		category tmpcategory;

		var query = new QueryBuilder(QueryType.SELECT, "main.categories");
		query.selectField("*");
		query.addCustomCondition("categorieID >= 0");
		query.orderBy("orderID", true);
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		while (stmt.step () == Sqlite.ROW) {
			string catID = stmt.column_text(0);
			uint unread = 0;
			if(feeds != null)
			{
				foreach(feed Feed in feeds)
				{
					bool found = false;
					var ids = Feed.getCatIDs();
					foreach(string id in ids)
					{
						if(id == catID)
						{
							found = true;
							break;
						}
					}

					if(found)
						unread += Feed.getUnread();
				}
			}

			tmpcategory = new category(catID, stmt.column_text(1), unread, stmt.column_int(3), stmt.column_text(4), stmt.column_int(5));
			tmp.add(tmpcategory);
		}

		return tmp;
	}


	public Gee.ArrayList<tag> read_tags()
	{
		Gee.ArrayList<tag> tmp = new Gee.ArrayList<tag>();
		tag tmpTag;

		var query = new QueryBuilder(QueryType.SELECT, "main.tags");
		query.selectField("*");
		query.addCustomCondition("instr(tagID, \"global.\") = 0");
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		while (stmt.step () == Sqlite.ROW) {
			tmpTag = new tag(stmt.column_text(0), stmt.column_text(1), stmt.column_int(3));
			tmp.add(tmpTag);
		}

		return tmp;
	}

	public tag read_tag(string tagID)
	{
		tag tmpTag = null;

		var query = new QueryBuilder(QueryType.SELECT, "main.tags");
		query.selectField("*");
		query.addEqualsCondition("tagID", tagID, true, true);
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		while (stmt.step () == Sqlite.ROW) {
			tmpTag = new tag(stmt.column_text(0), stmt.column_text(1), stmt.column_int(3));
		}

		return tmpTag;
	}

	protected string getAllTagsCondition()
	{
		var tags = read_tags();
		string query = "(";
		foreach(var Tag in tags)
		{
			query += "instr(\"tags\", \"%s\") > 0 OR ".printf(Tag.getTagID());
		}

		int or = query.char_count()-4;
		return query.substring(0, or) + ")";
	}

	public int getTagCount()
	{
		int count = 0;
		var query = new QueryBuilder(QueryType.SELECT, "main.tags");
		query.addCustomCondition("instr(tagID, \"global.\") = 0");
		query.selectField("count(*)");
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		while (stmt.step () == Sqlite.ROW) {
			count = stmt.column_int(0);
		}

		return count;
	}

	public Gee.ArrayList<category> read_categories_level(int level, Gee.ArrayList<feed>? feeds = null)
	{
		Gee.ArrayList<category> tmp = new Gee.ArrayList<category>();
		category tmpcategory;

		var query = new QueryBuilder(QueryType.SELECT, "main.categories");
		query.selectField("*");
		query.addCustomCondition("categorieID >= 0");
		query.addEqualsCondition("level", level.to_string());
		if(settings_general.get_enum("feedlist-sort-by") == FeedListSort.ALPHABETICAL)
		{
			query.orderBy("title", true);
		}
		else
		{
			query.orderBy("orderID", true);
		}

		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		while (stmt.step () == Sqlite.ROW) {
			string catID = stmt.column_text(0);
			uint unread = 0;
			if(feeds != null)
			{
				foreach(feed Feed in feeds)
				{
					bool found = false;
					var ids = Feed.getCatIDs();
					foreach(string id in ids)
					{
						if(id == catID)
						{
							found = true;
							break;
						}
					}

					if(found)
						unread += Feed.getUnread();
				}
			}

			tmpcategory = new category(catID, stmt.column_text(1), unread, stmt.column_int(3), stmt.column_text(4), stmt.column_int(5));
			tmp.add(tmpcategory);
		}

		return tmp;
	}

	//[Profile]
	public Gee.ArrayList<article> read_articles(string ID, FeedListType selectedType, bool only_unread, bool only_marked, string searchTerm, uint limit = 20, uint offset = 0, int searchRows = 0)
	{
		var query = new QueryBuilder(QueryType.SELECT, "main.articles");
		query.selectField("ROWID");
		query.selectField("feedID");
		query.selectField("articleID");
		query.selectField("title");
		query.selectField("author");
		query.selectField("url");
		query.selectField("preview");
		query.selectField("unread");
		query.selectField("marked");
		query.selectField("tags");
		query.selectField("date");
		query.selectField("guidHash");

		if(selectedType == FeedListType.FEED && ID != FeedID.ALL)
		{
			query.addEqualsCondition("feedID", ID, true, true);
		}
		else if(selectedType == FeedListType.CATEGORY && ID != CategoryID.MASTER && ID != CategoryID.TAGS)
		{
			query.addRangeConditionString("feedID", getFeedIDofCategorie(ID));
		}
		else if(ID == CategoryID.TAGS)
		{
			query.addCustomCondition(getAllTagsCondition());
		}
		else if(selectedType == FeedListType.TAG)
		{
			query.addCustomCondition("instr(tags, \"%s\") > 0".printf(ID));
		}

		if(only_unread){
			query.addEqualsCondition("unread", ArticleStatus.UNREAD.to_string());
		}

		if(only_marked){
			query.addEqualsCondition("marked", ArticleStatus.MARKED.to_string());
		}

		if(searchTerm != ""){
			if(searchTerm.has_prefix("title: "))
			{
				query.addCustomCondition("articleID IN (SELECT articleID FROM fts_table WHERE title MATCH '%s')".printf(Utils.prepareSearchQuery(searchTerm)));
			}
			else if(searchTerm.has_prefix("author: "))
			{
				query.addCustomCondition("articleID IN (SELECT articleID FROM fts_table WHERE author MATCH '%s')".printf(Utils.prepareSearchQuery(searchTerm)));
			}
			else if(searchTerm.has_prefix("content: "))
			{
				query.addCustomCondition("articleID IN (SELECT articleID FROM fts_table WHERE preview MATCH '%s')".printf(Utils.prepareSearchQuery(searchTerm)));
			}
			else
			{
				query.addCustomCondition("articleID IN (SELECT articleID FROM fts_table WHERE fts_table MATCH '%s')".printf(Utils.prepareSearchQuery(searchTerm)));
			}
		}

		if(searchRows != 0)
		{
			query.addCustomCondition("articleID in (SELECT articleID FROM main.articles ORDER BY rowid DESC LIMIT %i)".printf(searchRows));
		}

		string order_field = "";
		switch(settings_general.get_enum("articlelist-sort-by"))
		{
			case ArticleListSort.RECEIVED:
				order_field = "rowid";
				break;

			case ArticleListSort.DATE:
				order_field = "date";
				break;
		}

		bool desc = false;
		if(settings_general.get_boolean("articlelist-newest-first"))
			desc = true;

		query.orderBy(order_field, desc);
		query.limit(limit);
		query.offset(offset);
		query.build();
		query.print();


		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if(ec != Sqlite.OK)
			logger.print(LogMessage.DEBUG, sqlite_db.errmsg());


		Gee.ArrayList<article> tmp = new Gee.ArrayList<article>();
		while (stmt.step () == Sqlite.ROW)
		{
			tmp.add(new article(
								stmt.column_text(2),								// articleID
								stmt.column_text(3),								// title
								stmt.column_text(5),								// url
								stmt.column_text(1),								// feedID
								(ArticleStatus)stmt.column_int(7),					// unread
								(ArticleStatus)stmt.column_int(8),					// marked
								"",													// html
								stmt.column_text(6),								// preview
								stmt.column_text(4),								// author
								Utils.convertStringToDate(stmt.column_text(10)),	// date
								stmt.column_int(0),									// sortID
								stmt.column_text(9),								// tags
								stmt.column_text(11)
							));
		}

		return tmp;
	}

}
