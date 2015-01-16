/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * ttrss_interface.vala
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

public class ttrss_interface : GLib.Object {

	public string m_ttrss_url { get; private set; }

	private string m_ttrss_sessionid;
	private uint64 m_ttrss_apilevel;
	private Json.Parser m_parser;

	
	public ttrss_interface ()
	{
		m_parser = new Json.Parser ();
	}

	
	public int login()
	{
		string username = ttrss_utils.getUser();
		string passwd = ttrss_utils.getPasswd();
		m_ttrss_url = ttrss_utils.getURL();
		
		if(m_ttrss_url == "" && username == "" && passwd == ""){
			m_ttrss_url = "example-host/tt-rss";
			return LOGIN_ALL_EMPTY;
		}
		if(m_ttrss_url == ""){
			return LOGIN_MISSING_URL;
		}
		if(username == ""){
			return LOGIN_MISSING_USER;
		}
		if(passwd == ""){
			return LOGIN_MISSING_PASSWD;
		}

		
		var message = new ttrss_message(m_ttrss_url);
		message.add_string("op", "login");
		message.add_string("user", username);
		message.add_string("password", passwd);
		int error = message.send();
		
		if(error == NO_ERROR)
		{
			var response = message.get_response_object();
			m_ttrss_sessionid = response.get_string_member("session_id");
			m_ttrss_apilevel = response.get_int_member("api_level");
		}
		
		stdout.printf ("Session ID: %s\n", m_ttrss_sessionid);
		stdout.printf ("API Level: %lld\n", m_ttrss_apilevel);
		
		return LOGIN_SUCCESS;
	}


	private bool isloggedin()
	{
		var message = new ttrss_message(m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "isLoggedIn");
		int error = message.send();
		
		if(error == NO_ERROR)
		{
			var response = message.get_response_object();
			return response.get_boolean_member("status");
		}

		return false;
	}

	 
	public async int getUnreadCount()
	{
		SourceFunc callback = getUnreadCount.callback;
		int unread = 0;
		ThreadFunc<void*> run = () => {
		
			if(isloggedin()) {
				var message = new ttrss_message(m_ttrss_url);
				message.add_string("sid", m_ttrss_sessionid);
				message.add_string("op", "getUnread");
				int error = message.send();
		
				if(error == NO_ERROR)
				{
					var response = message.get_response_object();
					unread = int.parse(response.get_string_member("unread"));
				}
				stdout.printf("There are %i unread Feeds\n", unread);
				
				Idle.add((owned) callback);
			}
			return null;
		};
		new GLib.Thread<void*>("getUnreadCount", run);
		
		yield;
		
		return unread;
	}


	public async void getFeeds()
	{
		SourceFunc callback = getFeeds.callback;
		
		ThreadFunc<void*> run = () => {
			if(isloggedin())
			{
				dataBase.reset_subscribed_flag();
				var categories = dataBase.read_categories();

				foreach(var item in categories)
				{
					var message = new ttrss_message(m_ttrss_url);
					message.add_string("sid", m_ttrss_sessionid);
					message.add_string("op", "getFeeds");
					message.add_int("cat_id", int.parse(item.m_categorieID));
					int error = message.send();
		
					if(error == NO_ERROR)
					{
						var response = message.get_response_array();
						var feed_count = response.get_length();
						string icon_url = m_ttrss_url.replace("api/", getIconDir());
						
						for(uint i = 0; i < feed_count; i++)
						{
							var feed_node = response.get_object_element(i);
							string feed_id = feed_node.get_int_member("id").to_string();
							ttrss_utils.downloadIcon(feed_id, icon_url);
					
							dataBase.write_feed(feed_id,
											  feed_node.get_string_member("title"),
											  feed_node.get_string_member("feed_url"),
											  feed_node.get_boolean_member("has_icon"),
											  int.parse(feed_node.get_int_member("unread").to_string()),
											  feed_node.get_int_member("cat_id").to_string());
						}
					}	
				}
				
				dataBase.delete_unsubscribed_feeds();
				Idle.add((owned) callback);
			}
			return null;
		};
		new GLib.Thread<void*>("getFeeds", run);
		yield;
	}
	

	public string getIconDir()
	{
		var message = new ttrss_message(m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "getConfig");
		int error = message.send();
		
		if(error == NO_ERROR)
		{
			var response = message.get_response_object();
			return response.get_string_member("icons_url") + "/";
		}

		return null;
	}


	public async void getCategories()
	{
		SourceFunc callback = getCategories.callback;
		
		ThreadFunc<void*> run = () => {
			if(isloggedin())
			{
				dataBase.reset_exists_flag();
				
				var message = new ttrss_message(m_ttrss_url);
				message.add_string("sid", m_ttrss_sessionid);
				message.add_string("op", "getFeedTree");
				message.add_bool("include_empty", false);
				int error = message.send();
		
				if(error == NO_ERROR)
				{
					var response = message.get_response_object();
					var category_object = response.get_object_member("categories");
					getSubCategories(category_object, 0, CAT_ID_NONE);
					dataBase.delete_nonexisting_categories();
					updateCategorieUnread();
				}
				
				Idle.add((owned) callback);
			}
			return null;
		};
		new GLib.Thread<void*>("getCategories", run);
		yield;
	}


	private void getSubCategories(Json.Object categorie, int level, string parent)
	{
		level++;
		int orderID = 0;
		var subcategorie = categorie.get_array_member("items");
		var items_count = subcategorie.get_length();
		for(uint i = 0; i < items_count; i++)
		{
			var categorie_node = subcategorie.get_object_element(i);
			if(categorie_node.get_string_member("id").has_prefix("CAT:"))
			{
				orderID++;

				string title = categorie_node.get_string_member("name");
				int unread_count = int.parse(categorie_node.get_int_member("unread").to_string());
				string catID = categorie_node.get_string_member("id");
				string categorieID = catID.slice(4, catID.length);
				
				if(title == "Uncategorized")
				{
					unread_count = getUncategorizedUnread();
				}

				dataBase.write_categorie(categorieID, title, unread_count, orderID, parent, level);
				getSubCategories(categorie_node, level, categorieID);
			}
		}
	}
	
	
	// FIXME: workaround for possible bug in tt-rss api -----------------------------------------------------------------------------
	private int getUncategorizedUnread()
	{
		var message = new ttrss_message(m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "getCounters");
		message.add_string("output_mode", "c");
		int error = message.send();
		
		if(error == NO_ERROR)
		{
			var response = message.get_response_array();
			var categorie_count = response.get_length();
			
			for(int i = 0; i < categorie_count; i++)
			{
				var categorie_node = response.get_object_element(i);
				if(categorie_node.get_int_member("id") == 0)
				{
					if(categorie_node.has_member("kind"))
					{
						if(categorie_node.get_string_member("kind") == "cat")
						{
							return int.parse(categorie_node.get_int_member("counter").to_string());
						}
					}
				}
			}
		}
		
		return 0;
	}
	//--------------------------------------------------------------------------------------------------------------------------------


	private void updateCategorieUnread()
	{
		var message = new ttrss_message(m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "getCategories");
		message.add_bool("include_empty", false);
		int error = message.send();
		
		if(error == NO_ERROR)
		{
			var response = message.get_response_array();
			var categorie_count = response.get_length();
			
			for(int i = 0; i < categorie_count; i++)
			{
				var categorie_node = response.get_object_element(i);
				if(categorie_node.get_string_member("id") != null)
					dataBase.updateCategorie(int.parse(categorie_node.get_string_member("id")), int.parse(categorie_node.get_int_member("unread").to_string()));
			}
		}
	}


	public async void getArticles(int feedID = TTRSS_ID_ALL, int skip = 0)
	{
		SourceFunc callback = getArticles.callback;
		ThreadFunc<void*> run = () => {
			if(isloggedin())
			{
				sync_getArticles(feedID, skip);
				Idle.add((owned) callback);
			}
			return null;
		};
		new GLib.Thread<void*>("getArticles", run);
		yield;
	}
	
	
	private void sync_getArticles(int feedID, int skip, int limit = 200)
	{
		var message = new ttrss_message(m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "getHeadlines");
		message.add_int("feed_id", feedID);
		
		if(!dataBase.isTableEmpty("articles"))
			message.add_int("since_id", dataBase.getNewestArticle());
			
		message.add_int("limit", limit);
		message.add_int("skip", skip);
		
		
		int error = message.send();
		
		if(error == NO_ERROR)
		{
			var response = message.get_response_array();
			var headline_count = response.get_length();
			stdout.printf("Number of New Articles: %u\n", headline_count);
			
			if(skip == 0){
				feed_server.sendNotification(headline_count);
			}
			
			GLib.List<article> articles = new GLib.List<article>();
			string title, author, url, html;
			stdout.printf("headline count: %u\nskip: %i\n", headline_count, skip);
			
			
			
			for(uint i = 0; i < headline_count; i++)
			{
				var headline_node = response.get_object_element(i);
				getArticle( int.parse(headline_node.get_int_member("id").to_string()),
							out title, out author, out url, out html);
				
				articles.append(new article(
										headline_node.get_int_member("id").to_string(),
										headline_node.get_string_member("title").replace("&",""),
										headline_node.get_string_member("link"),
										headline_node.get_string_member("feed_id"),
										(headline_node.get_boolean_member("unread")) ? STATUS_UNREAD : STATUS_READ,
										(headline_node.get_boolean_member("marked")) ? STATUS_MARKED : STATUS_UNMARKED,
										html,
										"",
										author,
										-1
								));
				
			}
			
			articles.reverse();
			
			// first write all new articles
			foreach(article item in articles)
			{
				dataBase.write_article(	item.m_articleID,
										item.m_feedID,
										item.m_title,
										item.m_author,
										item.m_url,
										item.m_unread,
										item.m_marked,
										DB_INSERT_OR_IGNORE,
										item.m_html,
										item.m_preview);
			}
			
			
			// then only update marked and unread for all others
			/*foreach(article item in articles)
			{
				dataBase.write_article(	item.m_articleID,
										item.m_feedID,
										item.m_title,
										item.m_author,
										item.m_url,
										item.m_unread,
										item.m_marked,
										DB_INSERT_OR_REPLACE,
										item.m_html,
										item.m_preview);
			}*/
				
			stdout.printf("headline count: %u\nskip: %i\n", headline_count, skip);
			int maxArticles = feedreader_settings.get_int("max-articles");
			if(headline_count == 200 && (skip+200) < maxArticles)
			{
				stdout.printf("get more headlines\n");
				if(maxArticles - skip < 200)
				{
					sync_getArticles(feedID, skip + 200, maxArticles - skip);
				}
				else
				{
					sync_getArticles(feedID, skip + 200);
				}
			}
		}
	}
	

	public async void updateArticles(int feedID = TTRSS_ID_ALL)
	{
		SourceFunc callback = updateArticles.callback;

		ThreadFunc<void*> run = () => {
			if(isloggedin())
			{
				int limit = 2 * feedreader_settings.get_int("max-articles");
				uint headline_count;
				
				// update unread
				var message = new ttrss_message(m_ttrss_url);
				message.add_string("sid", m_ttrss_sessionid);
				message.add_string("op", "getCompactHeadlines");
				message.add_int("feed_id", feedID);
				message.add_int("limit", limit);
				message.add_string("view_mode", "unread");
				int error = message.send();
		
				if(error == NO_ERROR)
				{
					dataBase.markReadAllArticles();
					var response = message.get_response_array();
					headline_count = response.get_length();
					stdout.printf("About to update %u Articles to unread\n", headline_count);
					
					for(uint i = 0; i < headline_count; i++)
					{
						var headline_node = response.get_object_element(i);
						dataBase.update_article.begin(headline_node.get_int_member("id").to_string(), "unread", STATUS_UNREAD, (obj, res) => {
							dataBase.update_article.end(res);
						});
					}
				}
				

				// update marked
				var message2 = new ttrss_message(m_ttrss_url);
				message2.add_string("sid", m_ttrss_sessionid);
				message2.add_string("op", "getCompactHeadlines");
				message2.add_int("feed_id", feedID);
				message2.add_int("limit", limit);
				message2.add_string("view_mode", "marked");
				error = message2.send();
		
				if(error == NO_ERROR)
				{
					dataBase.unmarkAllArticles();
					var response2 = message2.get_response_array();
					headline_count = response2.get_length();
					stdout.printf("About to update %u Articles to marked\n", headline_count);
					
					for(uint i = 0; i < headline_count; i++)
					{
						var headline_node = response2.get_object_element(i);
						dataBase.update_article.begin(headline_node.get_int_member("id").to_string(), "marked", STATUS_MARKED, (obj, res) => {
							dataBase.update_article.end(res);
						});
					}
				}
				
				Idle.add((owned) callback);
			}
			return null;
		};
		new GLib.Thread<void*>("updateArticles", run);
		yield;
	}

	
	public void getArticle(int articleID, out string title, out string author, out string url, out string html)
	{
		title = author = url = html = "error";
		
		if(isloggedin())
		{
			var message = new ttrss_message(m_ttrss_url);
			message.add_string("sid", m_ttrss_sessionid);
			message.add_string("op", "getArticle");
			message.add_int("article_id", articleID);
			int error = message.send();
		
			if(error == NO_ERROR)
			{
				var response = message.get_response_array();
				var article_node = response.get_object_element(0);
			
				title = article_node.get_string_member("title");
				url = article_node.get_string_member("link");
				author = article_node.get_string_member("author");
				html = article_node.get_string_member("content");
			}
		}
	}


	public async bool updateArticleUnread(int articleID, int unread)
	{
		SourceFunc callback = updateArticleUnread.callback;
		bool return_value = false;

		ThreadFunc<void*> run = () => {
			Idle.add((owned) callback);
			
			var message = new ttrss_message(m_ttrss_url);
			message.add_string("sid", m_ttrss_sessionid);
			message.add_string("op", "updateArticle");
			message.add_int("article_ids", articleID);
			if(unread == STATUS_UNREAD)
				message.add_int("mode", 1);
			else if(unread == STATUS_READ)
				message.add_int("mode", 0);
			message.add_int("field", 2);
			int error = message.send();
		
			if(error == NO_ERROR)
			{
				var response = message.get_response_object();
				if(response.get_string_member("status") == "OK")
					return_value = true;
			}
				
			return null;
		};
		new GLib.Thread<void*>("updateAricle", run);
		yield;

		return return_value;
	}


	public async bool updateArticleMarked(int articleID, int marked)
	{
		SourceFunc callback = updateArticleMarked.callback;
		bool return_value = false;

		ThreadFunc<void*> run = () => {
			Idle.add((owned) callback);
			
			var message = new ttrss_message(m_ttrss_url);
			message.add_string("sid", m_ttrss_sessionid);
			message.add_string("op", "updateArticle");
			message.add_int("article_ids", articleID);
			if(marked == STATUS_MARKED)
				message.add_int("mode", 1);
			else if(marked == STATUS_UNMARKED)
				message.add_int("mode", 0);
			message.add_int("field", 0);
			int error = message.send();
		
			if(error == NO_ERROR)
			{
				var response = message.get_response_object();
				if(response.get_string_member("status") == "OK")
					return_value = true;
			}
			
			return null;
		};
		new GLib.Thread<void*>("updateAricle", run);
		yield;

		return return_value;
	}
}

