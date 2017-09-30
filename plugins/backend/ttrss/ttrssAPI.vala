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

public class FeedReader.ttrssAPI : GLib.Object {

	public string m_ttrss_url { get; private set; }
	private ttrssUtils m_utils;
	private string m_ttrss_sessionid;
	private uint64 m_ttrss_apilevel;
	private Json.Parser m_parser;
	private string? m_iconDir = null;
	private Soup.Session m_session;

	public ttrssAPI ()
	{
		m_parser = new Json.Parser();
		m_utils = new ttrssUtils();
		m_session = new Soup.Session();
		m_session.user_agent = Constants.USER_AGENT;
		m_session.ssl_strict = false;
		m_session.authenticate.connect((msg, auth, retrying) => {
			if(m_utils.getHtaccessUser() == "")
			{
				Logger.error("TTRSS Session: need Authentication");
			}
			else if(!retrying)
			{
				auth.authenticate(m_utils.getHtaccessUser(), m_utils.getHtaccessPasswd());
			}
		});
	}


	public LoginResponse login()
	{
		Logger.debug("TTRSS: login");
		string username = m_utils.getUser();
		string passwd = m_utils.getPasswd();
		m_ttrss_url = m_utils.getURL();

		if(m_ttrss_url == "" && username == "" && passwd == "")
		{
			m_ttrss_url = "example-host/tt-rss";
			return LoginResponse.ALL_EMPTY;
		}
		if(m_ttrss_url == "")
			return LoginResponse.MISSING_URL;
		if(GLib.Uri.parse_scheme(m_ttrss_url) == null)
			return LoginResponse.INVALID_URL;
		if(passwd == "")
			return LoginResponse.MISSING_PASSWD;


		var message = new ttrssMessage(m_session, m_ttrss_url);
		message.add_string("op", "login");
		if(username != "")
			message.add_string("user", username);
		message.add_string("password", passwd);
		int error = message.send();
		if(error != ConnectionError.NO_RESPONSE)
			message.printResponse();

		if(error == ConnectionError.SUCCESS)
		{
			var response = message.get_response_object();
			m_ttrss_sessionid = response.get_string_member("session_id");
			m_ttrss_apilevel = response.get_int_member("api_level");
			Logger.info("TTRSS Session ID: %s".printf(m_ttrss_sessionid));
			Logger.info("TTRSS API Level: %lld".printf(m_ttrss_apilevel));

			m_iconDir = m_ttrss_url.replace("api/", getIconDir());

			if(haveAPIplugin())
				return LoginResponse.SUCCESS;

			return LoginResponse.PLUGIN_NEEDED;
		}
		else if(error == ConnectionError.API_ERROR)
		{
			return LoginResponse.API_ERROR;
		}
		else if(error == ConnectionError.NO_RESPONSE)
		{
			return LoginResponse.NO_CONNECTION;
		}
		else if(error == ConnectionError.API_DISABLED)
		{
			return LoginResponse.NO_API_ACCESS;
		}
		else if(error == ConnectionError.CA_ERROR)
		{
			return LoginResponse.CA_ERROR;
		}
		else if(error == ConnectionError.UNAUTHORIZED)
		{
			return LoginResponse.UNAUTHORIZED;
		}

		return LoginResponse.UNKNOWN_ERROR;
	}

	public bool logout()
	{
		var message = new ttrssMessage(m_session, m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "logout");
		int error = message.send();
		Logger.warning("TTRSS: logout");
		message.printResponse();

		if(error == ConnectionError.SUCCESS)
		{
			var response = message.get_response_object();
			m_ttrss_sessionid = "";
			return response.get_boolean_member("status");
		}

		return false;
	}


	public bool isloggedin()
	{
		var message = new ttrssMessage(m_session, m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "isLoggedIn");
		int error = message.send();
		Logger.debug("TTRSS: isloggedin?");
		message.printResponse();

		if(error == ConnectionError.SUCCESS)
		{
			var response = message.get_response_object();
			return response.get_boolean_member("status");
		}

		return false;
	}

	private bool haveAPIplugin()
	{
		var message = new ttrssMessage(m_session, m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "removeLabel");
		int error = message.send();

		if(error == ConnectionError.API_ERROR)
		{
			var response = message.get_response_object();
			if(response.has_member("error"))
			{
				if(response.get_string_member("error") == "INCORRECT_USAGE")
				{
					return true;
				}
			}
		}

		return false;
	}


	public int getUnreadCount()
	{
		int unread = 0;
		var message = new ttrssMessage(m_session, m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "getUnread");
		int error = message.send();

		if(error == ConnectionError.SUCCESS)
		{
			var response = message.get_response_object();
			unread = int.parse(response.get_string_member("unread"));
		}
		Logger.info("There are %i unread articles".printf(unread));

		return unread;
	}


	public bool getFeeds(Gee.List<Feed> feeds, Gee.List<Category> categories)
	{
		foreach(var item in categories)
		{
			if(int.parse(item.getCatID()) > 0)
			{
				var message = new ttrssMessage(m_session, m_ttrss_url);
				message.add_string("sid", m_ttrss_sessionid);
				message.add_string("op", "getFeeds");
				message.add_int("cat_id", int.parse(item.getCatID()));
				int error = message.send();

				if(error == ConnectionError.SUCCESS)
				{
					var response = message.get_response_array();
					var feed_count = response.get_length();

					for(uint i = 0; i < feed_count; i++)
					{
						var feed_node = response.get_object_element(i);
						string feed_id = feed_node.get_int_member("id").to_string();
						string? icon_url = feed_node.get_boolean_member("has_icon") ? m_iconDir+feed_id+".ico" : null;

						feeds.add(
							new Feed(
									feed_id,
									feed_node.get_string_member("title"),
									feed_node.get_string_member("feed_url"),
									(int)feed_node.get_int_member("unread"),
									ListUtils.single(feed_node.get_int_member("cat_id").to_string()),
									icon_url
								)
						);
					}
				}
				else
				{
					return false;
				}
			}
		}
		return true;
	}


	public bool getUncategorizedFeeds(Gee.List<Feed> feeds)
	{
		var message = new ttrssMessage(m_session, m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "getFeeds");
		message.add_int("cat_id", 0);
		int error = message.send();

		if(error == ConnectionError.SUCCESS)
		{
			var response = message.get_response_array();
			var feed_count = response.get_length();

			for(uint i = 0; i < feed_count; i++)
			{
				var feed_node = response.get_object_element(i);
				string feed_id = feed_node.get_int_member("id").to_string();
				string? icon_url = feed_node.get_boolean_member("has_icon") ? m_iconDir+feed_id+".ico" : null;

				feeds.add(
					new Feed(
							feed_id,
							feed_node.get_string_member("title"),
							feed_node.get_string_member("feed_url"),
							(int)feed_node.get_int_member("unread"),
							ListUtils.single(feed_node.get_int_member("cat_id").to_string()),
							icon_url
						)
				);
			}
			return true;
		}

		return false;
	}

	public bool getTags(Gee.List<tag> tags)
	{
		var message = new ttrssMessage(m_session, m_ttrss_url);
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
				tags.add(
					new tag(
						tag_node.get_int_member("id").to_string(),
						tag_node.get_string_member("caption"),
						dbDaemon.get_default().getTagColor()
					)
				);
			}

			return true;
		}

		return false;
	}


	public string? getIconDir()
	{
		var message = new ttrssMessage(m_session, m_ttrss_url);
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


	public bool getCategories(Gee.List<Category> categories)
	{
		var message = new ttrssMessage(m_session, m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "getFeedTree");
		message.add_bool("include_empty", true);
		int error = message.send();

		if(error == ConnectionError.SUCCESS)
		{
			var response = message.get_response_object();
			if(response.has_member("categories"))
			{
				var category_object = response.get_object_member("categories");
				getSubCategories(categories, category_object, 0, CategoryID.MASTER.to_string());
				return true;
			}
		}
		return false;
	}


	private void getSubCategories(Gee.List<Category> categories, Json.Object categorie, int level, string parent)
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
				string catID = categorie_node.get_string_member("id");
				string categorieID = catID.slice(4, catID.length);

				if(int.parse(categorieID) > 0)
				{
					string title = categorie_node.get_string_member("name");
					int unread_count = (int)categorie_node.get_int_member("unread");

					if(title == "Uncategorized")
					{
						unread_count = getUncategorizedUnread();
					}

					categories.add(
						new Category (
							categorieID,
							title,
							unread_count,
							orderID,
							parent,
							level
						)
					);
				}

				getSubCategories(categories, categorie_node, level, categorieID);
			}
		}
	}


	private int getUncategorizedUnread()
	{
		var message = new ttrssMessage(m_session, m_ttrss_url);
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


	public void getHeadlines(Gee.List<Article> articles, int skip, int limit, ArticleStatus whatToGet, int feedID)
	{
		var message = new ttrssMessage(m_session, m_ttrss_url);
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
		message.printMessage();

		if(error == ConnectionError.SUCCESS)
		{
			var response = message.get_response_array();
			var headline_count = response.get_length();

			for(uint i = 0; i < headline_count; i++)
			{
				var headline_node = response.get_object_element(i);

				Gee.List<string>? tags = null;
				if(headline_node.has_member("labels"))
				{
					var labels = headline_node.get_array_member("labels");

					uint tag_count = 0;
					if(labels != null)
						tag_count = labels.get_length();

					if(tag_count > 0) {
						tags = new Gee.ArrayList<string>();
						for(int j = 0; j < tag_count; ++j)
						{
							tags.add(labels.get_array_element(j).get_int_element(0).to_string());
						}
					}
				}

				Gee.List<string>? media = null;
				if(headline_node.has_member("attachments"))
				{
					var attachments = headline_node.get_array_member("attachments");

					uint mediaCount = 0;
					if(attachments != null)
						mediaCount = attachments.get_length();

					if(mediaCount > 0)
					 	media = new Gee.ArrayList<string>();
					for(int j = 0; j < mediaCount; ++j)
					{
						var attachment = attachments.get_object_element(j);
						if(attachment.get_string_member("content_type").contains("audio")
						|| attachment.get_string_member("content_type").contains("video"))
						{
							media.add(attachment.get_string_member("content_url"));
						}
					}
				}

				var Article = new Article(
										headline_node.get_int_member("id").to_string(),
										headline_node.get_string_member("title"),
										headline_node.get_string_member("link"),
										headline_node.get_string_member("feed_id"),
										(headline_node.get_boolean_member("unread")) ? ArticleStatus.UNREAD : ArticleStatus.READ,
										(headline_node.get_boolean_member("marked")) ? ArticleStatus.MARKED : ArticleStatus.UNMARKED,
										"",
										"",
										(headline_node.get_string_member("author") == "") ? null : headline_node.get_string_member("author"),
										new DateTime.from_unix_local(headline_node.get_int_member("updated")),
										-1,
										tags,
										media
								);

				articles.add(Article);
			}
		}
	}

	// tt-rss server needs newsplusplus extention
	public Gee.List<string>? NewsPlus(ArticleStatus type, int limit)
	{
		var message = new ttrssMessage(m_session, m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "getCompactHeadlines");
		message.add_int("feed_id", ttrssUtils.TTRSSSpecialID.ALL);
		message.add_int("limit", limit);
		if(type == ArticleStatus.UNREAD)
			message.add_string("view_mode", "unread");
		else if(type == ArticleStatus.MARKED)
			message.add_string("view_mode", "marked");
		else
			return null;
		int error = message.send();
		message.printMessage();

		if(error == ConnectionError.SUCCESS)
		{
			var response = message.get_response_array();
			var headline_count = response.get_length();

			var ids = new Gee.LinkedList<string>();

			for(uint i = 0; i < headline_count; i++)
			{
				var headline_node = response.get_object_element(i);
				ids.add(headline_node.get_int_member("id").to_string());
			}
			return ids;
		}
		return null;
	}


	public void getArticles(string articleIDs, Gee.List<Article> articles)
	{
		var message = new ttrssMessage(m_session, m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "getArticle");
		message.add_string("article_id", articleIDs);
		int error = message.send();
		message.printMessage();
		//message.printResponse();

		if(error == ConnectionError.SUCCESS)
		{
			var response = message.get_response_array();
			var article_count = response.get_length();

			for(uint i = 0; i < article_count; i++)
			{
				var article_node = response.get_object_element(i);

				Gee.List<string>? tags = null;
				if(article_node.has_member("labels"))
				{
					var labels = article_node.get_array_member("labels");

					uint tag_count = 0;
					if(labels != null)
						tag_count = labels.get_length();

					if(tag_count > 0)
						tags = new Gee.ArrayList<string>();

					for(int j = 0; j < tag_count; ++j)
					{
						tags.add(labels.get_array_element(j).get_int_element(0).to_string());
					}
				}

				Gee.List<string>? media = null;
				if(article_node.has_member("attachments"))
				{
					var attachments = article_node.get_array_member("attachments");

					uint mediaCount = 0;
					if(attachments != null)
						mediaCount = attachments.get_length();

					if(mediaCount > 0)
						media = new Gee.ArrayList<string>();

					for(int j = 0; j < mediaCount; ++j)
					{
						var attachment = attachments.get_object_element(j);
						if(attachment.get_string_member("content_type").contains("audio")
						|| attachment.get_string_member("content_type").contains("video"))
						{
							media.add(attachment.get_string_member("content_url"));
						}
					}
				}

				var Article = new Article(
										article_node.get_string_member("id"),
										article_node.get_string_member("title"),
										article_node.get_string_member("link"),
										article_node.get_string_member("feed_id"),
										(article_node.get_boolean_member("unread")) ? ArticleStatus.UNREAD : ArticleStatus.READ,
										(article_node.get_boolean_member("marked")) ? ArticleStatus.MARKED : ArticleStatus.UNMARKED,
										article_node.get_string_member("content"),
										"",
										(article_node.get_string_member("author") == "") ? null : article_node.get_string_member("author"),
										new DateTime.from_unix_local(article_node.get_int_member("updated")),
										-1,
										tags,
										media
								);

				articles.add(Article);
			}
		}
	}

	public bool catchupFeed(string feedID, bool isCatID)
	{
		bool return_value = false;
		var message = new ttrssMessage(m_session, m_ttrss_url);
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

	public bool updateArticleUnread(string articleIDs, ArticleStatus unread)
	{
		bool return_value = false;
		var message = new ttrssMessage(m_session, m_ttrss_url);
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

		//message.printMessage();
		//message.printResponse();

		return return_value;
	}


	public bool updateArticleMarked(int articleID, ArticleStatus marked)
	{
		bool return_value = false;
		var message = new ttrssMessage(m_session, m_ttrss_url);
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

	public bool setArticleLabel(int articleID, int tagID, bool add)
	{
		var message = new ttrssMessage(m_session, m_ttrss_url);
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

	public int64 addLabel(string caption)
	{
		var message = new ttrssMessage(m_session, m_ttrss_url);
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

	public bool removeLabel(int tagID)
	{
		var message = new ttrssMessage(m_session, m_ttrss_url);
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

	public bool renameLabel(int tagID, string newName)
	{
		var message = new ttrssMessage(m_session, m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "renameLabel");
		message.add_int("label_id", tagID);
		message.add_string("caption", newName);
		int error = message.send();

		if(error == ConnectionError.SUCCESS)
		{
			return true;
		}

		return false;
	}


	public bool subscribeToFeed(string feedURL, string? catID, string? username, string? password, out string errmsg)
	{
		errmsg = "";
		var message = new ttrssMessage(m_session, m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "subscribeToFeed");
		message.add_string("feed_url", feedURL);

		if(catID != null)
			message.add_int("category_id", int.parse(catID));
		if(username != null && password != null)
		{
			message.add_string("login", username);
			message.add_string("password", password);
		}

		int error = message.send();
		message.printMessage();
		message.printResponse();
		Logger.debug(message.getStatusCode().to_string());

		if(error == ConnectionError.SUCCESS)
		{
			var response = message.get_response_object();
			if(response.has_member("status"))
			{
				var status = response.get_object_member("status");
				if(status.has_member("code"))
				{
					switch(status.get_int_member("code"))
					{
						case 0:
						case 1:
							return true;
						case 2:
							errmsg = _("Invalid URL");
							return false;
						case 3:
							errmsg = _("URL content is HTML, no feeds available");
							return false;
						case 4:
							errmsg = _("URL content is HTML which contains multiple feeds.");
							return false;
						case 5:
							errmsg = _("Couldn't download the URL content.");
							return false;
						case 6:
							errmsg = _("Content is an invalid XML.");
							return false;
						default:
							if(status.has_member("message"))
								errmsg = status.get_string_member("message");
							else
								errmsg = "ttrss error";
							return false;
					}
				}
			}
		}

		errmsg = _("Error reaching tt-rss");
		return false;
	}

	public bool unsubscribeFeed(int feedID)
	{
		var message = new ttrssMessage(m_session, m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "unsubscribeFeed");
		message.add_int("feed_id", feedID);
		int error = message.send();

		if(error == ConnectionError.SUCCESS)
		{
			return true;
		}

		return false;
	}

	public string? createCategory(string title, int? parentID = null)
	{
		var message = new ttrssMessage(m_session, m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "addCategory");
		message.add_string("caption", title);
		if(parentID != null)
			message.add_int("parent_id", parentID);
		int error = message.send();
		message.printMessage();


		if(error == ConnectionError.SUCCESS)
		{
			return message.get_response_string();
		}

		return null;
	}

	public bool removeCategory(int catID)
	{
		var message = new ttrssMessage(m_session, m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "removeCategory");
		message.add_int("category_id", catID);
		int error = message.send();

		if(error == ConnectionError.SUCCESS)
		{
			return true;
		}

		return false;
	}

	public bool moveCategory(int catID, int parentID)
	{
		var message = new ttrssMessage(m_session, m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "moveCategory");
		message.add_int("category_id", catID);
		if(parentID != int.parse(CategoryID.MASTER.to_string()))
			message.add_int("parent_id", parentID);
		int error = message.send();

		if(error == ConnectionError.SUCCESS)
		{
			return true;
		}

		return false;
	}

	public bool renameCategory(int catID, string title)
	{
		var message = new ttrssMessage(m_session, m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "renameCategory");
		message.add_int("category_id", catID);
		message.add_string("caption", title);
		int error = message.send();

		if(error == ConnectionError.SUCCESS)
		{
			return true;
		}

		return false;
	}

	public bool renameFeed(int feedID, string title)
	{
		var message = new ttrssMessage(m_session, m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "renameFeed");
		message.add_int("feed_id", feedID);
		message.add_string("caption", title);
		int error = message.send();

		if(error == ConnectionError.SUCCESS)
		{
			return true;
		}

		return false;
	}

	public bool moveFeed(int feedID, int catID)
	{
		var message = new ttrssMessage(m_session, m_ttrss_url);
		message.add_string("sid", m_ttrss_sessionid);
		message.add_string("op", "moveFeed");
		message.add_int("feed_id", feedID);
		message.add_int("category_id", catID);
		int error = message.send();

		if(error == ConnectionError.SUCCESS)
		{
			return true;
		}

		return false;
	}

	public bool ping()
	{
		Logger.debug("TTRSS: ping");
		var message = new ttrssMessage(m_session, m_ttrss_url);
		int error = message.send(true);

		if(error == ConnectionError.SUCCESS)
		{
			return true;
		}

		return false;
	}
}
