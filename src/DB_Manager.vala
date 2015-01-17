/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * db-manager.vala
 * Copyright (C) 2014 JeanLuc <jeanluc@jeanluc-desktop>
 *
 * tt-rss is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * tt-rss is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public class dbManager : GLib.Object {

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
			string feeds =					"""CREATE  TABLE  IF NOT EXISTS "main"."feeds" 
											(
												"feed_id" TEXT PRIMARY KEY  NOT NULL UNIQUE ,
												"name" TEXT NOT NULL,
												"url" TEXT NOT NULL,
												"has_icon" INTEGER NOT NULL,
												"unread" INTEGER NOT NULL,
												"category_id" TEXT,
												"subscribed" INTEGER DEFAULT 1
											)""";

			string categories =				"""CREATE  TABLE  IF NOT EXISTS "main"."categories" 
											(
												"categorieID" TEXT PRIMARY KEY  NOT NULL  UNIQUE ,
												"title" TEXT NOT NULL,
												"unread" INTEGER,
												"orderID" INTEGER,
												"exists" INTEGER,
												"Parent" TEXT,
												"Level" INTEGER
												)""";
												
			string articles =				"""CREATE  TABLE  IF NOT EXISTS "main"."articles"
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
												"sortID" INTEGER NOT NULL,
												"tags" TEXT
											)""";
			
			string tags =				   """CREATE  TABLE  IF NOT EXISTS "main"."tags" 
											(
												"tagID" TEXT PRIMARY KEY  NOT NULL  UNIQUE ,
												"title" TEXT NOT NULL,
												"unread" INTEGER,
												"exists" INTEGER,
												"color" TEXT
												)""";
	
			string errmsg;
			int ec = sqlite_db.exec (feeds, null, out errmsg);
			if (ec != Sqlite.OK) {
				error("Error: %s\n", errmsg);
			}
			ec = sqlite_db.exec (articles, null, out errmsg);
			if (ec != Sqlite.OK) {
				error("Error: %s\n", errmsg);
			}
			ec = sqlite_db.exec (categories, null, out errmsg);
			if (ec != Sqlite.OK) {
				error("Error: %s\n", errmsg);
			}
			ec = sqlite_db.exec (tags, null, out errmsg);
			if (ec != Sqlite.OK) {
				error("Error: %s\n", errmsg);
			}
	}


	public bool isTableEmpty(string table)
	{
		int count = -1;
		string query = "SELECT count(*) FROM \"main\".\"" + table + "\"";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
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



	public async void change_unread(string feedID, int increase)
	{
		SourceFunc callback = change_unread.callback;
		
		ThreadFunc<void*> run = () => {

			string change_feed_query = "UPDATE \"main\".\"feeds\" SET \"unread\" = \"unread\" ";
			if(increase == STATUS_UNREAD){
				change_feed_query = change_feed_query + "+ 1";
			}
			else if(increase == STATUS_READ){
				change_feed_query = change_feed_query + "- 1";
			} 
			change_feed_query = change_feed_query + " WHERE \"feed_id\" = \"" + feedID + "\"";
			string errmsg;
			int ec = sqlite_db.exec (change_feed_query, null, out errmsg);
			if (ec != Sqlite.OK) {
				error("Error: %s\n", errmsg);
			}
			

			
			string get_feed_id_query = "SELECT \"category_id\" FROM \"main\".\"feeds\" WHERE \"feed_id\" = \"" + feedID + "\"";
			Sqlite.Statement stmt;
			ec = sqlite_db.prepare_v2 (get_feed_id_query, get_feed_id_query.length, out stmt);
			if (ec != Sqlite.OK) {
				error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
			}
			string catID = CAT_ID_NONE;
			int cols = stmt.column_count ();
			while (stmt.step () == Sqlite.ROW) {
				for (int i = 0; i < cols; i++) {
					catID = stmt.column_text(i);
				}
			}
			stmt.reset ();


			string change_catID_query = "UPDATE \"main\".\"categories\" SET \"unread\" = \"unread\" ";
			if(increase == STATUS_UNREAD){
				change_catID_query = change_catID_query + "+ 1";
			}
			else if(increase == STATUS_READ){
				change_catID_query = change_catID_query + "- 1";
			}
			change_catID_query = change_catID_query + " WHERE \"categorieID\" = \"" + catID + "\"";
			ec = sqlite_db.exec (change_catID_query, null, out errmsg);
			if (ec != Sqlite.OK) {
				error("Error: %s\n", errmsg);
			}

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
	
	public void write_tag(string tagID, string label, string color)
	{
		string query = "INSERT OR REPLACE INTO \"main\".\"tags\" (\"tagID\",\"title\",\"exists\",\"color\") VALUES (\"" + tagID + "\", $LABEL, 1, $COLOR)";
		
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		int param_position = stmt.bind_parameter_index ("$LABEL");
		assert (param_position > 0);
		stmt.bind_text (param_position, label);
		param_position = stmt.bind_parameter_index ("$COLOR");
		assert (param_position > 0);
		stmt.bind_text (param_position, color);
		
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


	
	public void write_article(string articleID, string feedID, string title, string author, string url, int unread, int marked, int insert_replace, string html, string tags, string preview = "")
	{
		string output = "";
		string filename = GLib.Environment.get_tmp_dir() + "/" + "articleHtml.XXXXXX";
		int outputfd = GLib.FileUtils.mkstemp(filename);
		try{
			if(preview == "")
				GLib.FileUtils.set_contents(filename, html);
			else
				GLib.FileUtils.set_contents(filename, preview);
		}catch(GLib.FileError e){
			stderr.printf("error writing html to tmp file: %s\n", e.message);
		}
		GLib.FileUtils.close(outputfd);

		string[] spawn_args = {"html2text", "-utf8", "-nobs", filename};
		try{
			GLib.Process.spawn_sync(null, spawn_args, null , GLib.SpawnFlags.SEARCH_PATH, null, out output, null, null);
		}catch(GLib.SpawnError e){
			stdout.printf("error spawning command line: %s\n", e.message);
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
		
		string query = "";
		if(insert_replace == DB_INSERT_OR_IGNORE)
		{
			string command = "INSERT OR IGNORE INTO \"main\".\"articles\" ";
			string fields = "(\"articleID\",\"feedID\",\"title\",\"author\",\"url\",\"html\",\"preview\", \"unread\", \"marked\", \"sortID\") ";
			string values = "VALUES (\"" + articleID + "\", \"" + feedID + "\", $TITLE, \"" + author + "\", \"" + url + "\", $HTML, $PREVIEW, " + unread.to_string() + ", " + marked.to_string() + ", " + (getHighestSortID()+1).to_string() + ")";
			
			query = command + fields + values;
		}
		else if(insert_replace == DB_UPDATE_ROW)
		{
			query = "UPDATE \"main\".\"articles\" SET \"unread\" = " + unread.to_string() + ", \"marked\" = " + marked.to_string() + ", \"tags\" = \"" + tags + "\" WHERE \"articleID\"= \"" + articleID + "\"";
		}
						
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			warning("error writing article\nquery: %s\nhtml: %s\n", query, preview);
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		
		if(insert_replace == DB_INSERT_OR_IGNORE)
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
		}
		
		while (stmt.step () == Sqlite.ROW) {
			
		}
		stmt.reset ();
	}

	
	public article read_article(string articleID)
	{
		article tmp = null;
		string query = "SELECT * FROM \"main\".\"articles\" WHERE \"articleID\" = \"" + articleID + "\"";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		while (stmt.step () == Sqlite.ROW) {
			tmp = new article(
								articleID,
								stmt.column_text(2),
								stmt.column_text(4),
								stmt.column_text(1),
								stmt.column_int(7),
								stmt.column_int(8),
								stmt.column_text(5),
								stmt.column_text(6),
								stmt.column_text(3),
								stmt.column_int(9),
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
		string query = "SELECT count(*) FROM main.articles WHERE articleID >= \"" + articleID + "\" ORDER BY rowid DESC";
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
		string query = "\"feedID\" = ";
		string query2 = "SELECT feed_id FROM \"main\".\"feeds\" WHERE \"category_id\" = " + "\"" + categorieID + "\"";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query2, query2.length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		while (stmt.step () == Sqlite.ROW) {
			query = query + "\"" + stmt.column_text(0) + "\"" + " OR \"feedID\" = ";
		}
		return "(" + query.slice(0, query.length-15) + ")";
	}


	public void markReadAllArticles()
	{
		string query = "UPDATE \"main\".\"articles\" SET \"unread\"=" + STATUS_READ.to_string();
		string errmsg;
		int ec = sqlite_db.exec (query, null, out errmsg);
		if (ec != Sqlite.OK) {
			error("Error: %s\n", errmsg);
		}
	}


	public void unmarkAllArticles()
	{
		string query = "UPDATE \"main\".\"articles\" SET \"marked\"=" + STATUS_UNMARKED.to_string();
		string errmsg;
		int ec = sqlite_db.exec (query, null, out errmsg);
		if (ec != Sqlite.OK) {
			error("Error: %s\n", errmsg);
		}
	}


	public int getNewestArticle()
	{
		int result = 0;
		string query = "SELECT \"articleID\" FROM \"main\".\"articles\" WHERE \"sortID\" = " + getHighestSortID().to_string();
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
	
	public int getHighestSortID()
	{
		int result = 0;
		string query = "SELECT max(\"sortID\") FROM \"main\".\"articles\"";
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
			//print(stmt.column_text(0) + " " + stmt.column_text(1)
			tmpTag = new tag(stmt.column_text(0), stmt.column_text(1), stmt.column_text(3));
			tmp.append(tmpTag);
		}
		
		return tmp;
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

	public GLib.List<article> read_articles(string ID, int selectedType, bool only_unread, bool only_marked, string searchTerm, int limit = 100, int offset = 0)
	{
		GLib.List<article> tmp = new GLib.List<article>();
		string and = "";
		string query = "SELECT * FROM \"main\".\"articles\"";
		
		if( (ID != FEEDID_ALL_FEEDS && selectedType == FEEDLIST_FEED)
		|| (selectedType == FEEDLIST_CATEGORY && ID != CAT_ID_MASTER)
		|| (selectedType == FEEDLIST_TAG)
		|| only_unread
		|| only_marked
		|| searchTerm != "")
			query = query + " WHERE ";
		
		
		if(selectedType == FEEDLIST_FEED)
		{
			if(ID != FEEDID_ALL_FEEDS){
				query = query + "\"feedID\" = " + "\"" + ID + "\"";
				and = " AND ";
			}
		}
		else if(selectedType == FEEDLIST_CATEGORY && ID != CAT_ID_MASTER && ID != CAT_TAGS)
		{
				query = query + getFeedIDofCategorie(ID);
				and = " AND ";
		}
		else if(ID == CAT_TAGS)
		{
			query = query + "\"tags\" IS NOT \"\"";
		}
		else if(selectedType == FEEDLIST_TAG)
		{
			query = query + "instr(\"tags\", \"" + ID + "\") > 0";
		}
		if(only_unread){
			query = query + and + "\"unread\" = " + STATUS_UNREAD.to_string();
			and = " AND ";
		}
		if(only_marked){
			query = query + and + "\"marked\" = " + STATUS_MARKED.to_string();
			and = " AND ";
		}
		if(searchTerm != ""){
			query = query + and + "instr(UPPER(\"title\"), UPPER(\"" + searchTerm + "\")) > 0";
		}
		query = query + " ORDER BY sortID DESC LIMIT " + limit.to_string() + " OFFSET " + offset.to_string();
		
		stdout.printf("%s\n", query);
		article tmpArticle;
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		while (stmt.step () == Sqlite.ROW) {
			tmpArticle = new article(
								stmt.column_text(0),
								stmt.column_text(2),
								stmt.column_text(4),
								stmt.column_text(1),
								stmt.column_int(7),
								stmt.column_int(8),
								stmt.column_text(5),
								stmt.column_text(6),
								stmt.column_text(3),
								stmt.column_int(9),
								stmt.column_text(10)
							);
			tmp.append(tmpArticle);
		}
		
		return tmp;
	}

	 
}
