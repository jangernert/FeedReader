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

public class FeedReader.FeedlyAPI : Object {

	private FeedlyConnection m_connection;
	private string m_userID;
	private Json.Array m_unreadcounts;
	private FeedlyUtils m_utils;

	public FeedlyAPI() {
		m_connection = new FeedlyConnection();
		m_utils = new FeedlyUtils();
	}

	public string createCatID(string title)
	{
		return "user/%s/category/%s".printf(m_userID, title);
	}

	public string getMarkedID()
	{
		return "user/" + m_userID + "/tag/global.saved";
	}

	public LoginResponse login()
	{
		Logger.debug("feedly backend: login");

		if(!Utils.ping("http://feedly.com/"))
			return LoginResponse.NO_CONNECTION;

		if(m_utils.getRefreshToken() == "")
		{
			m_connection.getToken();
		}

		if(tokenStillValid() == ConnectionError.INVALID_SESSIONID)
		{
			Logger.debug("refresh token");
			m_connection.refreshToken();
		}

		if(getUserID())
		{
			Logger.debug("feedly: login success");
			return LoginResponse.SUCCESS;
		}

		m_utils.setAccessToken("");
		m_utils.setRefreshToken("");
		m_utils.setApiCode("");

		return LoginResponse.UNKNOWN_ERROR;
	}

	private bool getUserID()
	{
		var response = m_connection.send_get_request_to_feedly ("/v3/profile/");

		if(response.status != 200)
			return false;

		var parser = new Json.Parser();
		try
		{
			parser.load_from_data(response.data, -1);
		}
		catch(Error e)
		{
			Logger.error("getUserID: Could not load message response");
			Logger.error(e.message);
			return false;
		}
		var root = parser.get_root().get_object();

		if(root.has_member("id"))
		{
			m_userID = root.get_string_member("id");
			Logger.info("feedly: userID = " + m_userID);

			if(root.has_member("email"))
				m_utils.setEmail(root.get_string_member("email"));
			else if(root.has_member("givenName"))
				m_utils.setEmail(root.get_string_member("givenName"));
			else if(root.has_member("fullName"))
				m_utils.setEmail(root.get_string_member("fullName"));
			else if(root.has_member("google"))
				m_utils.setEmail(root.get_string_member("google"));
			else if(root.has_member("reader"))
				m_utils.setEmail(root.get_string_member("reader"));
			else if(root.has_member("twitterUserId"))
				m_utils.setEmail(root.get_string_member("twitterUserId"));
			else if(root.has_member("facebookUserId"))
				m_utils.setEmail(root.get_string_member("facebookUserId"));
			else if(root.has_member("wordPressId"))
				m_utils.setEmail(root.get_string_member("wordPressId"));
			else if(root.has_member("windowsLiveId"))
				m_utils.setEmail(root.get_string_member("windowsLiveId"));

			return true;
		}

		return false;
	}

	private ConnectionError tokenStillValid()
	{
		var response = m_connection.send_get_request_to_feedly ("/v3/profile/");

		if(response.status != 200)
			return ConnectionError.NO_RESPONSE;

		var parser = new Json.Parser ();
		try
		{
			parser.load_from_data(response.data, -1);
		}
		catch(Error e)
		{
			Logger.error("tokenStillValid: Could not load message response");
			Logger.error(e.message);
			return ConnectionError.NO_RESPONSE;
		}

		var root = parser.get_root().get_object();

		if(root.has_member("errorId"))
		{
			return ConnectionError.INVALID_SESSIONID;
		}
		return ConnectionError.SUCCESS;
	}


	public bool getCategories(Gee.List<Category> categories)
	{
		var response = m_connection.send_get_request_to_feedly ("/v3/categories/");

		if(response.status != 200)
			return false;

		var parser = new Json.Parser();
		try
		{
			parser.load_from_data(response.data, -1);
		}
		catch (Error e)
		{
			Logger.error("getCategories: Could not load message response");
			Logger.error(e.message);
			return false;
		}
		Json.Array array = parser.get_root().get_array();

		for (int i = 0; i < array.get_length(); i++)
		{
			Json.Object object = array.get_object_element(i);
			string categorieID = object.get_string_member("id");

			if(categorieID.has_suffix("global.all")
			|| categorieID.has_suffix("global.uncategorized"))
				continue;

			categories.add(
				new Category (
					categorieID,
					object.get_string_member("label"),
					getUnreadCountforID(categorieID),
					i+1,
					CategoryID.MASTER.to_string(),
					1
				)
			);
		}

		return true;
	}


	public bool getFeeds(Gee.List<Feed> feeds)
	{
		var response = m_connection.send_get_request_to_feedly("/v3/subscriptions/");

		if(response.status != 200)
			return false;

		var parser = new Json.Parser();
		try
		{
			parser.load_from_data(response.data, -1);
		}
		catch(Error e)
		{
			Logger.error("getFeeds: Could not load message response");
			Logger.error(e.message);
			return false;
		}
		Json.Array array = parser.get_root().get_array();
		uint length = array.get_length();

		for (uint i = 0; i < length; i++) {
			Json.Object object = array.get_object_element(i);


			string feedID = object.get_string_member("id");
			string url = object.has_member("website") ? object.get_string_member("website") : "";
			string? icon_url = null;
			if(object.has_member("iconUrl"))
				icon_url = object.get_string_member("iconUrl");
			else if(object.has_member("visualUrl"))
				icon_url = object.get_string_member("visualUrl");

			string title = "No Title";
			if(object.has_member("title"))
			{
				title = object.get_string_member("title");
			}
			else
			{
				title = Utils.URLtoFeedName(url);
			}

			uint catCount = object.get_array_member("categories").get_length();

			var categories = new Gee.ArrayList<string>();
			for(uint j = 0; j < catCount; ++j)
			{
				string categoryID = object.get_array_member("categories").get_object_element(j).get_string_member("id");

				if(categoryID.has_suffix("global.all")
				|| categoryID.has_suffix("global.uncategorized"))
					continue;

				categories.add(categoryID);
			}

			feeds.add(
				new Feed(
						feedID,
						title,
						url,
						getUnreadCountforID(object.get_string_member("id")),
						categories,
						icon_url
					)
			);
		}

		return true;
	}


	public bool getTags(Gee.List<tag> tags)
	{
		var response = m_connection.send_get_request_to_feedly("/v3/tags/");

		if(response.status != 200)
			return false;

		var parser = new Json.Parser();
		try{
			parser.load_from_data(response.data, -1);
		}
		catch (Error e) {
			Logger.error("getTags: Could not load message response");
			Logger.error(e.message);
			return false;
		}
		Json.Array array = parser.get_root().get_array ();
		uint length = array.get_length();

		for (uint i = 0; i < length; i++) {
			Json.Object object = array.get_object_element(i);

			tags.add(
				new tag(
					object.get_string_member("id"),
					object.has_member("label") ? object.get_string_member("label") : "",
					DataBase.readOnly().getTagColor()
				)
			);
		}

		return true;
	}



	public string? getArticles(Gee.List<Article> articles, int count, string? continuation = null, ArticleStatus whatToGet = ArticleStatus.ALL, string tagID = "", string feed_id = "")
	{
		string steamID = "user/" + m_userID + "/category/global.all";
		string onlyUnread = "false";
		string marked_tag = "user/" + m_userID + "/tag/global.saved";

		if(whatToGet == ArticleStatus.MARKED)
			steamID = marked_tag;
		else if(whatToGet == ArticleStatus.UNREAD)
			onlyUnread = "true";


		if(tagID != "" && whatToGet == ArticleStatus.ALL)
			steamID = tagID;

		if(feed_id != "" && whatToGet == ArticleStatus.ALL)
			steamID = feed_id;

		var parser = new Json.Parser();

		string streamCall = "/v3/streams/ids?streamId=%s&unreadOnly=%s&count=%i&ranked=newest&continuation=%s".printf(steamID, onlyUnread, count, (continuation == null) ? "" : continuation);
		var entry_id_response = m_connection.send_get_request_to_feedly(streamCall);

		if(entry_id_response.status != 200)
			return null;

		try
		{
			parser.load_from_data(entry_id_response.data, -1);
		}
		catch(Error e)
		{
			Logger.error("getArticles: Could not load message response");
			Logger.error(e.message);
		}

		var root = parser.get_root().get_object();
		if(!root.has_member("continuation"))
			return null;

		string cont = root.get_string_member("continuation");

		var response = m_connection.send_post_string_request_to_feedly("/v3/entries/.mget", entry_id_response.data,"application/json");

		if(response.status != 200)
			return null;

		try
		{
			parser.load_from_data(response.data, -1);
		}
		catch(Error e)
		{
			Logger.error("getArticles: Could not load message response");
			Logger.error(e.message);
		}
		var array = parser.get_root().get_array();

		for(int i = 0; i < array.get_length(); i++)
		{
			Json.Object object = array.get_object_element(i);
			string id = object.get_string_member("id");
			string title = object.has_member("title") ? object.get_string_member("title") : "No title specified";
			string? author = object.has_member("author") ? object.get_string_member("author") : null;
			string summaryContent = object.has_member("summary") ? object.get_object_member("summary").get_string_member("content") : "";
			string content = object.has_member("content") ? object.get_object_member("content").get_string_member("content") : summaryContent;
			bool unread = object.get_boolean_member("unread");
			string url = object.has_member("alternate") ? object.get_array_member("alternate").get_object_element(0).get_string_member("href") : "";
			string feedID = object.get_object_member("origin").get_string_member("streamId");

			DateTime date = new DateTime.now_local();
			if(object.has_member("updated") && object.get_int_member("updated") > 0)
			{
				date = new DateTime.from_unix_local(object.get_int_member("updated")/1000);
			}
			else if(object.has_member("published") && object.get_int_member("published") > 0)
			{
				date = new DateTime.from_unix_local(object.get_int_member("published")/1000);
			}
			else if(object.has_member("crawled") && object.get_int_member("crawled") > 0)
			{
				date = new DateTime.from_unix_local(object.get_int_member("crawled")/1000);
			}

			var marked = ArticleStatus.UNMARKED;

			var tags = new Gee.ArrayList<string>();
			if(object.has_member("tags"))
			{
				var tag_array = object.get_array_member("tags");
				uint tagCount = tag_array.get_length();

				for(int j = 0; j < tagCount; ++j)
				{
					var tag = tag_array.get_object_element(j).get_string_member("id");
					if(tag == marked_tag)
						marked = ArticleStatus.MARKED;
					else if(tag.contains("global."))
						continue;
					else
						tags.add(tag);
				}
			}

			var media = new Gee.ArrayList<string>();
			if(object.has_member("enclosure"))
			{
				var attachments = object.get_array_member("enclosure");

				uint mediaCount = 0;
				if(attachments != null)
					mediaCount = attachments.get_length();

				for(int j = 0; j < mediaCount; ++j)
				{
					var attachment = attachments.get_object_element(j);
					if(attachment.get_string_member("type").contains("audio")
					|| attachment.get_string_member("type").contains("video"))
					{
						media.add(attachment.get_string_member("href"));
					}
				}
			}

			var Article = new Article(
								id,
								title,
								url,
								feedID,
								(unread) ? ArticleStatus.UNREAD : ArticleStatus.READ,
								marked,
								content,
								//summaryContent,
								"",
								author,
								date, // timestamp includes msecs so divide by 1000 to get rid of them
								-1,
								tags,
								media
						);
			articles.add(Article);
		}

		return cont;
	}

	/** Returns the number of unread articles for an ID (may be a feed, subscription, category or tag */
	public void getUnreadCounts()
	{
		var response = m_connection.send_get_request_to_feedly ("/v3/markers/counts");

		if(response.status != 200)
			return;

		var parser = new Json.Parser ();
		try
		{
			parser.load_from_data(response.data, -1);
		}
		catch(Error e)
		{
			Logger.error("getUnreadCounts: Could not load message response");
			Logger.error(e.message);
		}

		var object = parser.get_root ().get_object ();

		m_unreadcounts = object.get_array_member("unreadcounts");
	}

	private int getUnreadCountforID(string id)
	{
		int unread_count = -1;

		for(int i = 0; i < m_unreadcounts.get_length (); i++)
		{
			var unread = m_unreadcounts.get_object_element(i);
			string unread_id = unread.get_string_member("id");

			if(id == unread_id)
			{
				unread_count = (int)unread.get_int_member("count");
				break;
			}
		}

		if(unread_count == -1)
		{
			Logger.error("Unknown id: %s".printf(id));
		}

		return unread_count;
	}

	public int getTotalUnread()
	{
		return getUnreadCountforID("user/" + m_userID + "/category/global.all");
	}


	public void mark_as_read(string ids_string, string type, ArticleStatus read)
	{
		var id_array = ids_string.split(",");
		Json.Object object = new Json.Object();

		if(read == ArticleStatus.READ)
			object.set_string_member ("action", "markAsRead");
		else if(read == ArticleStatus.UNREAD)
			object.set_string_member ("action", "keepUnread");
		object.set_string_member ("type", type);

		Json.Array ids = new Json.Array();
		foreach(string id in id_array)
		{
			ids.add_string_element(id);
		}

		string* type_id_identificator = null;

		if(type == "entries")
		{
			type_id_identificator = "entryIds";
		}
		else if(type == "feeds")
		{
			type_id_identificator = "feedIds";
		}
		else if(type == "categories")
		{
			type_id_identificator = "categoryIds";
		}
		else
		{
			error ("Unknown type: " + type + " don't know what to do with this.");
		}

		object.set_array_member(type_id_identificator, ids);

		if(type == "feeds"
		|| type == "categories")
		{
			var now = new DateTime.now_local();
			object.set_int_member("asOf", now.to_unix()*1000);
		}

		var root = new Json.Node(Json.NodeType.OBJECT);
		root.set_object (object);

		m_connection.send_post_request_to_feedly("/v3/markers", root);
	}

	public void addArticleTag(string ids_string, string tagID)
	{
		var id_array = ids_string.split(",");
		Json.Object object = new Json.Object();

		Json.Array ids = new Json.Array();
		foreach(string id in id_array)
		{
			ids.add_string_element(id);
		}

		object.set_array_member("entryIds", ids);
		var root = new Json.Node(Json.NodeType.OBJECT);
		root.set_object(object);

		m_connection.send_put_request_to_feedly("/v3/tags/" + GLib.Uri.escape_string(tagID), root);
	}

	public void deleteArticleTag(string ids_string, string tagID)
	{
		string command = GLib.Uri.escape_string(tagID) + "/" + GLib.Uri.escape_string(ids_string);
		m_connection.send_delete_request_to_feedly("/v3/tags/" + command);
	}

	public string createTag(string caption)
	{
		string tagID = "user/" + m_userID + "/tag/" + caption;
		Json.Object object = new Json.Object();
		object.set_string_member("entryId", "");
		var root = new Json.Node(Json.NodeType.OBJECT);
		root.set_object(object);

		m_connection.send_put_request_to_feedly("/v3/tags/" + GLib.Uri.escape_string(tagID), root);
		return tagID;
	}

	public void deleteTag(string tagID)
	{
		m_connection.send_delete_request_to_feedly("/v3/tags/" + GLib.Uri.escape_string(tagID));
	}


	public bool addSubscription(string feedURL, string? title = null, string? catIDs = null)
	{
		Json.Object object = new Json.Object();
		object.set_string_member("id", "feed/" + feedURL);

		if(title != null)
		{
			object.set_string_member("title", title);
		}

		if(catIDs != null)
		{
			var catArray = catIDs.split(",");
			Json.Array cats = new Json.Array();

			foreach(string catID in catArray)
			{
				string catName = DataBase.readOnly().getCategoryName(catID);
				Json.Object catObject = new Json.Object();
				catObject.set_string_member("id", catID);
				catObject.set_string_member("label", catName);
				cats.add_object_element(catObject);
			}

			object.set_array_member("categories", cats);
		}

		var root = new Json.Node(Json.NodeType.OBJECT);
		root.set_object(object);

		var response = m_connection.send_post_request_to_feedly("/v3/subscriptions", root);

		return response.status == 200;
	}

	public void moveSubscription(string feedID, string newCatID, string? oldCatID = null)
	{
		var Feed = DataBase.readOnly().read_feed(feedID);

		Json.Object object = new Json.Object();
		object.set_string_member("id", feedID);
		object.set_string_member("title", Feed.getTitle());


		var catArray = Feed.getCatIDs();
		Json.Array cats = new Json.Array();

		foreach(string catID in catArray)
		{
			if(catID != oldCatID)
			{
				string catName = DataBase.readOnly().getCategoryName(catID);
				Json.Object catObject = new Json.Object();
				catObject.set_string_member("id", catID);
				catObject.set_string_member("label", catName);
				cats.add_object_element(catObject);
			}
		}

		string newCatName = DataBase.readOnly().getCategoryName(newCatID);
		Json.Object catObject = new Json.Object();
		catObject.set_string_member("id", newCatID);
		catObject.set_string_member("label", newCatName);
		cats.add_object_element(catObject);

		object.set_array_member("categories", cats);

		var root = new Json.Node(Json.NodeType.OBJECT);
		root.set_object(object);

		m_connection.send_post_request_to_feedly("/v3/subscriptions", root);
	}

	public void removeSubscription(string feedID)
	{
		m_connection.send_delete_request_to_feedly("/v3/subscriptions/" + feedID);
	}

	public void renameCategory(string catID, string title)
	{
		Json.Object object = new Json.Object();
		object.set_string_member("label", title);
		var root = new Json.Node(Json.NodeType.OBJECT);
		root.set_object(object);

		m_connection.send_post_request_to_feedly("/v3/categories/" + catID, root);
	}

	public void renameTag(string tagID, string title)
	{
		Json.Object object = new Json.Object();
		object.set_string_member("label", title);
		var root = new Json.Node(Json.NodeType.OBJECT);
		root.set_object(object);

		m_connection.send_post_request_to_feedly("/v3/tags/" + tagID, root);
	}

	public void removeCategory(string catID)
	{
		m_connection.send_delete_request_to_feedly("/v3/categories/" + catID);
	}

	public void importOPML(string opml)
	{
		m_connection.send_post_string_request_to_feedly("/v3/opml", opml, "text/xml");
	}
}
