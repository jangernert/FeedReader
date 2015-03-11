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
												"unread" INTEGER NOT NULL,
												"category_id" TEXT,
												"subscribed" INTEGER DEFAULT 1
											)""");

			executeSQL(					"""CREATE  TABLE  IF NOT EXISTS "main"."categories"
											(
												"categorieID" TEXT PRIMARY KEY  NOT NULL  UNIQUE ,
												"title" TEXT NOT NULL,
												"unread" INTEGER,
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
												"date" DATETIME NOT NULL
											)""");

			executeSQL(					   """CREATE  TABLE  IF NOT EXISTS "main"."tags"
											(
												"tagID" TEXT PRIMARY KEY  NOT NULL  UNIQUE ,
												"title" TEXT NOT NULL,
												"exists" INTEGER,
												"color" INTEGER
												)""");

			executeSQL(			 			"""CREATE INDEX IF NOT EXISTS "index_articles" ON "articles" ("feedID" DESC, "unread" ASC, "marked" ASC)""");
	}


	private void executeSQL(string sql)
	{
		string errmsg;
		int ec = sqlite_db.exec (sql, null, out errmsg);
		if (ec != Sqlite.OK) {
			logger.print(LogMessage.ERROR, errmsg);
		}
	}


	public bool resetDB()
	{
		executeSQL("DROP TABLE \"main\".\"feeds\"");
		executeSQL("DROP TABLE \"main\".\"categories\"");
		executeSQL("DROP TABLE \"main\".\"articles\"");
		executeSQL("DROP TABLE \"main\".\"tags\"");
		executeSQL("VACUUM");

		string query = "PRAGMA INTEGRITY_CHECK";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			logger.print(LogMessage.ERROR, "%d: %s".printf(sqlite_db.errcode (), sqlite_db.errmsg ()));
		}

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


	public bool isTableEmpty(string table)
	{
		int count = -1;
		string query = "SELECT count(*) FROM \"main\".\"" + table + "\"";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			logger.print(LogMessage.ERROR, "%d: %s".printf(sqlite_db.errcode (), sqlite_db.errmsg ()));
		}

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
		string query = "SELECT count(*) FROM \"main\".\"articles\"";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
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



	public async void change_unread(string feedID, int increase)
	{
		SourceFunc callback = change_unread.callback;

		ThreadFunc<void*> run = () => {

			string change_feed_query = "";
			if(increase == ArticleStatus.UNREAD){
				change_feed_query = "UPDATE \"main\".\"feeds\" SET \"unread\" = \"unread\" + 1 WHERE \"feed_id\" = \"" + feedID + "\"";
			}
			else if(increase == ArticleStatus.READ){
				change_feed_query = "UPDATE \"main\".\"feeds\" SET \"unread\" = (CASE WHEN (\"unread\" > 0) THEN (\"unread\" - 1) ELSE \"unread\" END) WHERE \"feed_id\" = \"" + feedID + "\"";
			}
			executeSQL(change_feed_query);



			string get_feed_id_query = "SELECT \"category_id\" FROM \"main\".\"feeds\" WHERE \"feed_id\" = \"" + feedID + "\"";
			Sqlite.Statement stmt;
			int ec = sqlite_db.prepare_v2 (get_feed_id_query, get_feed_id_query.length, out stmt);
			if (ec != Sqlite.OK) {
				error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
			}
			string catID = CategoryID.NONE;
			int cols = stmt.column_count ();
			while (stmt.step () == Sqlite.ROW) {
				for (int i = 0; i < cols; i++) {
					catID = stmt.column_text(i);
				}
			}
			stmt.reset ();


			string change_catID_query = "";
			if(increase == ArticleStatus.UNREAD){
				change_catID_query = "UPDATE \"main\".\"categories\" SET \"unread\" = \"unread\" + 1 WHERE \"categorieID\" = \"" + catID + "\"";
			}
			else if(increase == ArticleStatus.READ){
				change_catID_query = "UPDATE \"main\".\"categories\" SET \"unread\" = (CASE WHEN (\"unread\" > 0) THEN (\"unread\" - 1) ELSE \"unread\" END) WHERE \"categorieID\" = \"" + catID + "\"";
			}
			executeSQL(change_catID_query);

			updateBadge();
			Idle.add((owned) callback);
			return null;
		};
		new GLib.Thread<void*>("change_unread", run);
		yield;
	}

	public uint get_unread_total()
	{
		string query = "SELECT unread FROM \"main\".\"categories\" WHERE \"level\" = 1 AND NOT \"categorieID\" = -1";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, "%d: %s".printf(sqlite_db.errcode(), sqlite_db.errmsg()));

		int unread = 0;
		while (stmt.step () == Sqlite.ROW) {
			unread += stmt.column_int(0);
		}
		stmt.reset ();
		return unread;
	}

	public uint get_unread_feed(string feedID)
	{
		string query = "SELECT unread FROM \"main\".\"feeds\" WHERE \"feed_id\" = %s".printf(feedID);
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, "%d: %s".printf(sqlite_db.errcode(), sqlite_db.errmsg()));

		int unread = 0;
		while (stmt.step() == Sqlite.ROW) {
			unread = stmt.column_int(0);
		}
		stmt.reset();
		return unread;
	}

	public uint get_unread_category(string catID)
	{
		string query = "SELECT unread FROM \"main\".\"categories\" WHERE \"categorieID\" = %s".printf(catID);
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
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

		string query = "INSERT OR REPLACE INTO \"main\".\"feeds\" (\"feed_id\",\"name\",\"url\",\"has_icon\",\"unread\", \"category_id\", \"subscribed\")
						VALUES ($FEEDID, $FEEDNAME, $FEEDURL, $HASICON, $UNREAD, $CATID, 1)";

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2(query, query.length, out stmt);
		if(ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());


		int feedID_pos   = stmt.bind_parameter_index("$FEEDID");
		int feedName_pos = stmt.bind_parameter_index("$FEEDNAME");
		int feedURL_pos  = stmt.bind_parameter_index("$FEEDURL");
		int hasIcon_pos  = stmt.bind_parameter_index("$HASICON");
		int unread_pos   = stmt.bind_parameter_index("$UNREAD");
		int catID_pos    = stmt.bind_parameter_index("$CATID");
		assert (feedID_pos > 0);
		assert (feedName_pos > 0);
		assert (feedURL_pos > 0);
		assert (hasIcon_pos > 0);
		assert (unread_pos > 0);
		assert (catID_pos > 0);

		foreach(var feed_item in feeds)
		{
			stmt.bind_text(feedID_pos, feed_item.m_feedID);
			stmt.bind_text(feedName_pos, feed_item.m_title);
			stmt.bind_text(feedURL_pos, feed_item.m_url);
			stmt.bind_int (hasIcon_pos, feed_item.m_hasIcon ? 1 : 0);
			stmt.bind_int (unread_pos, (int)feed_item.m_unread);
			stmt.bind_text(catID_pos, feed_item.m_categorieID);

			while(stmt.step() == Sqlite.ROW){}
			stmt.reset();
		}

		executeSQL("COMMIT TRANSACTION");
	}

	public void write_tags(ref GLib.List<tag> tags)
	{
		executeSQL("BEGIN TRANSACTION");

		string query = "INSERT OR IGNORE INTO \"main\".\"tags\" (\"tagID\",\"title\",\"exists\",\"color\") VALUES ($TAGID, $LABEL, 1, $COLOR)";

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
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
			stmt.bind_text(tagID_position, tag_item.m_tagID);
			stmt.bind_text(label_position, tag_item.m_title);
			stmt.bind_int (color_position, tag_item.m_color);

			while (stmt.step () == Sqlite.ROW) {}
			stmt.reset ();
		}

		executeSQL("COMMIT TRANSACTION");
	}


	public int getTagColor()
	{
		string query = "SELECT count(*) FROM \"main\".\"tags\" WHERE instr(\"tagID\", \"global.\") = 0";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
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
		executeSQL("UPDATE \"main\".\"tags\" SET \"color\" = " + color.to_string() + " WHERE \"tagID\" = \"" + tagID + "\"");
	}

	public void update_tag(string tagID)
	{
		executeSQL("UPDATE \"main\".\"tags\" SET \"exists\" = 1 WHERE \"tagID\" = \"" + tagID + "\"");
	}


	public void write_categories(ref GLib.List<category> categories)
	{
		executeSQL("BEGIN TRANSACTION");

		string query = "INSERT OR REPLACE INTO \"main\".\"categories\" (\"categorieID\",\"title\",\"unread\",\"orderID\", \"exists\", \"Parent\", \"Level\")
						VALUES ($CATID, $FEEDNAME, $UNREADCOUNT, $ORDERID, 1, $PARENT, $LEVEL)";

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());


		int catID_position       = stmt.bind_parameter_index("$CATID");
		int feedName_position    = stmt.bind_parameter_index("$FEEDNAME");
		int unreadCount_position = stmt.bind_parameter_index("$UNREADCOUNT");
		int orderID_position     = stmt.bind_parameter_index("$ORDERID");
		int parent_position      = stmt.bind_parameter_index("$PARENT");
		int level_position       = stmt.bind_parameter_index("$LEVEL");
		assert (catID_position > 0);
		assert (feedName_position > 0);
		assert (unreadCount_position > 0);
		assert (orderID_position > 0);
		assert (parent_position > 0);
		assert (level_position > 0);

		foreach(var cat_item in categories)
		{
			stmt.bind_text(catID_position, cat_item.m_categorieID);
			stmt.bind_text(feedName_position, cat_item.m_title);
			stmt.bind_int (unreadCount_position, cat_item.m_unread_count);
			stmt.bind_int (orderID_position, cat_item.m_orderID);
			stmt.bind_text(parent_position, cat_item.m_parent);
			stmt.bind_int (level_position, cat_item.m_level);

			while (stmt.step () == Sqlite.ROW) {}
			stmt.reset ();
		}

		executeSQL("COMMIT TRANSACTION");
	}

	public string read_preview(string articleID)
	{
		string query = "SELECT preview FROM \"main\".\"articles\" WHERE \"articleID\" = \"" + articleID + "\"";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
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
		string query = "SELECT name FROM \"main\".\"feeds\" WHERE \"feed_id\" = \"" + feedID + "\"";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, "reading preview - %s".printf(sqlite_db.errmsg()));

		string result = "";

		while (stmt.step () == Sqlite.ROW) {
			result = stmt.column_text(0);
		}

		return result;
	}


	public bool preview_empty(string articleID)
	{
		string query = "SELECT count(*) FROM \"main\".\"articles\" WHERE \"articleID\" = \"" + articleID + "\" AND NOT preview = \"\"";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			logger.print(LogMessage.ERROR, "checking for empty preview - %s".printf(sqlite_db.errmsg()));
		}

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
		query.build();

		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2(query.get(), query.get().length, out stmt);
		query.reset();

		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());



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


		foreach(var article in articles)
		{
			stmt.bind_text(articleID_position, article.getArticleID());
			stmt.bind_text(feedID_position, article.m_feedID);
			stmt.bind_text(url_position, article.m_url);
			stmt.bind_int (unread_position, article.m_unread);
			stmt.bind_int (marked_position, article.m_marked);
			stmt.bind_text(tags_position, article.m_tags);
			stmt.bind_text(title_position, article.m_title);
			stmt.bind_text(html_position, article.getHTML());
			stmt.bind_text(preview_position, article.getPreview());
			stmt.bind_text(author_position, article.getAuthor());
			stmt.bind_text(date_position, article.getDateStr());

			while(stmt.step () == Sqlite.ROW) {}
			stmt.reset();
		}

		var update_query = new QueryBuilder(QueryType.UPDATE, "main.articles");
		update_query.updateValuePair("unread", "$UNREAD");
		update_query.updateValuePair("marked", "$MARKED");
		update_query.updateValuePair("tags", "$TAGS");
		update_query.addEqualsCondition("articleID", "$ARTICLEID");
		update_query.build();

		ec = sqlite_db.prepare_v2 (update_query.get(), update_query.get().length, out stmt);
		update_query.reset();

		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		unread_position = stmt.bind_parameter_index("$UNREAD");
		marked_position = stmt.bind_parameter_index("$MARKED");
		tags_position = stmt.bind_parameter_index("$TAGS");
		articleID_position = stmt.bind_parameter_index("$ARTICLEID");
		assert (unread_position > 0);
		assert (marked_position > 0);
		assert (tags_position > 0);
		assert (articleID_position > 0);

		foreach(var article in articles)
		{
			stmt.bind_text(unread_position, article.m_unread.to_string());
			stmt.bind_text(marked_position, article.m_marked.to_string());
			stmt.bind_text(tags_position, article.m_tags);
			stmt.bind_text(articleID_position, article.getArticleID());

			while(stmt.step () == Sqlite.ROW) {}
			stmt.reset();
		}

		executeSQL("COMMIT TRANSACTION");
	}


	public article read_article(string articleID)
	{
		article tmp = null;
		string query = "SELECT ROWID, * FROM \"main\".\"articles\" WHERE \"articleID\" = \"" + articleID + "\"";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		while (stmt.step () == Sqlite.ROW) {
			tmp = new article(
								articleID,
								stmt.column_text(3),
								stmt.column_text(5),
								stmt.column_text(2),
								stmt.column_int(8),
								stmt.column_int(9),
								stmt.column_text(6),
								stmt.column_text(7),
								stmt.column_text(4),
								Utils.convertStringToDate(stmt.column_text(11)),
								stmt.column_int(0),
								stmt.column_text(10)
							);
		}
		stmt.reset ();
		return tmp;
	}


	public async void update_article(string articleIDs, string field, int field_value)
	{
		SourceFunc callback = update_article.callback;

		ThreadFunc<void*> run = () => {
			executeSQL("UPDATE \"main\".\"articles\" SET \"" + field + "\" = \"" + field_value.to_string() + "\" WHERE \"articleID\" IN (" + articleIDs + ")");
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
			string query = "SELECT unread, category_id FROM \"main\".\"feeds\" WHERE \"feed_id\" = \"" + feedID + "\"";
			Sqlite.Statement stmt;
			int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
			if (ec != Sqlite.OK)
				logger.print(LogMessage.ERROR, "reading preview - %s".printf(sqlite_db.errmsg()));

			int unread = 0;
			string catID = "";
			while (stmt.step () == Sqlite.ROW) {
				unread = stmt.column_int(0);
				catID = stmt.column_text(1);
			}

			executeSQL("UPDATE \"main\".\"articles\" SET \"unread\" = 8 WHERE \"feedID\" = \"" + feedID + "\"");
			executeSQL("UPDATE \"main\".\"feeds\" SET \"unread\" = 0 WHERE \"feed_id\" = \"" + feedID + "\"");
			executeSQL("UPDATE \"main\".\"categories\" SET \"unread\" = \"unread\" - " + unread.to_string() + " WHERE categorieID = \"" + catID + "\"");
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

			var query1 = new QueryBuilder(QueryType.UPDATE, "main.articles");
			query1.updateValuePair("unread", ArticleStatus.UNREAD.to_string());
			query1.addRangeConditionString("feedID", getFeedIDofCategorie(catID));
			executeSQL(query1.build());

			var query2 = new QueryBuilder(QueryType.UPDATE, "main.feeds");
			query2.updateValuePair("unread", "0");
			query2.addRangeConditionString("feed_id", getFeedIDofCategorie(catID));
			executeSQL(query2.build());

			var query3 = new QueryBuilder(QueryType.UPDATE, "main.categories");
			query3.updateValuePair("unread", "0");
			query3.addEqualsCondition("categorieID", "\"%s\"".printf(catID));
			executeSQL(query3.build());

			Idle.add((owned) callback);
			return null;
		};
		new GLib.Thread<void*>("markCategorieRead", run);
		yield;
	}

	public int getMaxCatLevel()
	{
		int maxCatLevel = 0;
		string query = "SELECT max(Level) FROM \"main\".\"categories\" WHERE categorieID >= 0";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		while (stmt.step () == Sqlite.ROW) {
			maxCatLevel = stmt.column_int(0);
		}
		return maxCatLevel;
	}


	public void reset_subscribed_flag()
	{
		executeSQL("UPDATE \"main\".\"feeds\" SET \"subscribed\" = 0");
	}

	public void reset_exists_tag()
	{
		executeSQL("UPDATE \"main\".\"tags\" SET \"exists\" = 0");
	}

	public void reset_exists_flag()
	{
		executeSQL("UPDATE \"main\".\"categories\" SET \"exists\" = 0");
	}



	public void delete_unsubscribed_feeds()
	{
		executeSQL("DELETE FROM \"main\".\"feeds\" WHERE \"subscribed\" = 0");
	}


	public void delete_nonexisting_categories()
	{
		executeSQL("DELETE FROM \"main\".\"categories\" WHERE \"exists\" = 0");
	}

	public void delete_nonexisting_tags()
	{
		executeSQL("DELETE FROM \"main\".\"tags\" WHERE \"exists\" = 0");
	}

	public void delete_articles(int feedID)
	{
		executeSQL("DELETE FROM \"main\".\"articles\" WHERE \"feedID\" = \"" + feedID.to_string() + "\"");
	}


	public bool article_exists(string articleID)
	{
		int result = 0;
		string query = "SELECT EXISTS(SELECT 1 FROM \"main\".\"articles\" WHERE articleID = \"" + articleID + "\" LIMIT 1)";
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


	public int getRowNumberHeadline(string date)
	{
		int result = 0;
		string query = "SELECT count(*) FROM main.articles WHERE date >= \"%s\" ORDER BY date DESC".printf(date);
		logger.print(LogMessage.DEBUG, query);
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		while (stmt.step () == Sqlite.ROW) {
			result = stmt.column_int(0);
		}
		return result;
	}


	public void updateCategorie(int catID, int unread)
	{
		executeSQL("UPDATE main.categories SET unread = \"" + unread.to_string() + "\" WHERE categorieID = \"" + catID.to_string() + "\"");
	}


	private GLib.List<string> getFeedIDofCategorie(string categorieID)
	{
		var feedIDs = new GLib.List<string>();

		string query = "SELECT feed_id FROM \"main\".\"feeds\" WHERE \"category_id\" = " + "\"" + categorieID + "\"";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2(query, query.length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		while (stmt.step() == Sqlite.ROW) {
			feedIDs.append(stmt.column_text(0));
		}
		return feedIDs;
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


	public void markReadAllArticles()
	{
		executeSQL("UPDATE \"main\".\"articles\" SET \"unread\"=" + ArticleStatus.READ.to_string());
	}


	public void unmarkAllArticles()
	{
		executeSQL("UPDATE \"main\".\"articles\" SET \"marked\"=" + ArticleStatus.UNMARKED.to_string());
	}


	public int getNewestArticle()
	{
		int result = 0;
		string query = "SELECT \"articleID\" FROM \"main\".\"articles\" WHERE \"ROWID\" = " + getHighestRowID().to_string();
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
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
		string query = "SELECT max(\"ROWID\") FROM \"main\".\"articles\"";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
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

		string query = "SELECT * FROM \"main\".\"feeds\"";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		while (stmt.step () == Sqlite.ROW) {
			tmpfeed = new feed(stmt.column_text(0), stmt.column_text(1), stmt.column_text(2), ((stmt.column_int(3) == 1) ? true : false), (uint)stmt.column_int(4), stmt.column_text(5));
			tmp.append(tmpfeed);
		}

		return tmp;
	}

	public GLib.List<category> read_categories()
	{
		GLib.List<category> tmp = new GLib.List<category>();
		category tmpcategory;

		string query = "SELECT * FROM \"main\".\"categories\" WHERE categorieID >= 0 ORDER BY orderID DESC";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		while (stmt.step () == Sqlite.ROW) {
			tmpcategory = new category(stmt.column_text(0), stmt.column_text(1), stmt.column_int(2), stmt.column_int(3), stmt.column_text(5), stmt.column_int(6));
			tmp.append(tmpcategory);
		}

		return tmp;
	}


	public GLib.List<tag> read_tags()
	{
		GLib.List<tag> tmp = new GLib.List<tag>();
		tag tmpTag;

		string query = "SELECT * FROM \"main\".\"tags\" WHERE instr(\"tagID\", \"global.\") = 0";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		while (stmt.step () == Sqlite.ROW) {
			tmpTag = new tag(stmt.column_text(0), stmt.column_text(1), stmt.column_int(3));
			tmp.append(tmpTag);
		}

		return tmp;
	}

	private string getAllTagsCondition()
	{
		var tags = read_tags();
		string query = "";
		foreach(var Tag in tags)
		{
			query += "instr(\"tags\", \"%s\") > 0 OR ".printf(Tag.m_tagID);
		}

		int or = query.char_count()-4;
		return query.substring(0, or);
	}

	public GLib.List<category> read_categories_level(int level)
	{
		GLib.List<category> tmp = new GLib.List<category>();
		category tmpcategory;

		string query = "SELECT * FROM \"main\".\"categories\" WHERE categorieID >= 0 AND \"level\" = \"" + level.to_string() + "\" ORDER BY orderID DESC";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK)
			logger.print(LogMessage.ERROR, sqlite_db.errmsg());

		while (stmt.step () == Sqlite.ROW) {
			tmpcategory = new category(stmt.column_text(0), stmt.column_text(1), stmt.column_int(2), stmt.column_int(3), stmt.column_text(5), stmt.column_int(6));
			tmp.append(tmpcategory);
		}

		return tmp;
	}

	//[Profile]
	public GLib.List<article> read_articles(string ID, int selectedType, bool only_unread, bool only_marked, string searchTerm, uint limit = 20, uint offset = 0)
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

		if(selectedType == FeedList.FEED && ID != FeedID.ALL)
		{
			query.addEqualsCondition("feedID", "\"%s\"".printf(ID));
		}
		else if(selectedType == FeedList.CATEGORY && ID != CategoryID.MASTER && ID != CategoryID.TAGS)
		{
			query.addRangeConditionString("feedID", getFeedIDofCategorie(ID));
		}
		else if(ID == CategoryID.TAGS)
		{
			query.addCustomCondition(getAllTagsCondition());
		}
		else if(selectedType == FeedList.TAG)
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
			query.addCustomCondition("instr(UPPER(title), UPPER(\"%s\")) > 0".printf(searchTerm));
		}

		string order_field = "rowid";
		if(settings_general.get_boolean("articlelist-sort-by-date"))
			order_field = "date";

		bool desc = false;
		if(settings_general.get_boolean("articlelist-newest-first"))
			desc = true;

		query.orderBy(order_field, desc);
		query.limit(limit);
		query.offset(offset);
		query.build();


		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query.get(), query.get().length, out stmt);
		if(ec != Sqlite.OK)
			logger.print(LogMessage.DEBUG, sqlite_db.errmsg());


		GLib.List<article> tmp = new GLib.List<article>();
		while (stmt.step () == Sqlite.ROW) {
			tmp.append(new article(
								stmt.column_text(2),								// articleID
								stmt.column_text(3),								// title
								stmt.column_text(5),								// url
								stmt.column_text(1),								// feedID
								stmt.column_int(7),									// unread
								stmt.column_int(8),									// marked
								"",													// html
								stmt.column_text(6),								// preview
								stmt.column_text(4),								// author
								Utils.convertStringToDate(stmt.column_text(10)),	// date
								stmt.column_int(0),									// sortID
								stmt.column_text(9)									// tags
							));
		}

		return tmp;
	}


}
