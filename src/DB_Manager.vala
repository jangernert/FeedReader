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

public class FeedReader.dbManager : GLib.Object {

	private Sqlite.Database sqlite_db;
	public signal void updateBadge();

	public dbManager () {
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
		int rc = Sqlite.Database.open_v2(db_path + "feedreader-02.db", out sqlite_db);
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
												"feed_id" TEXT PRIMARY KEY  NOT NULL UNIQUE ,
												"name" TEXT NOT NULL,
												"url" TEXT NOT NULL,
												"has_icon" INTEGER NOT NULL,
												"category_id" TEXT,
												"subscribed" INTEGER DEFAULT 1
											)""");

			executeSQL(					"""CREATE  TABLE  IF NOT EXISTS "main"."categories"
											(
												"categorieID" TEXT PRIMARY KEY  NOT NULL  UNIQUE ,
												"title" TEXT NOT NULL,
												"orderID" INTEGER,
												"exists" INTEGER,
												"Parent" TEXT,
												"Level" INTEGER
												)""");

			executeSQL(					"""CREATE  TABLE  IF NOT EXISTS "main"."articles"
											(
												"articleID" TEXT PRIMARY KEY  NOT NULL  UNIQUE ,
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
												"tagID" TEXT PRIMARY KEY  NOT NULL  UNIQUE ,
												"title" TEXT NOT NULL,
												"exists" INTEGER,
												"color" INTEGER
												)""");

			executeSQL(			 			"""CREATE INDEX IF NOT EXISTS "index_articles" ON "articles" ("feedID" DESC, "unread" ASC, "marked" ASC)""");
			executeSQL(						"""CREATE VIRTUAL TABLE fts_table USING fts4 (content='articles', articleID, preview, title, author)""");
	}


	private void executeSQL(string sql)
	{
		string errmsg;
		int ec = sqlite_db.exec (sql, null, out errmsg);
		if (ec != Sqlite.OK) {
			logger.print(LogMessage.ERROR, sql);
			logger.print(LogMessage.ERROR, errmsg);
		}
	}


	public bool resetDB()
	{
		executeSQL("DROP TABLE main.feeds");
		executeSQL("DROP TABLE main.categories");
		executeSQL("DROP TABLE main.articles");
		executeSQL("DROP TABLE main.tags");
		executeSQL("VACUUM");

		string query = "PRAGMA INTEGRITY_CHECK";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, "%d: %s".printf(sqlite_db.errcode (), sqlite_db.errmsg ()));


		int cols = stmt.column_count ();
		while (stmt.step () == Sqlite.ROW) {
			for (int i = 0; i < cols; i++) {
				if(stmt.column_text(i) != "ok")
				{
					logger.print(LogMessage.ERROR, "resetting the database failed");
					return false;
				}
			}
		}
		stmt.reset();
		return true;
	}

	public void updateFTS()
	{
		executeSQL("INSERT INTO fts_table(fts_table) VALUES('rebuild')");
	}

	public void springCleaning()
	{
		executeSQL("VACUUM");
		var now = new DateTime.now_local();
		settings_state.set_int("last-spring-cleaning", (int)now.to_unix());
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

	public void dropOldArtilces(int weeks)
	{
		var query = new QueryBuilder(QueryType.SELECT, "main.articles");
		query.selectField("articleID");
		query.selectField("feedID");
		query.addCustomCondition("date <= datetime('now', '-%i months')".printf(weeks));
		query.addEqualsCondition("marked", ArticleStatus.MARKED.to_string(), false, false);
		if(settings_general.get_enum("account-type") != Backend.OWNCLOUD)
		{
			int highesID = getHighestRowID();
			int syncCount = settings_general.get_int("max-articles");
			query.addCustomCondition("NOT rowid BETWEEN %i AND %i".printf(highesID, highesID-syncCount));
		}
		query.build();
		query.print();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		while (stmt.step () == Sqlite.ROW) {
			delete_article(stmt.column_text(0), stmt.column_text(1));
		}
	}

	private void delete_article(string articleID, string feedID)
	{
		executeSQL("DELETE FROM main.articles WHERE articleID = \"" + articleID + "\"");
		string folder_path = GLib.Environment.get_home_dir() + "/.local/share/feedreader/data/images/%s/%s/".printf(feedID, articleID);
		Utils.remove_directory(folder_path);
	}

	public void dropTag(string tagID)
	{
		var query = new QueryBuilder(QueryType.DELETE, "main.tags");
		query.addEqualsCondition("tagID", tagID, true, true);
		executeSQL(query.build());

		query = new QueryBuilder(QueryType.SELECT, "main.articles");
		query.selectField("tags");
		query.selectField("articleID");
		query.addCustomCondition("instr(tags, \"%s\") > 0".printf(tagID));
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		while (stmt.step () == Sqlite.ROW) {
			string old_tags = stmt.column_text(0);
			string articleID = stmt.column_text(1);
			string new_tags = "";
			var tagArray = old_tags.split(",");
			foreach(string tag in tagArray)
			{
				tag = tag.strip();
				if(tag != "" && tag != tagID)
					new_tags += "tag" + ",";
			}

			query = new QueryBuilder(QueryType.UPDATE, "main.articles");
			query.updateValuePair("tags", new_tags);
			query.addEqualsCondition("articleID", articleID, true, true);
			executeSQL(query.build());
		}
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

	public void write_feeds(ref GLib.List<feed> feeds)
	{
		executeSQL("BEGIN TRANSACTION");

		var query = new QueryBuilder(QueryType.INSERT_OR_REPLACE, "main.feeds");
		query.insertValuePair("feed_id", "$FEEDID");
		query.insertValuePair("name", "$FEEDNAME");
		query.insertValuePair("url", "$FEEDURL");
		query.insertValuePair("has_icon", "$HASICON");
		query.insertValuePair("category_id", "$CATID");
		query.insertValuePair("subscribed", "1");
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2(query.get(), query.get().length, out stmt);
		if(ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());


		int feedID_pos   = stmt.bind_parameter_index("$FEEDID");
		int feedName_pos = stmt.bind_parameter_index("$FEEDNAME");
		int feedURL_pos  = stmt.bind_parameter_index("$FEEDURL");
		int hasIcon_pos  = stmt.bind_parameter_index("$HASICON");
		int catID_pos    = stmt.bind_parameter_index("$CATID");
		assert (feedID_pos > 0);
		assert (feedName_pos > 0);
		assert (feedURL_pos > 0);
		assert (hasIcon_pos > 0);
		assert (catID_pos > 0);

		foreach(var feed_item in feeds)
		{
			string catString = "";
			foreach(string category in feed_item.getCatIDs())
			{
				catString += category + ",";
			}

			catString = catString.substring(0, catString.length-1);

			stmt.bind_text(feedID_pos, feed_item.getFeedID());
			stmt.bind_text(feedName_pos, feed_item.getTitle());
			stmt.bind_text(feedURL_pos, feed_item.getURL());
			stmt.bind_int (hasIcon_pos, feed_item.hasIcon() ? 1 : 0);
			stmt.bind_text(catID_pos, catString);

			while(stmt.step() == Sqlite.ROW){}
			stmt.reset();
		}

		executeSQL("COMMIT TRANSACTION");
	}

	public void write_tags(ref GLib.List<tag> tags)
	{
		executeSQL("BEGIN TRANSACTION");

		var query = new QueryBuilder(QueryType.INSERT_OR_IGNORE, "main.tags");
		query.insertValuePair("tagID", "$TAGID");
		query.insertValuePair("title", "$LABEL");
		query.insertValuePair("\"exists\"", "1");
		query.insertValuePair("color", "$COLOR");
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());


		int tagID_position = stmt.bind_parameter_index("$TAGID");
		int label_position = stmt.bind_parameter_index("$LABEL");
		int color_position = stmt.bind_parameter_index("$COLOR");
		assert (tagID_position > 0);
		assert (label_position > 0);
		assert (color_position > 0);

		foreach(var tag_item in tags)
		{
			stmt.bind_text(tagID_position, tag_item.getTagID());
			stmt.bind_text(label_position, tag_item.getTitle());
			stmt.bind_int (color_position, tag_item.getColor());

			while (stmt.step () == Sqlite.ROW) {}
			stmt.reset ();
		}

		executeSQL("COMMIT TRANSACTION");
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

	public void update_tag_color(string tagID, int color)
	{
		var query = new QueryBuilder(QueryType.UPDATE, "main.tags");
		query.updateValuePair("color", color.to_string());
		query.addEqualsCondition("tagID", tagID, true, true);
		executeSQL(query.build());
	}

	public void update_tag(string tagID)
	{
		var query = new QueryBuilder(QueryType.UPDATE, "main.tags");
		query.updateValuePair("\"exists\"", "1");
		query.addEqualsCondition("tagID", tagID, true, true);
		executeSQL(query.build());
	}


	public void write_categories(ref GLib.List<category> categories)
	{
		executeSQL("BEGIN TRANSACTION");

		var query = new QueryBuilder(QueryType.INSERT_OR_REPLACE, "main.categories");
		query.insertValuePair("categorieID", "$CATID");
		query.insertValuePair("title", "$FEEDNAME");
		query.insertValuePair("orderID", "$ORDERID");
		query.insertValuePair("\"exists\"", "1");
		query.insertValuePair("Parent", "$PARENT");
		query.insertValuePair("Level", "$LEVEL");
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());


		int catID_position       = stmt.bind_parameter_index("$CATID");
		int feedName_position    = stmt.bind_parameter_index("$FEEDNAME");
		int orderID_position     = stmt.bind_parameter_index("$ORDERID");
		int parent_position      = stmt.bind_parameter_index("$PARENT");
		int level_position       = stmt.bind_parameter_index("$LEVEL");
		assert (catID_position > 0);
		assert (feedName_position > 0);
		assert (orderID_position > 0);
		assert (parent_position > 0);
		assert (level_position > 0);

		foreach(var cat_item in categories)
		{
			stmt.bind_text(catID_position, cat_item.getCatID());
			stmt.bind_text(feedName_position, cat_item.getTitle());
			stmt.bind_int (orderID_position, cat_item.getOrderID());
			stmt.bind_text(parent_position, cat_item.getParent());
			stmt.bind_int (level_position, cat_item.getLevel());

			while (stmt.step () == Sqlite.ROW) {}
			stmt.reset ();
		}

		executeSQL("COMMIT TRANSACTION");
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


	public string getTagName(string tagID)
	{
		var query = new QueryBuilder(QueryType.SELECT, "main.tags");
		query.selectField("title");
		query.addEqualsCondition("tagID", tagID, true, true);
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, "getTagName - %s".printf(sqlite_db.errmsg()));

		string result = "";

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


	public void update_articles(ref GLib.List<article> articles)
	{
		executeSQL("BEGIN TRANSACTION");

		var update_query = new QueryBuilder(QueryType.UPDATE, "main.articles");
		update_query.updateValuePair("unread", "$UNREAD");
		update_query.updateValuePair("marked", "$MARKED");
		update_query.updateValuePair("tags", "$TAGS");
		update_query.updateValuePair("lastModified", "$LASTMODIFIED");
		update_query.addEqualsCondition("articleID", "$ARTICLEID");
		update_query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (update_query.get(), update_query.get().length, out stmt);

		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, "upate_articles: %s".printf(sqlite_db.errmsg()));

		int unread_position = stmt.bind_parameter_index("$UNREAD");
		int marked_position = stmt.bind_parameter_index("$MARKED");
		int tags_position = stmt.bind_parameter_index("$TAGS");
		int modified_position = stmt.bind_parameter_index("$LASTMODIFIED");
		int articleID_position = stmt.bind_parameter_index("$ARTICLEID");
		assert (unread_position > 0);
		assert (marked_position > 0);
		assert (tags_position > 0);
		assert (modified_position > 0);
		assert (articleID_position > 0);


		foreach(var article in articles)
		{
			stmt.bind_text(unread_position, article.getUnread().to_string());
			stmt.bind_text(marked_position, article.getMarked().to_string());
			stmt.bind_text(tags_position, article.getTagString());
			stmt.bind_int (modified_position, article.getLastModified());
			stmt.bind_text(articleID_position, article.getArticleID());

			while(stmt.step () == Sqlite.ROW) {}
			stmt.reset();
		}

		executeSQL("COMMIT TRANSACTION");
	}


	public void write_articles(ref GLib.List<article> articles)
	{

		FeedReader.Utils.generatePreviews(ref articles);
		FeedReader.Utils.checkHTML(ref articles);

		executeSQL("BEGIN TRANSACTION");

		var query = new QueryBuilder(QueryType.INSERT_OR_IGNORE, "main.articles");
		query.insertValuePair("articleID", "$ARTICLEID");
		query.insertValuePair("feedID", "$FEEDID");
		query.insertValuePair("title", "$TITLE");
		query.insertValuePair("author", "$AUTHOR");
		query.insertValuePair("url", "$URL");
		query.insertValuePair("html", "$HTML");
		query.insertValuePair("preview", "$PREVIEW");
		query.insertValuePair("unread", "$UNREAD");
		query.insertValuePair("marked", "$MARKED");
		query.insertValuePair("tags", "$TAGS");
		query.insertValuePair("date", "$DATE");
		query.insertValuePair("guidHash", "$GUIDHASH");
		query.insertValuePair("lastModified", "$LASTMODIFIED");
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2(query.get(), query.get().length, out stmt);

		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, "write_arties: %s".printf(sqlite_db.errmsg()));



		int articleID_position = stmt.bind_parameter_index("$ARTICLEID");
		int feedID_position = stmt.bind_parameter_index("$FEEDID");
		int url_position = stmt.bind_parameter_index("$URL");
		int unread_position = stmt.bind_parameter_index("$UNREAD");
		int marked_position = stmt.bind_parameter_index("$MARKED");
		int tags_position = stmt.bind_parameter_index("$TAGS");
		int title_position = stmt.bind_parameter_index("$TITLE");
		int html_position = stmt.bind_parameter_index("$HTML");
		int preview_position = stmt.bind_parameter_index("$PREVIEW");
		int author_position = stmt.bind_parameter_index("$AUTHOR");
		int date_position = stmt.bind_parameter_index("$DATE");
		int guidHash_position = stmt.bind_parameter_index("$GUIDHASH");
		int modified_position = stmt.bind_parameter_index("$LASTMODIFIED");

		assert (articleID_position > 0);
		assert (feedID_position > 0);
		assert (url_position > 0);
		assert (unread_position > 0);
		assert (marked_position > 0);
		assert (tags_position > 0);
		assert (title_position > 0);
		assert (html_position > 0);
		assert (preview_position > 0);
		assert (author_position > 0);
		assert (date_position > 0);
		assert (guidHash_position > 0);
		assert (modified_position > 0);


		foreach(var article in articles)
		{
			stmt.bind_text(articleID_position, article.getArticleID());
			stmt.bind_text(feedID_position, article.getFeedID());
			stmt.bind_text(url_position, article.getURL());
			stmt.bind_int (unread_position, article.getUnread());
			stmt.bind_int (marked_position, article.getMarked());
			stmt.bind_text(tags_position, article.getTagString());
			stmt.bind_text(title_position, article.getTitle());
			stmt.bind_text(html_position, article.getHTML());
			stmt.bind_text(preview_position, article.getPreview());
			stmt.bind_text(author_position, article.getAuthor());
			stmt.bind_text(date_position, article.getDateStr());
			stmt.bind_text(guidHash_position, article.getHash());
			stmt.bind_int (modified_position, article.getLastModified());

			while(stmt.step () == Sqlite.ROW) {}
			stmt.reset();
		}

		executeSQL("COMMIT TRANSACTION");
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

	public void set_article_tags(string articleID, string tags)
	{
		var query = new QueryBuilder(QueryType.UPDATE, "main.articles");
		query.updateValuePair("tags", "\"%s\"".printf(tags));
		query.addEqualsCondition("articleID", articleID, true, true);
		executeSQL(query.build());
	}

	public bool tag_still_used(string tagID)
	{
		var query = new QueryBuilder(QueryType.SELECT, "main.articles");
		query.selectField("count(*)");
		query.addCustomCondition("instr(tags, \"%s\") > 0".printf(tagID));
		query.limit(2);
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, "reading preview - %s".printf(sqlite_db.errmsg()));

		while (stmt.step () == Sqlite.ROW) {
			if(stmt.column_int(0) > 1)
				return true;
		}

		return false;
	}

	public async void update_article(string articleIDs, string field, int field_value)
	{
		SourceFunc callback = update_article.callback;

		ThreadFunc<void*> run = () => {

			var id_array = articleIDs.split(",");
			var id_list = new GLib.List<string>();
			foreach(string id in id_array)
			{
				id_list.append(id);
			}

			var query = new QueryBuilder(QueryType.UPDATE, "main.articles");
			query.updateValuePair(field, field_value.to_string());
			query.addRangeConditionString("articleID", id_list);
			executeSQL(query.build());

			Idle.add((owned) callback);
			return null;
		};
		new GLib.Thread<void*>("update_article", run);
		yield;
	}

	public async void markFeedRead(string feedID)
	{
		SourceFunc callback = markFeedRead.callback;

		ThreadFunc<void*> run = () => {

			var query = new QueryBuilder(QueryType.UPDATE, "main.articles");
			query.updateValuePair("unread", ArticleStatus.READ.to_string());
			query.addEqualsCondition("feedID", feedID);
			executeSQL(query.build());

			Idle.add((owned) callback);
			return null;
		};
		new GLib.Thread<void*>("markFeedRead", run);
		yield;
	}

	public async void markCategorieRead(string catID)
	{
		SourceFunc callback = markCategorieRead.callback;

		ThreadFunc<void*> run = () => {

			var query = new QueryBuilder(QueryType.UPDATE, "main.articles");
			query.updateValuePair("unread", ArticleStatus.READ.to_string());
			query.addRangeConditionString("feedID", getFeedIDofCategorie(catID));
			executeSQL(query.build());

			Idle.add((owned) callback);
			return null;
		};
		new GLib.Thread<void*>("markCategorieRead", run);
		yield;
	}

	public async void markAllRead()
	{
		SourceFunc callback = markAllRead.callback;

		ThreadFunc<void*> run = () => {

			var query1 = new QueryBuilder(QueryType.UPDATE, "main.articles");
			query1.updateValuePair("unread", ArticleStatus.READ.to_string());
			executeSQL(query1.build());

			Idle.add((owned) callback);
			return null;
		};
		new GLib.Thread<void*>("markAllRead", run);
		yield;
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


	public void reset_subscribed_flag()
	{
		executeSQL("UPDATE main.feeds SET \"subscribed\" = 0");
	}

	public void reset_exists_tag()
	{
		executeSQL("UPDATE main.tags SET \"exists\" = 0");
	}

	public void reset_exists_flag()
	{
		executeSQL("UPDATE main.categories SET \"exists\" = 0");
	}



	public void delete_unsubscribed_feeds()
	{
		executeSQL("DELETE FROM main.feeds WHERE \"subscribed\" = 0");
	}


	public void delete_nonexisting_categories()
	{
		executeSQL("DELETE FROM main.categories WHERE \"exists\" = 0");
	}

	public void delete_nonexisting_tags()
	{
		executeSQL("DELETE FROM main.tags WHERE \"exists\" = 0");
	}

	public void delete_articles_without_feed()
	{
		var query = new QueryBuilder(QueryType.SELECT, "main.feeds");
		query.selectField("feed_id");
		query.addEqualsCondition("subscribed", "0", true, false);
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		while (stmt.step () == Sqlite.ROW) {
			delete_articles(stmt.column_text(0));
		}
	}

	public void delete_articles(string feedID)
	{
		executeSQL("DELETE FROM main.articles WHERE feedID = \"" + feedID + "\"");
		string folder_path = GLib.Environment.get_home_dir() + "/.local/share/feedreader/data/images/%s/".printf(feedID);
		Utils.remove_directory(folder_path);
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
		//query.orderBy("date", true);
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


	public int getRowCountHeadlineByRowID(string date)
	{
		int result = 0;

		var query = new QueryBuilder(QueryType.SELECT, "main.articles");
		query.selectField("rowid");
		query.addEqualsCondition("date", date, true, true);
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		while (stmt.step () == Sqlite.ROW) {
			result = stmt.column_int(0);
		}


		query = new QueryBuilder(QueryType.SELECT, "main.articles");
		query.selectField("count(*)");
		query.addCustomCondition("rowid > %i".printf(result));
		query.build();

		ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		while (stmt.step () == Sqlite.ROW) {
			result = stmt.column_int(0);
		}

		return result;
	}


	private GLib.List<string> getFeedIDofCategorie(string categorieID)
	{
		var feedIDs = new GLib.List<string>();

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
					feedIDs.append(stmt.column_text(0));
				}
			}
			else
			{
				foreach(string cat in categories)
				{
					if(cat == categorieID)
					{
						feedIDs.append(stmt.column_text(0));
					}
				}
			}
		}
		return feedIDs;
	}

	private string getUncategorizedQuery()
	{
		string sql = "0";

		if(settings_general.get_enum("account-type") == Backend.FEEDLY)
		{
			var query = new QueryBuilder(QueryType.SELECT, "main.categories");
			query.selectField("categorieID");
			query.addCustomCondition("instr(tagID, \"global.must\") > 0");

			Sqlite.Statement stmt;
			int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
			if (ec != Sqlite.OK) {
				error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
			}

			string mustRead = "";
			while (stmt.step () == Sqlite.ROW) {
				mustRead = stmt.column_text(0);
			}

			sql = "category_id = \"\"";

			if(mustRead != "")
				sql += " OR category_id = \"%s\"".printf(mustRead);
		}
		else if(settings_general.get_enum("account-type") == Backend.OWNCLOUD)
		{
			sql = "category_id = 0";
		}


		return sql;
	}

	private string getUncategorizedFeedsQuery()
	{
		string sql = "feedID IN (%s)";

		var query = new QueryBuilder(QueryType.SELECT, "main.feeds");
		query.selectField("feed_id");
		query.addCustomCondition(getUncategorizedQuery());

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}

		string feedIDs = "";
		while (stmt.step () == Sqlite.ROW) {
			feedIDs += stmt.column_text(0) + ",";
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


	public int getNewestArticle()
	{
		int result = 0;

		var query = new QueryBuilder(QueryType.SELECT, "main.articles");
		query.selectField("articleID");
		query.addEqualsCondition("rowid", "%i".printf(getHighestRowID()));
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


	public GLib.List<feed> read_feeds()
	{
		GLib.List<feed> tmp = new GLib.List<feed>();
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
			tmp.append(tmpfeed);
		}

		return tmp;
	}


	private uint getFeedUnread(string feedID)
	{
		uint count = 0;

		var query = new QueryBuilder(QueryType.SELECT, "main.articles");
		query.selectField("count(*)");
		query.addEqualsCondition("unread", ArticleStatus.UNREAD.to_string());
		query.addEqualsCondition("feedID", feedID);
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


	public GLib.List<feed> read_feeds_without_cat()
	{
		GLib.List<feed> tmp = new GLib.List<feed>();
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
			tmp.append(tmpfeed);
		}

		return tmp;
	}

	public GLib.List<category> read_categories(GLib.List<feed>? feeds = null)
	{
		GLib.List<category> tmp = new GLib.List<category>();
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
			tmp.append(tmpcategory);
		}

		return tmp;
	}


	public GLib.List<tag> read_tags()
	{
		GLib.List<tag> tmp = new GLib.List<tag>();
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
			tmp.append(tmpTag);
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

	private string getAllTagsCondition()
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

	public GLib.List<category> read_categories_level(int level, GLib.List<feed>? feeds = null)
	{
		GLib.List<category> tmp = new GLib.List<category>();
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
			tmp.append(tmpcategory);
		}

		return tmp;
	}

	//[Profile]
	public GLib.List<article> read_articles(string ID, FeedListType selectedType, bool only_unread, bool only_marked, string searchTerm, uint limit = 20, uint offset = 0, int searchRows = 0)
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
				query.addCustomCondition("articleID IN (SELECT articleID FROM fts_table WHERE title MATCH \"%s\")".printf(Utils.parseSearchTerm(searchTerm)));
			}
			else if(searchTerm.has_prefix("author: "))
			{
				query.addCustomCondition("articleID IN (SELECT articleID FROM fts_table WHERE author MATCH \"%s\")".printf(Utils.parseSearchTerm(searchTerm)));
			}
			else if(searchTerm.has_prefix("content: "))
			{
				query.addCustomCondition("articleID IN (SELECT articleID FROM fts_table WHERE preview MATCH \"%s\")".printf(Utils.parseSearchTerm(searchTerm)));
			}
			else
			{
				query.addCustomCondition("articleID IN (SELECT articleID FROM fts_table WHERE fts_table MATCH \"%s\")".printf(Utils.parseSearchTerm(searchTerm)));
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


		GLib.List<article> tmp = new GLib.List<article>();
		while (stmt.step () == Sqlite.ROW)
		{
			tmp.append(new article(
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
