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

	private SQLHeavy.Database db;
	private SQLHeavy.Transaction transaction;
	public signal void updateBadge();

	public dbManager () {
		try{
			string db_path = GLib.Environment.get_home_dir() + "/.local/share/feedreader/data/";
			db = new SQLHeavy.Database (db_path + "feedreader-01.db", SQLHeavy.FileMode.READ | SQLHeavy.FileMode.WRITE | SQLHeavy.FileMode.CREATE);
			db.synchronous = SQLHeavy.SynchronousMode.NORMAL;
		}
		catch(SQLHeavy.Error e){ error(e.message); }
	}

	public void init()
	{
		try
		{
			var table_feed = db.prepare (
											"""CREATE  TABLE  IF NOT EXISTS "main"."feeds" 
											(
												"feed_id" INTEGER PRIMARY KEY  NOT NULL UNIQUE ,
												"name" VARCHAR NOT NULL ,
												"url" VARCHAR NOT NULL  UNIQUE ,
												"has_icon" INTEGER NOT NULL ,
												"unread" INTEGER NOT NULL,
												"category_id" INTEGER,
												"subscribed" INTEGER DEFAULT 1
											)"""
			                             );

			var table_headline = db.prepare (
												"""CREATE  TABLE  IF NOT EXISTS "main"."headlines" 
												(
													"articleID" INTEGER PRIMARY KEY  NOT NULL  UNIQUE ,
													"title" VARCHAR NOT NULL , 
													"url" VARCHAR NOT NULL ,
													"feedID" INTEGER NOT NULL , 
													"unread" INTEGER NOT NULL ,
													"marked" INTEGER NOT NULL
												)"""
		                            		);
		
			var table_article = db.prepare(
			                               """CREATE  TABLE  IF NOT EXISTS "main"."articles"
											(
												"articleID" INTEGER PRIMARY KEY  NOT NULL  UNIQUE ,
												"feedID" INTEGER NOT NULL ,
												"title" VARCHAR NOT NULL ,
												"author" VARCHAR NOT NULL ,
												"url" VARCHAR NOT NULL ,
												"html" VARCHAR,
												"preview" VARCHAR
											)"""
										  );

			var table_categories = db.prepare(
			                              		"""CREATE  TABLE  IF NOT EXISTS "main"."categories" 
												(
													"categorieID" INTEGER PRIMARY KEY  NOT NULL  UNIQUE ,
													"title" VARCHAR NOT NULL ,
													"unread" INTEGER,
													"orderID" INTEGER,
													"exists" INTEGER,
													"Parent" INTEGER,
													"Level" INTEGER,
													"expanded" INTEGER DEFAULT 0
												)"""
			                                  );

			var table_ui = db.prepare (
			                           """CREATE  TABLE  IF NOT EXISTS "main"."properties" 
										(
											"propertie" VARCHAR PRIMARY KEY  NOT NULL ,
											"value" INTEGER NOT NULL
										)"""
			                           );

			var table_login = db.prepare (
			                         		"""CREATE  TABLE  IF NOT EXISTS "main"."login" 
											(
												"data" VARCHAR PRIMARY KEY  NOT NULL,
												"value" VARCHAR NOT NULL
											)"""
			                              );

			table_login.execute();
			table_feed.execute();
			table_headline.execute();
			table_article.execute();
			table_categories.execute();
			table_ui.execute();
			
		}
		catch(SQLHeavy.Error e)
		{
			 error(e.message); 
		}
	}


	public bool isTableEmpty(string table)
	{
		int count = -1;
		try{
			string query = "SELECT count(*) FROM \"main\".\"" + table + "\"";
			var isTableEmpty = db.prepare(query);
			var result = isTableEmpty.execute();
			count = result.fetch_int(0);
		}
		catch(SQLHeavy.Error e){ error(e.message); }

		if(count > 0)
			return false;
		else
			return true;
	}


	public string read_login(string type)
	{
		try{
			var read_login = db.prepare("SELECT value FROM \"main\".\"login\" WHERE data = :type");
			var result = read_login.execute(":type", typeof(string), type);
			if(result.fetch_string(0) != null)
				return result.fetch_string(0);
			else
				return "";
		}
		catch(SQLHeavy.Error e){
			error(e.message); 
		}
		
	}


	public void write_login(string type, string login_value)
	{
		try
		{
			transaction = db.begin_transaction();
			var insert_login = transaction.prepare(
			                                      "INSERT OR REPLACE INTO \"main\".\"login\" (\"data\", \"value\") VALUES (:type, :login_value)"
			                                      );

			insert_login.execute(":type", typeof(string), type,
			                     ":login_value", typeof(string), login_value);
			transaction.commit();
		}
		catch(SQLHeavy.Error e){ error(e.message); }
	}


	public void change_unread(int feedID, bool increase)
	{
		try
		{
			transaction = db.begin_transaction();
			string change_feed_query = "UPDATE \"main\".\"feeds\" SET \"unread\" = \"unread\" ";
			if(increase){
				change_feed_query = change_feed_query + "+ 1";
			}else{
				change_feed_query = change_feed_query + "- 1";
			} 
			change_feed_query = change_feed_query + " WHERE \"feed_id\" = " + feedID.to_string();
			transaction.execute(change_feed_query);
			transaction.commit();
			

			
			var catID_query = db.prepare("""SELECT "category_id" FROM "main"."feeds" WHERE "feed_id" = :feedID""");
			var catID_result = catID_query.execute(":feedID", typeof(int), feedID);
			int catID = catID_result.fetch_int(0);


			transaction = db.begin_transaction();
			string change_catID_query = "UPDATE \"main\".\"categories\" SET \"unread\" = \"unread\" ";
			if(increase){
				change_catID_query = change_catID_query + "+ 1";
			}else{
				change_catID_query = change_catID_query + "- 1";
			}
			change_catID_query = change_catID_query + " WHERE \"categorieID\" = " + catID.to_string();
			transaction.execute(change_catID_query);
			transaction.commit();
			

			
			transaction = db.begin_transaction();
			string change_unread_query = "UPDATE \"main\".\"properties\" SET \"value\" = \"value\" ";
			if(increase){
				change_unread_query = change_unread_query + "+ 1";
			}else{
				change_unread_query = change_unread_query + "- 1";
			}
			change_unread_query = change_unread_query + " WHERE \"propertie\" = \"unread_articles\"";
			transaction.execute(change_unread_query);
			transaction.commit();
			updateBadge();
		}
		catch(SQLHeavy.Error e){ error(e.message); }
	}


	public void write_propertie(string propertie_name, int propertie_value)
	{
		try
		{
			transaction = db.begin_transaction();
			var insert_propertie = transaction.prepare(
			                                      "INSERT OR REPLACE INTO \"main\".\"properties\" (\"propertie\", \"value\") VALUES (:propertie_name, :propertie_value)"
			                                      );

			insert_propertie.execute(":propertie_name", typeof(string), propertie_name,
			                         ":propertie_value", typeof(int), propertie_value);
			transaction.commit();
		}
		catch(SQLHeavy.Error e){ error(e.message); }
	}


	public int read_propertie(string propertie_name)
	{
		try{
			var read_propertie = db.prepare("SELECT value FROM \"main\".\"properties\" WHERE propertie = :propertie_name");
			var result = read_propertie.execute(":propertie_name", typeof(string), propertie_name);
			return result.fetch_int(0);
		}
		catch(SQLHeavy.Error e){ error(e.message); }
	}

	public void write_feed(int feed_id, string feed_name, string feed_url, bool has_icon, int unread_count, int cat_id)
	{
		try{
			int int_has_icon = 0;
			if(has_icon) int_has_icon = 1;
			
			transaction = db.begin_transaction();
			var insert_feed = transaction.prepare("""INSERT OR REPLACE INTO "main"."feeds" ("feed_id","name","url","has_icon","unread", "category_id", "subscribed") 
													VALUES (:feed_id, :name, :url, :has_icon, :unread, :cat_id, 1)""");
			insert_feed.set_int(":feed_id", feed_id);
			insert_feed.set_string(":name", feed_name);
			insert_feed.set_string(":url", feed_url);
			insert_feed.set_int (":has_icon", int_has_icon);
			insert_feed.set_int(":unread", unread_count);
			insert_feed.set_int(":cat_id", cat_id);
			insert_feed.execute();
			transaction.commit();

		}catch(SQLHeavy.Error e){
			 error(e.message); 
		}
	}


	public void write_categorie(int categorieID, string categorie_name, int unread_count, int orderID, int parent, int level)
	{
		try{
			transaction = db.begin_transaction();
			var insert_categorie = transaction.prepare("""INSERT OR REPLACE INTO "main"."categories" ("categorieID","title","unread","orderID", "exists", "Parent", "Level", "expanded") 
												VALUES (:categorieID, :categorie_name, :unread_count, :orderID, 1, :parent, :level, (SELECT "expanded" FROM "main"."categories" WHERE "categorieID" = :categorieID))""");
			insert_categorie.set_int(":categorieID", categorieID);
			insert_categorie.set_string(":categorie_name", categorie_name);
			insert_categorie.set_int (":unread_count", unread_count);
			insert_categorie.set_int(":orderID", orderID);
			insert_categorie.set_int(":parent", parent);
			insert_categorie.set_int(":level", level);
			insert_categorie.execute();
			transaction.commit();

		}catch(SQLHeavy.Error e){
			 error(e.message); 
		}
	}


	public void write_headline(int articleID, string title, string url, int feed_ID, bool unread, bool marked)
	{
		try{
			int int_unread = 0;
			int int_marked = 0;
			if(unread) int_unread = 1;
			if(marked) int_marked = 1;

			transaction = db.begin_transaction();
			var insert_headline = transaction.prepare("""INSERT INTO "main"."headlines" ("articleID","title","url","feedID","unread", "marked") 
														VALUES (:articleID, :title, :url, :feedID, :unread, :marked)""");
		
			insert_headline.execute(":articleID", typeof(int), articleID,
			                       ":title", typeof(string), title,
			                       ":url", typeof(string), url,
			                       ":feedID", typeof(int), feed_ID,
			                       ":unread", typeof(int), int_unread,
			                       ":marked", typeof(int), int_marked);
			transaction.commit();
		}
		catch(SQLHeavy.Error e){ error(e.message); }
	}


	public void read_article(int articleID, out int feedID, out string title, out string author, out string url, out string html, out string preview)
	{
		try{
			var read_article = db.prepare("""SELECT * FROM "main"."articles" WHERE "articleID" = :articleID""");
			var result = read_article.execute(":articleID", typeof(int), articleID);

			feedID = result.fetch_int(1);
			title = result.fetch_string(2);
			author = result.fetch_string(3);
			url = result.fetch_string(4);
			html = result.fetch_string(5);
			preview = result.fetch_string(6);
		}
		catch(SQLHeavy.Error e){
			html = url = author = title = "error";
			feedID = -1;
			error(e.message); 
		}
	}

	public void write_article(int articleID, int feedID, string title, string author, string url, string html)
	{
		try{
		
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
            //stdout.printf("output: %s\n", output);
            
            
            
            
			
		
			transaction = db.begin_transaction();
			var insert_article = transaction.prepare("""INSERT OR REPLACE INTO "main"."articles" ("articleID","feedID","title","author","url","html","preview") 
														VALUES (:articleID, :feedID, :title, :author, :url, :html, :preview)""");
		
			insert_article.execute(":articleID", typeof(int), articleID,
			                       ":feedID", typeof(int), feedID,
			                       ":title", typeof(string), title,
			                       ":author", typeof(string), author,
			                       ":url", typeof(string), url,
			                       ":html", typeof(string), html,
			                       ":preview", typeof(string), output);
			transaction.commit();
		}
		catch(SQLHeavy.Error e){error(e.message);}
	}


	public void debug_write_allArticles(ttrss_interface ttrss)
	{
		try{
			string title, author, url, html;
			
			var headlines = db.execute("""SELECT "articleID","feedID" FROM "main"."headlines" """);
			for (int row = 1 ; !headlines.finished ; row++, headlines.next () )
			{
				ttrss.getArticle(headlines.fetch_int(0), out title, out author, out url, out html);
				write_article(headlines.fetch_int(0), headlines.fetch_int(1), title, author, url, html);
			}
		}
		catch(SQLHeavy.Error e){ error(e.message); }
	}


	public void update_headline(int articleID, string field, bool field_value)
	{
		int int_field_value = 0;
		if(field_value) int_field_value = 1;

		try{
			transaction = db.begin_transaction();
			var update_query = transaction.prepare("UPDATE \"main\".\"headlines\" SET \"" + field + "\"=:value WHERE \"articleID\"=:articleID");
			update_query.execute(":value", typeof(int), int_field_value,
			                     ":articleID", typeof(int), articleID);
			transaction.commit();
		}catch(SQLHeavy.Error e){ error(e.message); }
	}


	public SQLHeavy.QueryResult read_feeds()
	{
		SQLHeavy.QueryResult result = null;
		try{result = db.execute("SELECT * FROM \"main\".\"feeds\"");}
		catch(SQLHeavy.Error e){ error(e.message); }
		return result;
	}

	public SQLHeavy.QueryResult read_categories()
	{
		SQLHeavy.QueryResult result = null;
		try{
			result = db.execute("SELECT * FROM \"main\".\"categories\" WHERE categorieID >= 0 ORDER BY orderID DESC");
		}
		catch(SQLHeavy.Error e){ error(e.message); }
		return result;
	}

	public SQLHeavy.QueryResult read_categories_level(int level)
	{
		SQLHeavy.QueryResult result = null;
		try{
			var query = db.prepare("SELECT * FROM \"main\".\"categories\" WHERE categorieID >= 0 AND \"level\" = :level ORDER BY orderID DESC");
			result = query.execute(":level", typeof(int), level);
		}
		catch(SQLHeavy.Error e){ error(e.message); }
		return result;
	}

	public int getMaxCatLevel()
	{
		int maxCatLevel = 0;
		try{
			var result = db.execute("SELECT max(Level) FROM \"main\".\"categories\" WHERE categorieID >= 0");
			maxCatLevel = result.fetch_int(0);
		}
		catch(SQLHeavy.Error e){ error(e.message); }
		return maxCatLevel;
	}


	public void reset_subscribed_flag()
	{
		try{
			transaction = db.begin_transaction();
			transaction.execute("UPDATE \"main\".\"feeds\" SET \"subscribed\" = 0");
			transaction.commit();
		}catch(SQLHeavy.Error e){ error(e.message); }
	}

	public void reset_exists_flag()
	{
		try{
			transaction = db.begin_transaction();
			transaction.execute("UPDATE \"main\".\"categories\" SET \"exists\" = 0");
			transaction.commit();
		}catch(SQLHeavy.Error e){ error(e.message); }
	}



	public void delete_unsubscribed_feeds()
	{
		try{
			var to_delete = db.execute("SELECT \"feed_id\" FROM \"main\".\"feeds\" WHERE \"subscribed\" = 0");
			for (int row = 1 ; !to_delete.finished ; row++, to_delete.next () )
			{
				int delete_feed = to_delete.fetch_int(0);
				stdout.printf("Delete: %i\n", delete_feed);
				delete_headlines(delete_feed);
				transaction = db.begin_transaction();
				var delete_query = transaction.prepare("DELETE FROM \"main\".\"feeds\" WHERE \"feed_id\" = :delte_feed");
				delete_query.execute(":delte_feed", typeof(int), delete_feed);
				transaction.commit();
			}
		}catch(SQLHeavy.Error e){ error(e.message); }
	}


	public void delete_nonexisting_categories()
	{
		try{
				transaction = db.begin_transaction();
				transaction.execute("DELETE FROM \"main\".\"categories\" WHERE \"exists\" = 0");
				transaction.commit();
		}catch(SQLHeavy.Error e){ error(e.message); }
	}

	public void mark_categorie_expanded(int catID, int expanded)
	{
		try{
			transaction = db.begin_transaction();
			var query = transaction.prepare("UPDATE \"main\".\"categories\" SET \"expanded\" = :expanded WHERE \"categorieID\" = :catID");
			query.set_int(":expanded", expanded);
			query.set_int(":catID", catID);
			query.execute();
			transaction.commit();
		}catch(SQLHeavy.Error e){ error(e.message); }
	}

	public void delete_headlines(int feedID)
	{
		try{
			transaction = db.begin_transaction();
			var delete_headlines_query = transaction.prepare("DELETE FROM \"main\".\"headlines\" WHERE \"feedID\" = :delte_feed");
			delete_headlines_query.execute(":delte_feed", typeof(int), feedID);
			transaction.commit();
			
			transaction = db.begin_transaction();
			var delete_articles_query = transaction.prepare("DELETE FROM \"main\".\"articles\" WHERE \"feedID\" = :delte_feed");
			delete_articles_query.execute(":delte_feed", typeof(int), feedID);
			transaction.commit();
		}catch(SQLHeavy.Error e){ error(e.message); }
	}

	
	public SQLHeavy.QueryResult read_headlines(int ID, bool ID_is_feedID, bool only_unread, bool only_marked, int limit = 100, int offset = 0)
	{
		SQLHeavy.QueryResult articles = null;
		try{
			string query = "SELECT * FROM \"main\".\"headlines\"";
			if(ID != 0 || only_unread || only_marked) query = query + " WHERE ";
			if(ID_is_feedID)
			{
				if(ID != 0) query = query + "\"feedID\" = " + ID.to_string();
			}
			else
			{
				if(ID != 0) query = query + getFeedIDofCategorie(ID);
			}
			if((ID != 0 && only_unread) || (ID != 0 && only_marked) || (only_unread && only_marked && ID != 0)) query = query + " AND ";
			if(only_unread) query = query + "\"unread\" = 1";
			if(only_unread && only_marked) query = query + " AND ";
			if(only_marked) query = query + "\"marked\" = 1";
			query = query + " ORDER BY articleID DESC LIMIT " + limit.to_string() + " OFFSET " + offset.to_string();

			//stdout.printf("%s\n", query);

			articles = db.execute (query);
		}
		catch(SQLHeavy.Error e){ error(e.message); }
		
		return articles;
	}


	public int getRowNumberHeadline(int articleID)
	{
		try{
			var query = db.prepare("SELECT count(*) FROM main.headlines WHERE articleID >= :articleID ORDER BY articleID DESC");
			query.set_int(":articleID", articleID);
			var result = query.execute();
			return result.fetch_int(0);
		}catch(SQLHeavy.Error e){ error(e.message); }
	}


	public void updateCategorie(int catID, int unread)
	{
		try{
			transaction = db.begin_transaction();
			var query = transaction.prepare("UPDATE main.categories SET unread = :unread WHERE categorieID = :catID");
			query.execute(":unread", typeof(int), unread,
			              ":catID", typeof(int), catID);
			transaction.commit();
		}catch(SQLHeavy.Error e){ error(e.message); }
	}


	private string getFeedIDofCategorie(int categorieID)
	{
		string query = "\"feedID\" = ";
		try{
			var feedIDs = db.execute ("SELECT feed_id FROM \"main\".\"feeds\" WHERE \"category_id\" = " + categorieID.to_string());
			
			while(!feedIDs.finished)
			{
				query = query + feedIDs.fetch_int(0).to_string() + " OR \"feedID\" = ";
				feedIDs.next();
			}
		}
		catch(SQLHeavy.Error e){ error(e.message); }
		return "(" + query.slice(0, query.length-15) + ")";
	}


	public void markReadAllArticles()
	{
		try{
			transaction = db.begin_transaction();
			transaction.execute ("UPDATE \"main\".\"headlines\" SET \"unread\"=0");
			transaction.commit();
		}
		catch(SQLHeavy.Error e){ error(e.message); }
	}


	public void unmarkAllArticles()
	{
		try{
			transaction = db.begin_transaction();
			transaction.execute ("UPDATE \"main\".\"headlines\" SET \"marked\"=0");
			transaction.commit();
		}
		catch(SQLHeavy.Error e){ error(e.message); }
	}


	public int getNewestArticle()
	{
		try{var result = db.execute ("SELECT max(\"articleID\") FROM \"main\".\"headlines\"");
		return result.fetch_int(0);
		}
		catch(SQLHeavy.Error e){ error(e.message); }
	}





	 
}
