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
				warning("Can't create directory for database!\n ErrorMessage: %s\n", e.message);
			}
		}
		int rc = Sqlite.Database.open_v2(db_path + "feedreader-02.db", out sqlite_db);
		if (rc != Sqlite.OK) {
			error("Can't open database: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		sqlite_db.busy_timeout(1000);
	}

	public void init()
	{
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
												"tags" TEXT
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
		stmt.reset ();
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

		return count;
	}



	public async void change_unread(string feedID, int increase)
	{
		SourceFunc callback = change_unread.callback;
		
		ThreadFunc<void*> run = () => {

			string change_feed_query = "UPDATE \"main\".\"feeds\" SET \"unread\" = \"unread\" ";
			if(increase == ArticleStatus.UNREAD){
				change_feed_query = change_feed_query + "+ 1";
			}
			else if(increase == ArticleStatus.READ){
				change_feed_query = change_feed_query + "- 1";
			} 
			change_feed_query = change_feed_query + " WHERE \"feed_id\" = \"" + feedID + "\"";
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


			string change_catID_query = "UPDATE \"main\".\"categories\" SET \"unread\" = \"unread\" ";
			if(increase == ArticleStatus.UNREAD){
				change_catID_query = change_catID_query + "+ 1";
			}
			else if(increase == ArticleStatus.READ){
				change_catID_query = change_catID_query + "- 1";
			}
			change_catID_query = change_catID_query + " WHERE \"categorieID\" = \"" + catID + "\"";
			executeSQL(change_catID_query);

			updateBadge();
			Idle.add((owned) callback);
			return null;
		};
		new GLib.Thread<void*>("change_unread", run);
		yield;
	}
	
	public int get_unread_total()
	{
		string query = "SELECT unread FROM \"main\".\"categories\" WHERE \"level\" = 1 AND NOT \"categorieID\" = -1";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		int unread = 0;
		while (stmt.step () == Sqlite.ROW) {
			unread += stmt.column_int(0);
		}
		stmt.reset ();
		return unread;
	}

	public void write_feed(string feed_id, string feed_name, string feed_url, bool has_icon, int unread_count, string cat_id)
	{
		int int_has_icon = 0;
		if(has_icon) int_has_icon = 1;
		
		string query = "INSERT OR REPLACE INTO \"main\".\"feeds\" (\"feed_id\",\"name\",\"url\",\"has_icon\",\"unread\", \"category_id\", \"subscribed\") 
						VALUES (\"" + feed_id + "\", $FEEDNAME, $FEEDURL, \"" + int_has_icon.to_string() + "\", \"" + unread_count.to_string() + "\", \"" + cat_id + "\", 1)";
		
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			warning("error writing feed\nquery: %s\nfeed_name: %s\n", query, feed_name);
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		int param_position = stmt.bind_parameter_index ("$FEEDNAME");
		assert (param_position > 0);
		stmt.bind_text (param_position, feed_name);
		param_position = stmt.bind_parameter_index ("$FEEDURL");
		assert (param_position > 0);
		stmt.bind_text (param_position, feed_url);
		
		while (stmt.step () == Sqlite.ROW) {
		
		}
		stmt.reset ();
	}
	
	public void write_tag(string tagID, string label)
	{
		string query1 = "SELECT count(*) FROM \"main\".\"tags\" WHERE instr(\"tagID\", \"global.\") = 0";
		Sqlite.Statement stmt1;
		int ec = sqlite_db.prepare_v2 (query1, query1.length, out stmt1);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		int tagCount = 0;
		while (stmt1.step () == Sqlite.ROW) {
			tagCount = stmt1.column_int(0);
		}
		stmt1.reset ();
		
		int colorCount = COLORS.length;
		int colorNumber = (tagCount%colorCount);
		
		string query = "INSERT OR IGNORE INTO \"main\".\"tags\" (\"tagID\",\"title\",\"exists\",\"color\") VALUES (\"" + tagID + "\", $LABEL, 1, " + colorNumber.to_string() + ")";
		
		Sqlite.Statement stmt;
		ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		int param_position = stmt.bind_parameter_index ("$LABEL");
		assert (param_position > 0);
		stmt.bind_text (param_position, label);
		
		while (stmt.step () == Sqlite.ROW) {}
		stmt.reset ();
	}
	
	public void update_tag_color(string tagID, int color)
	{
		string query = "UPDATE \"main\".\"tags\" SET \"color\" = " + color.to_string() + " WHERE \"tagID\" = \"" + tagID + "\"";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		
		while (stmt.step () == Sqlite.ROW) {}
		stmt.reset ();
	}
	
	public void update_tag(string tagID)
	{
		string query = "UPDATE \"main\".\"tags\" SET \"exists\" = 1 WHERE \"tagID\" = \"" + tagID + "\"";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		
		while (stmt.step () == Sqlite.ROW) {}
		stmt.reset ();
	}


	public void write_categorie(string categorieID, string categorie_name, int unread_count, int orderID, string parent, int level)
	{
		string query = "INSERT OR REPLACE INTO \"main\".\"categories\" (\"categorieID\",\"title\",\"unread\",\"orderID\", \"exists\", \"Parent\", \"Level\") 
						VALUES (\"" + categorieID + "\", $FEEDNAME, \"" + unread_count.to_string() + "\", \"" + orderID.to_string() + "\", 1, \"" + parent + "\", \"" + level.to_string() + "\")";
		
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			warning("error writing category\nquery: %s\ncategory_name: %s\n", query, categorie_name);
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		int param_position = stmt.bind_parameter_index ("$FEEDNAME");
		assert (param_position > 0);
		stmt.bind_text (param_position, categorie_name);
		while (stmt.step () == Sqlite.ROW) {
			
		}
		stmt.reset ();
	}
	
	
	public int preview_empty(string articleID)
	{
		string query = "SELECT count(*) FROM \"main\".\"articles\" WHERE \"articleID\" = \"" + articleID + "\" AND NOT preview = \"\"";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		
		int result = 1;
		
		while (stmt.step () == Sqlite.ROW) {
			result = stmt.column_int(0);
		}
		
		return result;
	}


	
	public void write_article(string articleID, string feedID, string title, string author, string url, int unread, int marked, int insert_replace, string html, string tags, string preview = "")
	{
		// FIXME check if preview already exists and dont generate it again
		// SELECT count(*) FROM main.articles WHERE articleID = "34134" AND preview = ""
		string output = _("No Preview Available");
		int preview_exists = preview_empty(articleID);
		
		if(preview_exists == 0 && html != "")
		{
			string filename = GLib.Environment.get_tmp_dir() + "/" + "articleHtml.XXXXXX";
			int outputfd = GLib.FileUtils.mkstemp(filename);
			try{
				if(preview == "")
					GLib.FileUtils.set_contents(filename, html);
				else
					GLib.FileUtils.set_contents(filename, preview);
			}catch(GLib.FileError e){
				logger.print(LogMessage.ERROR, "error writing html to tmp file - %s".printf(e.message));
			}
			GLib.FileUtils.close(outputfd);

			string[] spawn_args = {"html2text", "-utf8", "-nobs", filename};
			try{
				GLib.Process.spawn_sync(null, spawn_args, null , GLib.SpawnFlags.SEARCH_PATH, null, out output, null, null);
			}catch(GLib.SpawnError e){
				logger.print(LogMessage.ERROR, "html2text: %s".printf(e.message));
			}

			string prefix = "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>";
			if(output.has_prefix(prefix))
			{
				output = output.slice(prefix.length, output.length);
			}

			int length = 300;
			if(output.length < 300)
				length = output.length;

			output = output.replace("\n"," ");
			output = output.slice(0, length);
			output = output.slice(0, output.last_index_of(" "));
			output = output.chug();
		}
		
		if(html == "")
		{
			html = _("No Text available for this article :(");
		}
		
		
		string query = "";
		if(insert_replace == DataBase.INSERT_OR_IGNORE)
		{
			string command = "INSERT OR IGNORE INTO \"main\".\"articles\" ";
			string fields = "(\"articleID\",\"feedID\",\"title\",\"author\",\"url\",\"html\",\"preview\", \"unread\", \"marked\", \"tags\") ";
			string values = "VALUES (\"" + articleID + "\", \"" + feedID + "\", $TITLE, $AUTHOR, \"" + url + "\", $HTML, $PREVIEW, " + unread.to_string() + ", " + marked.to_string() + ", \"" + tags + "\")";
			
			query = command + fields + values;
		}
		else if(insert_replace == DataBase.UPDATE_ROW)
		{
			query = "UPDATE \"main\".\"articles\" SET \"unread\" = " + unread.to_string() + ", \"marked\" = " + marked.to_string() + ", \"tags\" = \"" + tags + "\" WHERE \"articleID\"= \"" + articleID + "\"";
		}
						
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			warning("error writing article\nquery: %s\nhtml: %s\n", query, preview);
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		
		if(insert_replace == DataBase.INSERT_OR_IGNORE)
		{
			int param_position = stmt.bind_parameter_index ("$TITLE");
			assert (param_position > 0);
			stmt.bind_text (param_position, title);
			param_position = stmt.bind_parameter_index ("$HTML");
			assert (param_position > 0);
			stmt.bind_text (param_position, html);
			param_position = stmt.bind_parameter_index ("$PREVIEW");
			assert (param_position > 0);
			stmt.bind_text (param_position, output);
			param_position = stmt.bind_parameter_index ("$AUTHOR");
			assert (param_position > 0);
			stmt.bind_text (param_position, author);
		}
		
		while (stmt.step () == Sqlite.ROW) {
			
		}
		stmt.reset ();
	}

	
	[Profile] public article read_article(string articleID)
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
								stmt.column_int(0),
								stmt.column_text(10)
							);
		}
		stmt.reset ();
		return tmp;
	}
	

	public async void update_article(string articleID, string field, int field_value)
	{
		SourceFunc callback = update_article.callback;
		
		ThreadFunc<void*> run = () => {
			string query = "UPDATE \"main\".\"articles\" SET \"" + field + "\" = \"" + field_value.to_string() + "\" WHERE \"articleID\"= \"" + articleID + "\"";
			string errmsg;
			int ec = sqlite_db.exec (query, null, out errmsg);
			if (ec != Sqlite.OK) {
				error("Error: %s\n", errmsg);
			}
			Idle.add((owned) callback);
			return null;
		};
		new GLib.Thread<void*>("update_article", run);
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
		string query = "UPDATE \"main\".\"feeds\" SET \"subscribed\" = 0";
		string errmsg;
		int ec = sqlite_db.exec (query, null, out errmsg);
		if (ec != Sqlite.OK) {
			error("Error: %s\n", errmsg);
		}
	}
	
	public void reset_exists_tag()
	{
		string query = "UPDATE \"main\".\"tags\" SET \"exists\" = 0";
		string errmsg;
		int ec = sqlite_db.exec (query, null, out errmsg);
		if (ec != Sqlite.OK) {
			error("Error: %s\n", errmsg);
		}
	}

	public void reset_exists_flag()
	{
		string query = "UPDATE \"main\".\"categories\" SET \"exists\" = 0";
		string errmsg;
		int ec = sqlite_db.exec (query, null, out errmsg);
		if (ec != Sqlite.OK) {
			error("Error: %s\n", errmsg);
		}
	}



	public void delete_unsubscribed_feeds()
	{
		string query = "DELETE FROM \"main\".\"feeds\" WHERE \"subscribed\" = 0";
		string errmsg;
		int ec = sqlite_db.exec (query, null, out errmsg);
		if (ec != Sqlite.OK) {
			error("Error: %s\n", errmsg);
		}
	}


	public void delete_nonexisting_categories()
	{
		string query = "DELETE FROM \"main\".\"categories\" WHERE \"exists\" = 0";
		string errmsg;
		int ec = sqlite_db.exec (query, null, out errmsg);
		if (ec != Sqlite.OK) {
			error("Error: %s\n", errmsg);
		}
	}
	
	public void delete_nonexisting_tags()
	{
		string query = "DELETE FROM \"main\".\"tags\" WHERE \"exists\" = 0";
		string errmsg;
		int ec = sqlite_db.exec (query, null, out errmsg);
		if (ec != Sqlite.OK) {
			error("Error: %s\n", errmsg);
		}
	}

	public void delete_articles(int feedID)
	{
		string query = "DELETE FROM \"main\".\"articles\" WHERE \"feedID\" = \"" + feedID.to_string() + "\"";
		string errmsg;
		int ec = sqlite_db.exec (query, null, out errmsg);
		if (ec != Sqlite.OK) {
			error("Error: %s\n", errmsg);
		}
	}


	public int getRowNumberHeadline(string articleID)
	{
		int result = 0;
		string query = "SELECT count(*) FROM main.articles WHERE articleID >= \"" + articleID + "\" ORDER BY ROWID DESC";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		while (stmt.step () == Sqlite.ROW) {
			result = stmt.column_int(0);
		}
		return result;
	}


	public void updateCategorie(int catID, int unread)
	{
		string query = "UPDATE main.categories SET unread = \"" + unread.to_string() + "\" WHERE categorieID = \"" + catID.to_string() + "\"";
		string errmsg;
		int ec = sqlite_db.exec (query, null, out errmsg);
		if (ec != Sqlite.OK) {
			error("Error: %s\n", errmsg);
		}
	}


	private string getFeedIDofCategorie(string categorieID)
	{
		string query = "\"feedID\" IN (";
		string query2 = "SELECT feed_id FROM \"main\".\"feeds\" WHERE \"category_id\" = " + "\"" + categorieID + "\"";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query2, query2.length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		while (stmt.step () == Sqlite.ROW) {
			query = query + "\"" + stmt.column_text(0) + "\", ";
		}
		return query.slice(0, query.length-2) + ")";
	}
	
	
	public string getFeedIDofArticle(string articleID)
	{
		string query = "SELECT feedID FROM \"main\".\"articles\" WHERE \"articleID\" = " + "\"" + articleID + "\"";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		string id = "";
		while (stmt.step () == Sqlite.ROW) {
			id = stmt.column_text(0);
		}
		return id;
	}


	public void markReadAllArticles()
	{
		string query = "UPDATE \"main\".\"articles\" SET \"unread\"=" + ArticleStatus.READ.to_string();
		string errmsg;
		int ec = sqlite_db.exec (query, null, out errmsg);
		if (ec != Sqlite.OK) {
			error("Error: %s\n", errmsg);
		}
	}


	public void unmarkAllArticles()
	{
		string query = "UPDATE \"main\".\"articles\" SET \"marked\"=" + ArticleStatus.UNMARKED.to_string();
		string errmsg;
		int ec = sqlite_db.exec (query, null, out errmsg);
		if (ec != Sqlite.OK) {
			error("Error: %s\n", errmsg);
		}
	}


	public int getNewestArticle()
	{
		int result = 0;
		string query = "SELECT \"articleID\" FROM \"main\".\"articles\" WHERE \"ROWID\" = " + getHighestRowID().to_string();
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
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
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
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
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		while (stmt.step () == Sqlite.ROW) {
			tmpfeed = new feed(stmt.column_text(0), stmt.column_text(1), stmt.column_text(2), stmt.column_int(3), stmt.column_int(4), stmt.column_text(5));
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
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
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
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		while (stmt.step () == Sqlite.ROW) {
			tmpTag = new tag(stmt.column_text(0), stmt.column_text(1), stmt.column_int(3));
			tmp.append(tmpTag);
		}
		
		return tmp;
	}
	
	private string getAllTagsQuery()
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
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		while (stmt.step () == Sqlite.ROW) {
			tmpcategory = new category(stmt.column_text(0), stmt.column_text(1), stmt.column_int(2), stmt.column_int(3), stmt.column_text(5), stmt.column_int(6));
			tmp.append(tmpcategory);
		}

		return tmp;
	}

	[Profile] public GLib.List<article> read_articles(string ID, int selectedType, bool only_unread, bool only_marked, string searchTerm, int limit = 100, int offset = 0)
	{
		GLib.List<article> tmp = new GLib.List<article>();
		string and = "";
		string query = "SELECT ROWID, feedID, articleID, title, author, url, preview, unread, marked, tags FROM \"main\".\"articles\"";
		
		if( (ID != FeedID.ALL && selectedType == FeedList.FEED)
		|| (selectedType == FeedList.CATEGORY && ID != CategoryID.MASTER)
		|| (selectedType == FeedList.TAG)
		|| only_unread
		|| only_marked
		|| searchTerm != "")
			query = query + " WHERE ";
		
		
		if(selectedType == FeedList.FEED)
		{
			if(ID != FeedID.ALL){
				query = query + "\"feedID\" = " + "\"" + ID + "\"";
				and = " AND ";
			}
		}
		else if(selectedType == FeedList.CATEGORY && ID != CategoryID.MASTER && ID != CategoryID.TAGS)
		{
				query = query + getFeedIDofCategorie(ID);
				and = " AND ";
		}
		else if(ID == CategoryID.TAGS)
		{
			query = query + getAllTagsQuery();
		}
		else if(selectedType == FeedList.TAG)
		{
			query = query + "instr(\"tags\", \"" + ID + "\") > 0";
		}
		if(only_unread){
			query = query + and + "\"unread\" = " + ArticleStatus.UNREAD.to_string();
			and = " AND ";
		}
		if(only_marked){
			query = query + and + "\"marked\" = " + ArticleStatus.MARKED.to_string();
			and = " AND ";
		}
		if(searchTerm != ""){
			query = query + and + "instr(UPPER(\"title\"), UPPER(\"" + searchTerm + "\")) > 0";
		}
		query = query + " ORDER BY ROWID DESC LIMIT " + limit.to_string() + " OFFSET " + offset.to_string();
		
		logger.print(LogMessage.DEBUG, query);
		article tmpArticle;
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		while (stmt.step () == Sqlite.ROW) {
			tmpArticle = new article(
								stmt.column_text(2),	// articleID
								stmt.column_text(3),	// title
								stmt.column_text(5),	// url
								stmt.column_text(1),	// feedID
								stmt.column_int(7),		// unread
								stmt.column_int(8),		// marked
								"",						// html
								stmt.column_text(6),	// preview
								stmt.column_text(4),	// author
								stmt.column_int(0),		// sortID
								stmt.column_text(9)		// tags
							);
			tmp.append(tmpArticle);
		}
		
		return tmp;
	}

	 
}
