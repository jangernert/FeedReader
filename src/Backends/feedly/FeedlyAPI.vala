public class FeedReader.FeedlyAPI : Object {

	private FeedlyConnection m_connection;
	private string m_token;
	private string m_refresh_token;
	private string m_userID;
	private Gee.HashMap<string,int> markers;
	private Json.Array m_unreadcounts;

	public FeedlyAPI() {
		m_connection = new FeedlyConnection();
	}

	public int login()
	{
		logger.print(LogMessage.DEBUG, "feedly backend: login");
		if(settings_feedly.get_string("feedly-refresh-token") == "")
		{
			m_connection.getToken();
		}

		if(tokenStillValid() == ConnectionError.INVALID_SESSIONID)
		{
			logger.print(LogMessage.DEBUG, "refresh token");
			m_connection.refreshToken();
		}

		getUserID();
		logger.print(LogMessage.DEBUG, "feedly: login success");
		return LoginResponse.SUCCESS;
	}

	private void getUserID()
	{
		string response = m_connection.send_get_request_to_feedly ("/v3/profile/");
		var parser = new Json.Parser ();
		parser.load_from_data (response, -1);
		var root = parser.get_root().get_object();

		if(root.has_member("id"))
		{
			m_userID = root.get_string_member("id");
			print(m_userID + "\n");
		}
	}

	private int tokenStillValid()
	{
		string response = m_connection.send_get_request_to_feedly ("/v3/profile/");
		var parser = new Json.Parser ();
		parser.load_from_data (response, -1);
		var root = parser.get_root().get_object();

		if(root.has_member("errorId"))
		{
			return ConnectionError.INVALID_SESSIONID;
		}
		return ConnectionError.SUCCESS;
	}


	public void getCategories(ref GLib.List<category> categories)
	{
		string response = m_connection.send_get_request_to_feedly ("/v3/categories/");

		var parser = new Json.Parser();
		parser.load_from_data (response, -1);
		Json.Array array = parser.get_root ().get_array ();

		for (int i = 0; i < array.get_length (); i++) {
			Json.Object object = array.get_object_element(i);
			string categorieID = object.get_string_member("id");

			categories.append(
				new category (
					categorieID,
					object.get_string_member("label"),
					getUnreadCountforID(categorieID),
					i+1,
					CategoryID.MASTER,
					1
				)
			);
		}
	}


	public void getFeeds(ref GLib.List<feed> feeds)
	{
		string response = m_connection.send_get_request_to_feedly("/v3/subscriptions/");

		var parser = new Json.Parser();
		parser.load_from_data(response, -1);
		Json.Array array = parser.get_root().get_array ();
		uint length = array.get_length();

		for (uint i = 0; i < length; i++) {
			Json.Object object = array.get_object_element(i);


			string feedID = object.get_string_member("id");
			string url = object.has_member("website") ? object.get_string_member("website") : "";
			string icon_url = "";
			if(object.has_member("iconUrl"))
			{
				icon_url = object.get_string_member("iconUrl");
				downloadIcon(feedID, icon_url);
			}
			else if(object.has_member("visualUrl"))
			{
				icon_url = object.get_string_member("visualUrl");
				downloadIcon(feedID, icon_url);
			}

			string title = "No Title";
			if(object.has_member("title"))
			{
				title = object.get_string_member("title");
			}
			else
			{
				title = ttrss_utils.URLtoFeedName(url);
			}

			feeds.append(
				new feed (
						feedID,
						title,
						url,
						(icon_url == "") ? false : true,
						getUnreadCountforID(object.get_string_member("id")),
						object.get_array_member("categories").get_object_element(0).get_string_member("id")
					)
			);
		}
	}


	public void getTags(ref GLib.List<tag> tags)
	{
		string response = m_connection.send_get_request_to_feedly("/v3/tags/");

		var parser = new Json.Parser();
		parser.load_from_data(response, -1);
		Json.Array array = parser.get_root().get_array ();
		uint length = array.get_length();

		for (uint i = 0; i < length; i++) {
			Json.Object object = array.get_object_element(i);

			tags.append(
				new tag(
					object.get_string_member("id"),
					object.has_member("label") ? object.get_string_member("label") : "",
					dataBase.getTagColor()
				)
			);
		}
	}



	public void getArticles(ref GLib.List<article> articles, int maxArticles, int whatToGet = ArticleStatus.ALL, string tagID = "")
	{
		string steamID = "";
		string onlyUnread = "false";

		if(whatToGet == ArticleStatus.ALL)
			steamID = "user/" + m_userID + "/category/global.all";
		else if(whatToGet == ArticleStatus.MARKED)
			steamID = "user/" + m_userID + "/tag/global.saved";
		else if(whatToGet == ArticleStatus.UNREAD)
			onlyUnread = "true";


		if(tagID != "" && whatToGet == ArticleStatus.ALL)
			steamID = "user/" + m_userID + "/tag/" + tagID;



		string entry_id_response = m_connection.send_get_request_to_feedly("/v3/streams/ids?streamId=%s&unreadOnly=%s&count=%i&ranked=newest".printf(steamID, onlyUnread, maxArticles));
		string response = m_connection.send_post_string_request_to_feedly("/v3/entries/.mget", entry_id_response,"application/json");

		var parser = new Json.Parser();
		parser.load_from_data(response, -1);

		var array = parser.get_root().get_array();

		for(int i = 0; i < array.get_length(); i++) {
			Json.Object object = array.get_object_element(i);
			string id = object.get_string_member("id");
			string title = object.has_member("title") ? object.get_string_member("title") : "No title specified";
			string author = object.has_member("author") ? object.get_string_member("author") : "None";
			string summaryContent = object.has_member("summary") ? object.get_object_member("summary").get_string_member("content") : "";
			string Content = object.has_member("content") ? object.get_object_member("content").get_string_member("content") : summaryContent;
			bool unread = object.get_boolean_member("unread");
			string url = object.has_member("alternate") ? object.get_array_member("alternate").get_object_element(0).get_string_member("href") : "";
			string feedID = object.get_object_member("origin").get_string_member("streamId");
			string tagString = "";

			if(object.has_member("tags"))
			{
				var tags = object.get_array_member("tags");
				uint tagCount = tags.get_length();

				for(int j = 0; j < tagCount; ++j)
				{
					tagString = tagString + tags.get_object_element(j).get_string_member("id") + ",";
				}
			}

			articles.append(
				new article(
					id,
					title,
					url,
					feedID,
					(unread) ? ArticleStatus.UNREAD : ArticleStatus.READ,
					ArticleStatus.UNMARKED,
					Content,
					summaryContent,
					author,
					((int)object.get_int_member("updated"))/1000, // timestamp includes msecs so divide by 1000 to get rid of them
					-1,
					tagString
				)
			);
		}
	}


	private void downloadIcon(string feed_id, string icon_url)
	{
		string icon_path = GLib.Environment.get_home_dir() + "/.local/share/feedreader/data/feed_icons/";
		var path = GLib.File.new_for_path(icon_path);
		try{path.make_directory_with_parents();}catch(GLib.Error e){}
		string local_filename = icon_path + feed_id.replace("/", "_").replace(".", "_") + ".ico";

		if(!FileUtils.test (local_filename, GLib.FileTest.EXISTS))
		{
			Soup.Message message_dlIcon;
			message_dlIcon = new Soup.Message ("GET", icon_url);
			var session = new Soup.Session ();
			var status = session.send_message(message_dlIcon);
			if (status == 200)
				try{FileUtils.set_contents(local_filename, (string)message_dlIcon.response_body.flatten().data, (long)message_dlIcon.response_body.length);}
				catch(GLib.FileError e){}
		}
	}

	/** Returns the number of unread articles for an ID (may be a feed, subscription, category or tag */
	public void getUnreadCounts()
	{
		string response = m_connection.send_get_request_to_feedly ("/v3/markers/counts");

		var parser = new Json.Parser ();
		parser.load_from_data (response, -1);

		var object = parser.get_root ().get_object ();

		m_unreadcounts = object.get_array_member("unreadcounts");
	}

	private int getUnreadCountforID(string id)
	{
		int unread_count = -1;

		for (int i = 0; i < m_unreadcounts.get_length (); i++) {
			var unread = m_unreadcounts.get_object_element (i);

			string unread_id = unread.get_string_member ("id");

			if (id == unread_id) {
				unread_count = (int)unread.get_int_member ("count");
				break;
			}
		}

		if(unread_count == -1) {
			logger.print(LogMessage.ERROR, "Unkown id: %s".printf(id));
		}

		return unread_count;
	}

	public int getTotalUnread()
	{
		int unread_count = 0;

		for (int i = 0; i < m_unreadcounts.get_length (); i++) {
			var unread = m_unreadcounts.get_object_element (i);
			unread_count += (int)unread.get_int_member ("count");
		}

		return unread_count;
	}


	public void mark_as_read(string ids_string, string type, int read)
	{
		var id_array = ids_string.split(",");
		Json.Object object = new Json.Object();

		if(read == ArticleStatus.READ)
			object.set_string_member ("action", "markAsRead");
		else if(read == ArticleStatus.UNREAD)
			object.set_string_member ("action", "undoMarkAsRead");
		object.set_string_member ("type", type);

		Json.Array ids = new Json.Array();
		foreach(string id in id_array)
		{
			ids.add_string_element (id);
		}

		string* type_id_identificator = null;

		if(type == "entries") {
			type_id_identificator = "entryIds";
		} else if(type == "feeds") {
			type_id_identificator = "feedIds";
		} else if(type == "categories") {
			type_id_identificator = "categoryIds";
		} else {
			error ("Unknown type: " + type + " don't know what to do with this.");
		}

		object.set_array_member (type_id_identificator, ids);

		var root = new Json.Node(Json.NodeType.OBJECT);
		root.set_object (object);

		m_connection.send_post_request_to_feedly ("/v3/markers", root);
	}
}
