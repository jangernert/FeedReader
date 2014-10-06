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
		int rc = Sqlite.Database.open_v2 (db_path + "feedreader-01.db", out sqlite_db);
		if (rc != Sqlite.OK) {
			error("Can't open database: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		sqlite_db.busy_timeout (1000);
	}

	public void init()
	{
			string feeds =					"""CREATE  TABLE  IF NOT EXISTS "main"."feeds" 
											(
												"feed_id" INTEGER PRIMARY KEY  NOT NULL UNIQUE ,
												"name" VARCHAR NOT NULL ,
												"url" VARCHAR NOT NULL  UNIQUE ,
												"has_icon" INTEGER NOT NULL ,
												"unread" INTEGER NOT NULL,
												"category_id" INTEGER,
												"subscribed" INTEGER DEFAULT 1
											)""";

			string headlines =				"""CREATE  TABLE  IF NOT EXISTS "main"."headlines" 
											(
												"articleID" INTEGER PRIMARY KEY  NOT NULL  UNIQUE ,
												"title" VARCHAR NOT NULL , 
												"url" VARCHAR NOT NULL ,
												"feedID" INTEGER NOT NULL , 
												"unread" INTEGER NOT NULL ,
												"marked" INTEGER NOT NULL
											)""";
		
			string articles =				"""CREATE  TABLE  IF NOT EXISTS "main"."articles"
											(
												"articleID" INTEGER PRIMARY KEY  NOT NULL  UNIQUE ,
												"feedID" INTEGER NOT NULL ,
												"title" VARCHAR NOT NULL ,
												"author" VARCHAR NOT NULL ,
												"url" VARCHAR NOT NULL ,
												"html" VARCHAR,
												"preview" VARCHAR
											)""";

			string categories =				"""CREATE  TABLE  IF NOT EXISTS "main"."categories" 
											(
												"categorieID" INTEGER PRIMARY KEY  NOT NULL  UNIQUE ,
												"title" VARCHAR NOT NULL ,
												"unread" INTEGER,
												"orderID" INTEGER,
												"exists" INTEGER,
												"Parent" INTEGER,
												"Level" INTEGER
												)""";
	
			string errmsg;
			int ec = sqlite_db.exec (feeds, null, out errmsg);
			if (ec != Sqlite.OK) {
				error("Error: %s\n", errmsg);
			}
			ec = sqlite_db.exec (headlines, null, out errmsg);
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



	public void change_unread(int feedID, bool increase)
	{
		string change_feed_query = "UPDATE \"main\".\"feeds\" SET \"unread\" = \"unread\" ";
		if(increase){
			change_feed_query = change_feed_query + "+ 1";
		}else{
			change_feed_query = change_feed_query + "- 1";
		} 
		change_feed_query = change_feed_query + " WHERE \"feed_id\" = " + feedID.to_string();
		string errmsg;
		int ec = sqlite_db.exec (change_feed_query, null, out errmsg);
		if (ec != Sqlite.OK) {
			error("Error: %s\n", errmsg);
		}
			

			
		string get_feed_id_query = "SELECT \"category_id\" FROM \"main\".\"feeds\" WHERE \"feed_id\" = \"" + feedID.to_string() + "\"";
		Sqlite.Statement stmt;
		ec = sqlite_db.prepare_v2 (get_feed_id_query, get_feed_id_query.length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		int catID = -99;
		int cols = stmt.column_count ();
		while (stmt.step () == Sqlite.ROW) {
			for (int i = 0; i < cols; i++) {
				catID = stmt.column_int(i);
			}
		}
		stmt.reset ();


		string change_catID_query = "UPDATE \"main\".\"categories\" SET \"unread\" = \"unread\" ";
		if(increase){
			change_catID_query = change_catID_query + "+ 1";
		}else{
			change_catID_query = change_catID_query + "- 1";
		}
		change_catID_query = change_catID_query + " WHERE \"categorieID\" = " + catID.to_string();
		ec = sqlite_db.exec (change_catID_query, null, out errmsg);
		if (ec != Sqlite.OK) {
			error("Error: %s\n", errmsg);
		}

		updateBadge();
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

	public void write_feed(int feed_id, string feed_name, string feed_url, bool has_icon, int unread_count, int cat_id)
	{
		int int_has_icon = 0;
		if(has_icon) int_has_icon = 1;
		
		string query = "INSERT OR REPLACE INTO \"main\".\"feeds\" (\"feed_id\",\"name\",\"url\",\"has_icon\",\"unread\", \"category_id\", \"subscribed\") 
						VALUES (\"" + feed_id.to_string() + "\", $FEEDNAME, $FEEDURL, \"" + int_has_icon.to_string() + "\", \"" + unread_count.to_string() + "\", \"" + cat_id.to_string() + "\", 1)";
		
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


	public void write_categorie(int categorieID, string categorie_name, int unread_count, int orderID, int parent, int level)
	{
		string query = "INSERT OR REPLACE INTO \"main\".\"categories\" (\"categorieID\",\"title\",\"unread\",\"orderID\", \"exists\", \"Parent\", \"Level\") 
						VALUES (\"" + categorieID.to_string() + "\", $FEEDNAME, \"" + unread_count.to_string() + "\", \"" + orderID.to_string() + "\", 1, \"" + parent.to_string() + "\", \"" + level.to_string() + "\")";
		
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


	public void write_headline(int articleID, string title, string url, int feed_ID, bool unread, bool marked)
	{		
		int int_unread = 0;
		int int_marked = 0;
		if(unread) int_unread = 1;
		if(marked) int_marked = 1;
		string query = "INSERT INTO \"main\".\"headlines\" (\"articleID\",\"title\",\"url\",\"feedID\",\"unread\", \"marked\") 
						VALUES (\"" + articleID.to_string() + "\", $TITLE, \"" + url + "\", \"" + feed_ID.to_string() + "\", \"" + int_unread.to_string() + "\", \"" + int_marked.to_string() + "\")";
		/*string errmsg;
		int ec = sqlite_db.exec (query, null, out errmsg);
		if (ec != Sqlite.OK) {
			warning("error writing headline\nquery: %s\n", query);
			error("Error: %s\n", errmsg);
		}*/
		
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			warning("error writing article\nquery: %s\ntitle: %s\n", query, title);
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		int param_position = stmt.bind_parameter_index ("$TITLE");
		assert (param_position > 0);
		stmt.bind_text (param_position, title);
		while (stmt.step () == Sqlite.ROW) {
			
		}
		stmt.reset ();
	}


	public void read_article(int articleID, out int feedID, out string title, out string author, out string url, out string html, out string preview)
	{
		feedID = 0;
		title = author = url = html = preview = "";
		string query = "SELECT * FROM \"main\".\"articles\" WHERE \"articleID\" = \"" + articleID.to_string() + "\"";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		while (stmt.step () == Sqlite.ROW) {
			feedID = stmt.column_int(1);
			title = stmt.column_text(2);
			author = stmt.column_text(3);
			url = stmt.column_text(4);
			html = stmt.column_text(5);
			preview = stmt.column_text(6);
		}
		stmt.reset ();
	}

	public void write_article(int articleID, int feedID, string title, string author, string url, string html)
	{
		string output = "";
		string filename = GLib.Environment.get_tmp_dir() + "/" + "articleHtml.XXXXXX";
		int outputfd = GLib.FileUtils.mkstemp(filename);
		try{
			GLib.FileUtils.set_contents(filename, html);
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
		
		
		string query = "INSERT OR REPLACE INTO \"main\".\"articles\" (\"articleID\",\"feedID\",\"title\",\"author\",\"url\",\"html\",\"preview\") 
						VALUES (\"" + articleID.to_string() + "\", \"" + feedID.to_string() + "\", $TITLE, \"" + author + "\", \"" + url + "\", $HTML, $PREVIEW)";
						
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			warning("error writing article\nquery: %s\nhtml: %s\n", query, output);
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		int param_position = stmt.bind_parameter_index ("$TITLE");
		assert (param_position > 0);
		stmt.bind_text (param_position, title);
		param_position = stmt.bind_parameter_index ("$HTML");
		assert (param_position > 0);
		stmt.bind_text (param_position, html);
		param_position = stmt.bind_parameter_index ("$PREVIEW");
		assert (param_position > 0);
		stmt.bind_text (param_position, output);
		while (stmt.step () == Sqlite.ROW) {
			
		}
		stmt.reset ();
	}


	public void debug_write_allArticles(ttrss_interface ttrss)
	{
		string title, author, url, html;
		
		string query = """SELECT "articleID","feedID" FROM "main"."headlines" """;
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		while (stmt.step () == Sqlite.ROW) {
			ttrss.getArticle(stmt.column_int(0), out title, out author, out url, out html);
			write_article(stmt.column_int(0), stmt.column_int(1), title, author, url, html);
		}
	}


	public void update_headline(int articleID, string field, bool field_value)
	{
		int int_field_value = 0;
		if(field_value) int_field_value = 1;
		
		string query = "UPDATE \"main\".\"headlines\" SET \"" + field + "\" = \"" + int_field_value.to_string() + "\" WHERE \"articleID\"= \"" + articleID.to_string() + "\"";
		string errmsg;
		int ec = sqlite_db.exec (query, null, out errmsg);
		if (ec != Sqlite.OK) {
			error("Error: %s\n", errmsg);
		}
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
		string query = "SELECT \"feed_id\" FROM \"main\".\"feeds\" WHERE \"subscribed\" = 0";
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		while (stmt.step () == Sqlite.ROW) {
			int delete_feed = stmt.column_int(0);
			delete_headlines(delete_feed);
			string query2 = "DELETE FROM \"main\".\"feeds\" WHERE \"feed_id\" = :delte_feed";
			string errmsg;
			ec = sqlite_db.exec (query2, null, out errmsg);
			if (ec != Sqlite.OK) {
				error("Error: %s\n", errmsg);
			}
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

	public void delete_headlines(int feedID)
	{
		string query = "DELETE FROM \"main\".\"headlines\" WHERE \"feedID\" = \"" + feedID.to_string() + "\"";
		string errmsg;
		int ec = sqlite_db.exec (query, null, out errmsg);
		if (ec != Sqlite.OK) {
			error("Error: %s\n", errmsg);
		}
		
		string query2 = "DELETE FROM \"main\".\"articles\" WHERE \"feedID\" = \"" + feedID.to_string() + "\"";
		ec = sqlite_db.exec (query2, null, out errmsg);
		if (ec != Sqlite.OK) {
			error("Error: %s\n", errmsg);
		}
	}


	public int getRowNumberHeadline(int articleID)
	{
		int result = 0;
		string query = "SELECT count(*) FROM main.headlines WHERE articleID >= \"" + articleID.to_string() + "\" ORDER BY articleID DESC";
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


	private string getFeedIDofCategorie(int categorieID)
	{
		string query = "\"feedID\" = ";
		string query2 = "SELECT feed_id FROM \"main\".\"feeds\" WHERE \"category_id\" = " + categorieID.to_string();
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query2, query2.length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		while (stmt.step () == Sqlite.ROW) {
			query = query + stmt.column_int(0).to_string() + " OR \"feedID\" = ";
		}
		return "(" + query.slice(0, query.length-15) + ")";
	}


	public void markReadAllArticles()
	{
		string query = "UPDATE \"main\".\"headlines\" SET \"unread\"=0";
		string errmsg;
		int ec = sqlite_db.exec (query, null, out errmsg);
		if (ec != Sqlite.OK) {
			error("Error: %s\n", errmsg);
		}
	}


	public void unmarkAllArticles()
	{
		string query = "UPDATE \"main\".\"headlines\" SET \"marked\"=0";
		string errmsg;
		int ec = sqlite_db.exec (query, null, out errmsg);
		if (ec != Sqlite.OK) {
			error("Error: %s\n", errmsg);
		}
	}


	public int getNewestArticle()
	{
		int result = 0;
		string query = "SELECT max(\"articleID\") FROM \"main\".\"headlines\"";
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
			tmpfeed = new feed(stmt.column_int(0), stmt.column_text(1), stmt.column_text(2), stmt.column_int(3), stmt.column_int(4), stmt.column_int(5));
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
			tmpcategory = new category(stmt.column_int(0), stmt.column_text(1), stmt.column_int(2), stmt.column_int(3), stmt.column_int(5), stmt.column_int(6));
			tmp.append(tmpcategory);
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
			tmpcategory = new category(stmt.column_int(0), stmt.column_text(1), stmt.column_int(2), stmt.column_int(3), stmt.column_int(5), stmt.column_int(6));
			tmp.append(tmpcategory);
		}

		return tmp;
	}

	public GLib.List<headline> read_headlines(int ID, bool ID_is_feedID, bool only_unread, bool only_marked, string searchTerm, int limit = 100, int offset = 0)
	{
		GLib.List<headline> tmp = new GLib.List<headline>();
		string and = "";
		string query = "SELECT * FROM \"main\".\"headlines\"";
		if(ID != -3 || !ID_is_feedID || only_unread || only_marked || searchTerm != "") query = query + " WHERE ";
		if(ID_is_feedID)
		{
			if(ID != -3){
				query = query + "\"feedID\" = " + ID.to_string();
				and = " AND ";
			}
		}
		else
		{
				query = query + getFeedIDofCategorie(ID);
				and = " AND ";
		}
		if(only_unread){
			query = query + and + "\"unread\" = 1";
			and = " AND ";
		}
		if(only_marked){
			query = query + and + "\"marked\" = 1";
			and = " AND ";
		}
		if(searchTerm != ""){
			query = query + and + "instr(UPPER(\"title\"), UPPER(\"" + searchTerm + "\")) > 0";
		}
		query = query + " ORDER BY articleID DESC LIMIT " + limit.to_string() + " OFFSET " + offset.to_string();
		
		//stdout.printf("%s\n", query);
		headline tmpHeadline;
		Sqlite.Statement stmt;
		int ec = sqlite_db.prepare_v2 (query, query.length, out stmt);
		if (ec != Sqlite.OK) {
			error("Error: %d: %s\n", sqlite_db.errcode (), sqlite_db.errmsg ());
		}
		while (stmt.step () == Sqlite.ROW) {
			tmpHeadline = new headline(stmt.column_int(0), stmt.column_text(1), stmt.column_text(2), stmt.column_int(3), stmt.column_int(4), stmt.column_int(5));
			tmp.append(tmpHeadline);
		}
		
		return tmp;
	}

	 
}
