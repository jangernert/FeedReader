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

	public string ttrss_url { get; private set; }

	private string m_ttrss_sessionid;
	private uint64 m_ttrss_apilevel;
	private Soup.Session m_session;
	private string m_contenttype;
	private Json.Parser m_parser;

	
	public ttrss_interface ()
	{
		m_session = new Soup.Session ();
		m_contenttype = "application/x-www-form-urlencoded";
		m_parser = new Json.Parser ();
	}

	
	public bool login(out string error_message)
	{
		error_message = "no errors";
		ttrss_url = dataBase.read_login("url");
		string username = dataBase.read_login("user");

		var pwSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
		                                  "URL", Secret.SchemaAttributeType.STRING,
		                                  "Username", Secret.SchemaAttributeType.STRING);

		var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
		attributes["URL"] = ttrss_url;
		attributes["Username"] = username;

		string passwd = "";
		try{passwd = Secret.password_lookupv_sync(pwSchema, attributes, null);}catch(GLib.Error e){}
		
		
		if(ttrss_url == "" && username == "" && passwd == ""){
			ttrss_url = "example-host/tt-rss";
			error_message = "";
			return false;
		}
		if(ttrss_url == ""){
			error_message = "No URL entered";
			return false;
		}
		if(username == ""){
			error_message = "No username entered";
			return false;
		}
		if(passwd == ""){
			error_message = "No password entered";
			return false;
		}

		
		var message_login = new Soup.Message ("POST", ttrss_url);
		string login = "{\"op\":\"login\",\"user\":\"" + username + "\",\"password\":\"" + passwd + "\"}";
		message_login.set_request(m_contenttype, Soup.MemoryUse.COPY, login.data);

		if(m_session.send_message (message_login) != 200){
			error_message = "Sorry, could not reach the given URL.";
			return false;
		}
		
		try{
			if(!m_parser.load_from_data ((string) message_login.response_body.flatten ().data, -1)){
				error_message = "The given URL seems not to point to a valid instance of tt-rss";
				return false;
			}
		}
		catch (Error e) {
			error_message = "The given URL seems not to point to a valid instance of tt-rss.";
			return false;
		}

		var root_object = m_parser.get_root ().get_object ();
		var response = root_object.get_object_member ("content");

		if(response.has_member("session_id"))
		{
			m_ttrss_sessionid = response.get_string_member("session_id");
			m_ttrss_apilevel = response.get_int_member("api_level");
		}
		else if(response.has_member("error"))
		{
			string login_error = response.get_string_member("error");
			if(login_error == "LOGIN_ERROR"){
				error_message = "The given username or password are not correct.";			
				return false;
			}
		}

		

		stdout.printf ("Session ID: %s\n", m_ttrss_sessionid);
		stdout.printf ("API Level: %lld\n", m_ttrss_apilevel);
		return true;
	}


	private bool isloggedin()
	{
		var message_isloggedin = new Soup.Message ("POST", ttrss_url);
		string isloggedin = "{\"sid\":\"" + m_ttrss_sessionid + "\",\"op\":\"isLoggedIn\"}";
		message_isloggedin.set_request(m_contenttype, Soup.MemoryUse.COPY, isloggedin.data);
		m_session.send_message (message_isloggedin);

		try{
			m_parser.load_from_data ((string) message_isloggedin.response_body.flatten().data, -1);
		}
		catch (Error e) {
			stderr.printf ("I guess something is not working...\n");
			return false;
		}

		var root_object = m_parser.get_root ().get_object ();
		var response = root_object.get_object_member ("content");
		bool loggedin = response.get_boolean_member("status");

		return loggedin;
	}

	 
	public async int getUnreadCount()
	{
		SourceFunc callback = getUnreadCount.callback;
		int unread = 0;
		ThreadFunc<void*> run = () => {
			if(isloggedin()) {
				var message_unread = new Soup.Message ("POST", ttrss_url);
				string getunread = "{\"sid\":\"" + m_ttrss_sessionid + "\",\"op\":\"getUnread\"}";
				message_unread.set_request(m_contenttype, Soup.MemoryUse.COPY, getunread.data);
				m_session.send_message (message_unread);

				try{
					m_parser.load_from_data ((string) message_unread.response_body.flatten ().data, -1);
				}
				catch (Error e) {
					stderr.printf ("I guess something is not working...\n");
				}

				var root_object = m_parser.get_root ().get_object ();
				var response = root_object.get_object_member ("content");
				var unreadcount = response.get_string_member("unread");

				unread = int.parse(unreadcount);
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
				int all_unread_count = 0;

				var categories = dataBase.read_categories();
				try{
					for(int row = 1; !categories.finished; row++, categories.next() )
					{
						var message_getFeeds = new Soup.Message("POST", ttrss_url);
						string getFeeds = "{\"sid\":\"" + m_ttrss_sessionid + "\",\"op\":\"getFeeds\", \"cat_id\":" + categories.fetch_int(0).to_string() + "}";
						message_getFeeds.set_request(m_contenttype, Soup.MemoryUse.COPY, getFeeds.data);
						m_session.send_message(message_getFeeds);

						try{
							m_parser.load_from_data((string) message_getFeeds.response_body.flatten ().data, -1);
						}
						catch (Error e) {
							stderr.printf("I guess something is not working...\n");
						}

						var root_object = m_parser.get_root().get_object();
						var response = root_object.get_array_member ("content");
						var feed_count = response.get_length();
				
				
						string icon_url = ttrss_url.replace("api/", getIconDir());
				
						for(uint i = 0; i < feed_count; i++)
						{
							var feed_node = response.get_object_element(i);
							string feed_id = feed_node.get_int_member("id").to_string();
							downloadIcon(feed_id, icon_url);
					
							all_unread_count += int.parse(feed_node.get_int_member("unread").to_string());
					
							dataBase.write_feed(int.parse(feed_id),
										  feed_node.get_string_member("title"),
										  feed_node.get_string_member("feed_url"),
										  feed_node.get_boolean_member("has_icon"),
										  int.parse(feed_node.get_int_member("unread").to_string()),
									      int.parse(feed_node.get_int_member("cat_id").to_string()));
						}
					}
				}catch(SQLHeavy.Error e){}
				
				
				dataBase.write_propertie("unread_articles", all_unread_count);
				dataBase.delete_unsubscribed_feeds();
				Idle.add((owned) callback);
			}
			return null;
		};
		new GLib.Thread<void*>("getFeeds", run);
		yield;
	}


	private void downloadIcon(string feed_id, string icon_url)
	{
		string icon_path = GLib.Environment.get_home_dir() + "/.local/share/feedreader/data/feed_icons/";
		var path = GLib.File.new_for_path(icon_path);
		try{path.make_directory_with_parents();}catch(GLib.Error e){}
		
		string remote_filename = icon_url + feed_id + ".ico";
		string local_filename = icon_path + feed_id + ".ico";
					
			
		if(!FileUtils.test (local_filename, GLib.FileTest.EXISTS))
		{
			Soup.Message message_dlIcon;
			message_dlIcon = new Soup.Message ("GET", remote_filename);
			var status = m_session.send_message(message_dlIcon);
			if (status == 200)
				try{FileUtils.set_contents(local_filename, (string)message_dlIcon.response_body.flatten().data, (long)message_dlIcon.response_body.length);}
				catch(GLib.FileError e){}
		}
	}


	public string getIconDir()
	{
		var message_getIconDir = new Soup.Message("POST", ttrss_url);
		string getIconDir = "{\"sid\":\"" + m_ttrss_sessionid + "\",\"op\":\"getConfig\"}";
		message_getIconDir.set_request(m_contenttype, Soup.MemoryUse.COPY, getIconDir.data);
		m_session.send_message(message_getIconDir);

		try{
			m_parser.load_from_data((string) message_getIconDir.response_body.flatten ().data, -1);
		}
		catch (Error e){}

		var root_object = m_parser.get_root().get_object();
		var response = root_object.get_object_member("content");

		return response.get_string_member("icons_url") + "/";
	}


	public async void getCategories()
	{
		SourceFunc callback = getCategories.callback;
		
		ThreadFunc<void*> run = () => {
			if(isloggedin())
			{
				dataBase.reset_exists_flag();
				var message_getCategories = new Soup.Message("POST", ttrss_url);
				string getCategories = "{\"sid\":\"" + m_ttrss_sessionid + "\",\"op\":\"getFeedTree\",\"include_empty\":false}";
				
				message_getCategories.set_request(m_contenttype, Soup.MemoryUse.COPY, getCategories.data);
				m_session.send_message(message_getCategories);

				try{
					m_parser.load_from_data((string)message_getCategories.response_body.flatten().data, -1);
				}
				catch (Error e) {
					stderr.printf("I guess something is not working...\n");
				}

				var root_object = m_parser.get_root().get_object();
				var response = root_object.get_object_member("content");
				var category_object = response.get_object_member("categories");

				getSubCategories(category_object, 0, -99);
				dataBase.delete_nonexisting_categories();
				updateCategorieUnread();
				Idle.add((owned) callback);
			}
			return null;
		};
		new GLib.Thread<void*>("getCategories", run);
		yield;
	}


	private void getSubCategories(Json.Object categorie, int level, int parent)
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
				int categorieID = int.parse(catID.slice(4, catID.length));

				dataBase.write_categorie(categorieID, title, unread_count, orderID, parent, level);
				getSubCategories(categorie_node, level, categorieID);
			}
		}
	}


	private void updateCategorieUnread()
	{
		var message_getCategories = new Soup.Message("POST", ttrss_url);
		string getCategories = "{\"sid\":\"" + m_ttrss_sessionid + "\",\"op\":\"getCategories\",\"include_empty\":false}";

		message_getCategories.set_request(m_contenttype, Soup.MemoryUse.COPY, getCategories.data);
		m_session.send_message(message_getCategories);

		try{
			m_parser.load_from_data((string)message_getCategories.response_body.flatten().data, -1);
		}
		catch (Error e) {}

		var root_object = m_parser.get_root().get_object();
		var response = root_object.get_array_member("content");
		var categorie_count = response.get_length();

		for(int i = 0; i < categorie_count; i++)
		{
			var categorie_node = response.get_object_element(i);
			if(categorie_node.get_string_member("id") != null)
				dataBase.updateCategorie(int.parse(categorie_node.get_string_member("id")), int.parse(categorie_node.get_int_member("unread").to_string()));
		}
	}


	public async void getHeadlines(int64 feedID = -4)
	{
		SourceFunc callback = getHeadlines.callback;
		//stdout.printf("getHeadlines\n");
		ThreadFunc<void*> run = () => {
			if(isloggedin())
			{
				var message_getHeadlines = new Soup.Message("POST", ttrss_url);

				string getHeadlines;
				if(dataBase.isTableEmpty("headlines"))
				{
					getHeadlines =
					"{\"sid\":\"" + m_ttrss_sessionid + "\", \"op\":\"getHeadlines\"" + ", \"feed_id\":\"" + feedID.to_string() + "\"}";
				}
				else
				{
					getHeadlines = 
					"{\"sid\":\"" + m_ttrss_sessionid + "\", \"op\":\"getHeadlines\"" + ", \"feed_id\":\"" + feedID.to_string() + "\"" + ", \"since_id\":" + dataBase.getNewestArticle().to_string() + "}";
				}
				message_getHeadlines.set_request(m_contenttype, Soup.MemoryUse.COPY, getHeadlines.data);
				m_session.send_message(message_getHeadlines);
			
				try{
					m_parser.load_from_data((string) message_getHeadlines.response_body.flatten ().data, -1);
				} catch (Error e) {}

				var root_object = m_parser.get_root().get_object();
				var response = root_object.get_array_member ("content");

				var headline_count = response.get_length();
				string title, author, url, html;
				stdout.printf("Number of New Articles: %u\n", headline_count);

				if(headline_count > 0){
					try{
						string verb = "";
						if(headline_count == 1)
							verb = " is "
						else
							verb = " are ";
						Notify.Notification notification = new Notify.Notification("New Articles", "There" + verb + headline_count.to_string() + " new articles", "internet-news-reader");
						notification.show ();
					}catch (GLib.Error e) {
						error("Error: %s", e.message);
					}
				}
			
				
				for(uint i = 0; i < headline_count; i++)
				{
					var headline_node = response.get_object_element(i);
				
					dataBase.write_headline(int.parse(headline_node.get_int_member("id").to_string()),
						             headline_node.get_string_member("title").replace("&",""),
						             headline_node.get_string_member("link"),
						             int.parse(headline_node.get_string_member("feed_id")),
						             headline_node.get_boolean_member("unread"),
						             headline_node.get_boolean_member("marked")
						             );
					
					getArticle(int.parse(headline_node.get_int_member("id").to_string()),
					           out title, out author, out url, out html);
					dataBase.write_article(int.parse(headline_node.get_int_member("id").to_string()),
					                 int.parse(headline_node.get_string_member("feed_id")),
					                 title, author, url, html);
				}
				Idle.add((owned) callback);
			}
			return null;
		};
		new GLib.Thread<void*>("getHeadlines", run);
		yield;
	}


	public async void updateHeadlines(int limit, int64 feedID = -4)
	{
		SourceFunc callback = updateHeadlines.callback;

		ThreadFunc<void*> run = () => {
			if(isloggedin())
			{
				// update unread
				dataBase.markReadAllArticles();
				var message_updateHeadlines = new Soup.Message("POST", ttrss_url);
				string updateHeadlines = 
					"{\"sid\":\"" + m_ttrss_sessionid + "\",\"op\":\"getCompactHeadlines\", \"feed_id\":" + feedID.to_string() + ", \"limit\":" + limit.to_string() + ", \"view_mode\":\"unread\"}";
				message_updateHeadlines.set_request(m_contenttype, Soup.MemoryUse.COPY, updateHeadlines.data);
				m_session.send_message(message_updateHeadlines);
			
				try{
					m_parser.load_from_data((string) message_updateHeadlines.response_body.flatten ().data, -1);
				} catch (Error e) {}

				var root_object = m_parser.get_root().get_object();
				var response = root_object.get_array_member ("content");
				var headline_count = response.get_length();
				stdout.printf("About to update %u Articles to unread\n", headline_count);
			
	
				for(uint i = 0; i < headline_count; i++)
				{
					var headline_node = response.get_object_element(i);
					dataBase.update_headline(int.parse(headline_node.get_int_member("id").to_string()), "unread", true);
				}

				// update marked
				dataBase.unmarkAllArticles();
				message_updateHeadlines = new Soup.Message("POST", ttrss_url);
				updateHeadlines = 
					"{\"sid\":\"" + m_ttrss_sessionid + "\",\"op\":\"getCompactHeadlines\", \"feed_id\":" + feedID.to_string() + ", \"limit\":" + limit.to_string() + ", \"view_mode\":\"marked\"}";
				message_updateHeadlines.set_request(m_contenttype, Soup.MemoryUse.COPY, updateHeadlines.data);
				m_session.send_message(message_updateHeadlines);

				try{
					m_parser.load_from_data((string) message_updateHeadlines.response_body.flatten ().data, -1);
				} catch (Error e) {}

				root_object = m_parser.get_root().get_object();
				response = root_object.get_array_member ("content");
				headline_count = response.get_length();
				stdout.printf("About to update %u Articles to marked\n", headline_count);

				for(uint i = 0; i < headline_count; i++)
				{
					var headline_node = response.get_object_element(i);
					dataBase.update_headline(int.parse(headline_node.get_int_member("id").to_string()), "marked", true);
				}
				
				Idle.add((owned) callback);
			}
			return null;
		};
		new GLib.Thread<void*>("updateHeadlines", run);
		yield;
	}

	
	public void getArticle(int articleID, out string title, out string author, out string url, out string html)
	{
		title = author = url = html = "error";
		
		if(isloggedin())
		{
			var message_getArticle = new Soup.Message("POST", ttrss_url);
			string getArticle = 
				"{\"sid\":\"" + m_ttrss_sessionid + "\",\"op\":\"getArticle\", \"article_id\":" + articleID.to_string() + "}";
			message_getArticle.set_request(m_contenttype, Soup.MemoryUse.COPY, getArticle.data);
			m_session.send_message(message_getArticle);

				
			try{
				m_parser.load_from_data ((string)message_getArticle.response_body.flatten().data, -1);
			}
			catch(Error e){}

			var root_object = m_parser.get_root().get_object();
			var response = root_object.get_array_member("content");
			var article_node = response.get_object_element(0);
			title = article_node.get_string_member("title");
			url = article_node.get_string_member("link");
			author = article_node.get_string_member("author");
			html = article_node.get_string_member("content");
		}
	}


	public async bool updateArticleUnread(int articleID, bool unread)
	{
		SourceFunc callback = updateArticleUnread.callback;
		bool return_value = false;

		ThreadFunc<void*> run = () => {
			Idle.add((owned) callback);
			int int_unread = 0;
			if(unread)
				int_unread = 1;
		
			var message_updateAricle = new Soup.Message ("POST", ttrss_url);
			string updateAricle = "{\"sid\":\"" + m_ttrss_sessionid + "\",\"op\":\"updateArticle\",\"article_ids\":" + articleID.to_string() + ",\"mode\":" + int_unread.to_string() + ",\"field\":2}";
			//stdout.printf("update Article message: %s\n", updateAricle);
			message_updateAricle.set_request(m_contenttype, Soup.MemoryUse.COPY, updateAricle.data);
			m_session.send_message (message_updateAricle);

			try{
				m_parser.load_from_data ((string) message_updateAricle.response_body.flatten().data, -1);
			}
			catch (Error e) {
				stderr.printf ("I guess something is not working...\n");
			}

			var root_object = m_parser.get_root ().get_object ();
			var response = root_object.get_object_member ("content");
			if(response.get_string_member("status") == "OK")
				return_value = true;
			
			return null;
		};
		new GLib.Thread<void*>("updateAricle", run);
		yield;

		return return_value;
	}


	public async bool updateArticleMarked(int articleID, bool marked)
	{
		SourceFunc callback = updateArticleMarked.callback;
		bool return_value = false;

		ThreadFunc<void*> run = () => {
			Idle.add((owned) callback);
			int int_marked = 0;
			if(marked)
				int_marked = 1;
		
			var message_updateAricle = new Soup.Message ("POST", ttrss_url);
			string updateAricle = "{\"sid\":\"" + m_ttrss_sessionid + "\",\"op\":\"updateArticle\",\"article_ids\":" + articleID.to_string() + ",\"mode\":" + int_marked.to_string() + ",\"field\":0}";
			message_updateAricle.set_request(m_contenttype, Soup.MemoryUse.COPY, updateAricle.data);
			m_session.send_message (message_updateAricle);

			try{
				m_parser.load_from_data ((string) message_updateAricle.response_body.flatten().data, -1);
			}
			catch (Error e) {
				stderr.printf ("I guess something is not working...\n");
			}

			var root_object = m_parser.get_root ().get_object ();
			var response = root_object.get_object_member ("content");
			if(response.get_string_member("status") == "OK")
				return_value = true;
			
			return null;
		};
		new GLib.Thread<void*>("updateAricle", run);
		yield;

		return return_value;
	}
}

