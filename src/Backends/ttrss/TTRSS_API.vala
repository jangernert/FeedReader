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

public class FeedReader.ttrss_interface : GLib.Object {

	public string m_ttrss_url { get; private set; }

	private string m_ttrss_sessionid;
	private uint64 m_ttrss_apilevel;
	private Json.Parser m_parser;


	public ttrss_interface ()
	{
		m_parser = new Json.Parser();
	}


	public LoginResponse login()
	{
		logger.print(LogMessage.DEBUG, "TTRSS: login");
		string username = ttrss_utils.getUser();
		string passwd = ttrss_utils.getPasswd();
		m_ttrss_url = ttrss_utils.getURL();

		if(m_ttrss_url == "" && username == "" && passwd == ""){
			m_ttrss_url = "example-host/tt-rss";
			return LoginResponse.ALL_EMPTY;
		}
		if(m_ttrss_url == ""){
			return LoginResponse.MISSING_URL;
		}
		if(username == ""){
			return LoginResponse.MISSING_USER;
		}
		if(passwd == ""){
			return LoginResponse.MISSING_PASSWD;
		}


		var message = new ttrss_message(m_ttrss_url);
		message.add_string("op", "login");
		message.add_string("user", username);
		message.add_string("password", passwd);
		int error = message.send();

		if(error == ConnectionError.SUCCESS)
		{
			var response = message.get_response_object();
			m_ttrss_sessionid = response.get_string_member("session_id");
			m_ttrss_apilevel = response.get_int_member("api_level");
			logger.print(LogMessage.INFO, "TTRSS Session ID: %s".printf(m_ttrss_sessionid));
			logger.print(LogMessage.INFO, "TTRSS API Level: %lld".printf(m_ttrss_apilevel));
			return LoginResponse.SUCCESS;
		}
		else if(error == ConnectionError.TTRSS_API)
		{
			return LoginResponse.WRONG_LOGIN;
		}
		else if(error == ConnectionError.NO_RESPONSE)
		{
			return LoginResponse.NO_CONNECTION;
		}
		else if(error == ConnectionError.TTRSS_API_DISABLED)
		{
			return LoginResponse.NO_API_ACCESS;
		}
		else if(error == ConnectionError.CA_ERROR)
        {
            return LoginResponse.CA_ERROR;
        }

		return LoginResponse.UNKNOWN_ERROR;
	}


	public bool isloggedin()
	{
		var message = new ttrss_message(m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "isLoggedIn");
		int error = message.send();

		if(error == ConnectionError.SUCCESS)
		{
			var response = message.get_response_object();
			return response.get_boolean_member("status");
		}

		return false;
	}

	public async bool supportTags()
	{
		SourceFunc callback = supportTags.callback;
		bool result = false;

		ThreadFunc<void*> run = () => {
			var message = new ttrss_message(m_ttrss_url);
			message.add_string("sid", m_ttrss_sessionid);
			message.add_string("op", "removeLabel");
			int error = message.send();

			if(error == ConnectionError.TTRSS_API)
			{
				var response = message.get_response_object();
				if(response.has_member("error"))
				{
					if(response.get_string_member("error") == "INCORRECT_USAGE")
					{
						result = true;
					}
				}
			}

			Idle.add((owned) callback);
			return null;
		};

		new GLib.Thread<void*>("update_article", run);
		yield;

		return result;
	}


	public int getUnreadCount()
	{
		int unread = 0;
		if(isloggedin()) {
			var message = new ttrss_message(m_ttrss_url);
			message.add_string("sid", m_ttrss_sessionid);
			message.add_string("op", "getUnread");
			int error = message.send();

			if(error == ConnectionError.SUCCESS)
			{
				var response = message.get_response_object();
				unread = int.parse(response.get_string_member("unread"));
			}
			logger.print(LogMessage.INFO, "There are %i unread articles".printf(unread));
		}

		return unread;
	}


	public void getFeeds(ref GLib.List<feed> feeds, ref GLib.List<category> categories)
	{
		if(isloggedin())
		{
			foreach(var item in categories)
			{
				if(int.parse(item.getCatID()) > 0)
				{
					var message = new ttrss_message(m_ttrss_url);
					message.add_string("sid", m_ttrss_sessionid);
					message.add_string("op", "getFeeds");
					message.add_int("cat_id", int.parse(item.getCatID()));
					int error = message.send();

					if(error == ConnectionError.SUCCESS)
					{
						var response = message.get_response_array();
						var feed_count = response.get_length();
						string icon_url = m_ttrss_url.replace("api/", getIconDir());

						for(uint i = 0; i < feed_count; i++)
						{
							var feed_node = response.get_object_element(i);
							string feed_id = feed_node.get_int_member("id").to_string();

							if(feed_node.get_boolean_member("has_icon"))
								ttrss_utils.downloadIcon(feed_id, icon_url);

							feeds.append(
								new feed (
										feed_id,
										feed_node.get_string_member("title"),
										feed_node.get_string_member("feed_url"),
										feed_node.get_boolean_member("has_icon"),
										(int)feed_node.get_int_member("unread"),
										{ feed_node.get_int_member("cat_id").to_string() }
									)
							);
						}
					}
				}
			}

			getUncategorizedFeeds(ref feeds);
		}
	}


	private void getUncategorizedFeeds(ref GLib.List<feed> feeds)
	{
		var message = new ttrss_message(m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "getFeeds");
		message.add_int("cat_id", 0);
		int error = message.send();

		if(error == ConnectionError.SUCCESS)
		{
			var response = message.get_response_array();
			var feed_count = response.get_length();
			string icon_url = m_ttrss_url.replace("api/", getIconDir());

			for(uint i = 0; i < feed_count; i++)
			{
				var feed_node = response.get_object_element(i);
				string feed_id = feed_node.get_int_member("id").to_string();

				if(feed_node.get_boolean_member("has_icon"))
					ttrss_utils.downloadIcon(feed_id, icon_url);

				feeds.append(
					new feed (
							feed_id,
							feed_node.get_string_member("title"),
							feed_node.get_string_member("feed_url"),
							feed_node.get_boolean_member("has_icon"),
							(int)feed_node.get_int_member("unread"),
							{ feed_node.get_int_member("cat_id").to_string() }
						)
				);
			}
		}
	}

	public void getTags(ref GLib.List<tag> tags)
	{
		if(isloggedin())
		{
			var message = new ttrss_message(m_ttrss_url);
			message.add_string("sid", m_ttrss_sessionid);
			message.add_string("op", "getLabels");
			int error = message.send();

			if(error == ConnectionError.SUCCESS)
			{
				var response = message.get_response_array();
				var tag_count = response.get_length();

				for(uint i = 0; i < tag_count; ++i)
				{
					var tag_node = response.get_object_element(i);
					tags.append(
						new tag(
							tag_node.get_int_member("id").to_string(),
							tag_node.get_string_member("caption"),
							dataBase.getTagColor()
						)
					);
				}
			}
		}
	}


	public string getIconDir()
	{
		var message = new ttrss_message(m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "getConfig");
		int error = message.send();

		if(error == ConnectionError.SUCCESS)
		{
			var response = message.get_response_object();
			return response.get_string_member("icons_url") + "/";
		}

		return null;
	}


	public void getCategories(ref GLib.List<category> categories)
	{
		if(isloggedin())
		{
			var message = new ttrss_message(m_ttrss_url);
			message.add_string("sid", m_ttrss_sessionid);
			message.add_string("op", "getFeedTree");
			message.add_bool("include_empty", false);
			int error = message.send();

			if(error == ConnectionError.SUCCESS)
			{
				var response = message.get_response_object();
				var category_object = response.get_object_member("categories");

				getSubCategories(ref categories, category_object, 0, CategoryID.MASTER);
			}
		}
	}


	private void getSubCategories(ref GLib.List<category> categories, Json.Object categorie, int level, string parent)
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
				int unread_count = (int)categorie_node.get_int_member("unread");
				string catID = categorie_node.get_string_member("id");
				string categorieID = catID.slice(4, catID.length);

				if(title == "Uncategorized")
				{
					unread_count = getUncategorizedUnread();
				}

				categories.append(
					new category (
						categorieID,
						title,
						unread_count,
						orderID,
						parent,
						level
					)
				);

				getSubCategories(ref categories, categorie_node, level, categorieID);
			}
		}
	}


	private int getUncategorizedUnread()
	{
		var message = new ttrss_message(m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "getCounters");
		message.add_string("output_mode", "c");
		int error = message.send();

		if(error == ConnectionError.SUCCESS)
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
							return (int)categorie_node.get_int_member("counter");
						}
					}
				}
			}
		}

		return 0;
	}


	public void updateCategorieUnread()
	{
		var message = new ttrss_message(m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "getCategories");
		message.add_bool("include_empty", false);
		int error = message.send();

		if(error == ConnectionError.SUCCESS)
		{
			var response = message.get_response_array();
			var categorie_count = response.get_length();

			for(int i = 0; i < categorie_count; i++)
			{
				var categorie_node = response.get_object_element(i);
				if(categorie_node.get_string_member("id") != null)
					dataBase.updateCategorie(categorie_node.get_string_member("id"), (int)categorie_node.get_int_member("unread"));
			}
		}
	}


	public void getHeadlines(ref GLib.List<article> articles, int skip, int limit, ArticleStatus whatToGet = ArticleStatus.ALL, int feedID = TTRSSSpecialID.ALL)
	{
		var message = new ttrss_message(m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "getHeadlines");
		message.add_int("feed_id", feedID);
		message.add_int("limit", limit);
		message.add_int("skip", skip);

		switch(whatToGet)
		{
			case ArticleStatus.ALL:
				message.add_string("view_mode", "all_articles");
				break;

			case ArticleStatus.UNREAD:
				message.add_string("view_mode", "unread");
				break;

			case ArticleStatus.MARKED:
				message.add_string("view_mode", "marked");
				break;
		}

		int error = message.send();

		if(error == ConnectionError.SUCCESS)
		{
			var response = message.get_response_array();
			var headline_count = response.get_length();

			for(uint i = 0; i < headline_count; i++)
			{
				var headline_node = response.get_object_element(i);

				string tagString = "";
				if(headline_node.has_member("labels"))
				{
					var tags = headline_node.get_array_member("labels");

					uint tagCount = 0;
					if(tags != null)
						tagCount = tags.get_length();

					for(int j = 0; j < tagCount; ++j)
					{
						tagString = tagString + tags.get_array_element(j).get_int_element(0).to_string() + ",";
					}
				}

				var Article = new article(
										headline_node.get_int_member("id").to_string(),
										headline_node.get_string_member("title").replace("&",""),
										headline_node.get_string_member("link"),
										headline_node.get_string_member("feed_id"),
										(headline_node.get_boolean_member("unread")) ? ArticleStatus.UNREAD : ArticleStatus.READ,
										(headline_node.get_boolean_member("marked")) ? ArticleStatus.MARKED : ArticleStatus.UNMARKED,
										"",
										"",
										(headline_node.get_string_member("author") == "") ? _("not found") : headline_node.get_string_member("author"),
										new DateTime.from_unix_local(headline_node.get_int_member("updated")),
										-1,
										tagString
								);

				articles.append(Article);

			}
		}
	}


	public void getArticles(string articleIDs, ref GLib.List<article> articles)
	{
		if(isloggedin())
		{
			var message = new ttrss_message(m_ttrss_url);
			message.add_string("sid", m_ttrss_sessionid);
			message.add_string("op", "getArticle");
			message.add_string("article_id", articleIDs);
			int error = message.send();
			message.printMessage();

			if(error == ConnectionError.SUCCESS)
			{
				var response = message.get_response_array();
				var article_count = response.get_length();

				for(uint i = 0; i < article_count; i++)
				{
					var article_node = response.get_object_element(i);

					string tagString = "";
					if(article_node.has_member("labels"))
					{
						var tags = article_node.get_array_member("labels");

						uint tagCount = 0;
						if(tags != null)
							tagCount = tags.get_length();

						for(int j = 0; j < tagCount; ++j)
						{
							tagString = tagString + tags.get_array_element(j).get_int_element(0).to_string() + ",";
						}
					}

					var Article = new article(
											article_node.get_string_member("id"),
											article_node.get_string_member("title").replace("&",""),
											article_node.get_string_member("link"),
											article_node.get_string_member("feed_id"),
											(article_node.get_boolean_member("unread")) ? ArticleStatus.UNREAD : ArticleStatus.READ,
											(article_node.get_boolean_member("marked")) ? ArticleStatus.MARKED : ArticleStatus.UNMARKED,
											article_node.get_string_member("content"),
											"",
											(article_node.get_string_member("author") == "") ? _("not found") : article_node.get_string_member("author"),
											new DateTime.from_unix_local(article_node.get_int_member("updated")),
											-1,
											tagString
									);

					articles.append(Article);
				}
			}
		}
	}

	public bool markFeedRead(string feedID, bool isCatID)
	{
		bool return_value = false;
		var message = new ttrss_message(m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "catchupFeed");
		message.add_int_array("feed_id", feedID);
		message.add_bool("is_cat", isCatID);
		int error = message.send();

		if(error == ConnectionError.SUCCESS)
		{
			var response = message.get_response_object();
			if(response.get_string_member("status") == "OK")
				return_value = true;
		}

		return return_value;
	}

	public bool markAllItemsRead()
	{
		bool return_value = false;

		var categories = dataBase.read_categories();
		foreach(category cat in categories)
		{
			var message = new ttrss_message(m_ttrss_url);
			message.add_string("sid", m_ttrss_sessionid);
			message.add_string("op", "catchupFeed");
			message.add_int_array("feed_id", cat.getCatID());
			message.add_bool("is_cat", true);
			int error = message.send();

			if(error == ConnectionError.SUCCESS)
			{
				var response = message.get_response_object();
				if(response.get_string_member("status") == "OK")
					return_value = true;
			}
		}

		return return_value;
	}


	public bool updateArticleUnread(string articleIDs, ArticleStatus unread)
	{
		bool return_value = false;
		var message = new ttrss_message(m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "updateArticle");
		message.add_int_array("article_ids", articleIDs);
		if(unread == ArticleStatus.UNREAD)
			message.add_int("mode", 1);
		else if(unread == ArticleStatus.READ)
			message.add_int("mode", 0);
		message.add_int("field", 2);
		int error = message.send();

		if(error == ConnectionError.SUCCESS)
		{
			var response = message.get_response_object();
			if(response.get_string_member("status") == "OK")
				return_value = true;
		}

		return return_value;
	}


	public bool updateArticleMarked(int articleID, ArticleStatus marked)
	{
		bool return_value = false;
		var message = new ttrss_message(m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "updateArticle");
		message.add_int("article_ids", articleID);
		if(marked == ArticleStatus.MARKED)
			message.add_int("mode", 1);
		else if(marked == ArticleStatus.UNMARKED)
			message.add_int("mode", 0);
		message.add_int("field", 0);
		int error = message.send();

		if(error == ConnectionError.SUCCESS)
		{
			var response = message.get_response_object();
			if(response.get_string_member("status") == "OK")
				return_value = true;
		}

		return return_value;
	}

	public bool addArticleTag(int articleID, int tagID, bool add)
	{
		var message = new ttrss_message(m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "setArticleLabel");
		message.add_int("article_ids", articleID);
		message.add_int("label_id", tagID);
		message.add_bool("assign", add);
		int error = message.send();

		if(error == ConnectionError.SUCCESS)
		{
			var response = message.get_response_object();
			if(response.get_string_member("status") == "OK")
			return true;
		}

		return false;
	}

	public int64 createTag(string caption)
	{
		var message = new ttrss_message(m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "addLabel");
		message.add_string("caption", caption);
		int error = message.send();

		if(error == ConnectionError.SUCCESS)
		{
			return message.get_response_int();
		}

		return 0;
	}

	public bool deleteTag(int tagID)
	{
		var message = new ttrss_message(m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "removeLabel");
		message.add_int("label_id", tagID);
		int error = message.send();

		if(error == ConnectionError.SUCCESS)
		{
			return true;
		}

		return false;
	}
}
