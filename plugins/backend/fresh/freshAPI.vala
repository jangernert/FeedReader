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

FeedReader.dbDaemon dataBase;
FeedReader.Logger logger;

public class FeedReader.freshAPI : Object {

	private freshConnection m_connection;
	private freshUtils m_utils;

	public freshAPI()
	{
		m_connection = new freshConnection();
		m_utils = new freshUtils();
	}

	public LoginResponse login()
	{
		logger.print(LogMessage.DEBUG, "fresh backend: login");

		if(!Utils.ping(m_utils.getUnmodifiedURL()))
			return LoginResponse.NO_CONNECTION;

		return m_connection.getSID();
	}

	public bool getSubscriptionList(Gee.LinkedList<feed> feeds)
	{
		string response = m_connection.getRequest("reader/api/0/subscription/list?output=json");

		if(response == "" || response == null)
			return false;

		var parser = new Json.Parser();
		try
		{
			parser.load_from_data(response, -1);
		}
		catch (Error e)
		{
			logger.print(LogMessage.ERROR, "getTagList: Could not load message response");
			logger.print(LogMessage.ERROR, e.message);
			return false;
		}
		Json.Array array = parser.get_root().get_object().get_array_member("subscriptions");

		for (int i = 0; i < array.get_length (); i++)
		{
			Json.Object object = array.get_object_element(i);

			string url = object.get_string_member("htmlUrl");
			string id = object.get_string_member("id");
			string catID = object.get_array_member("categories").get_object_element(0).get_string_member("id");
			string xmlURL = object.get_string_member("url");

			string title = "No Title";
			if(object.has_member("title"))
			{
				title = object.get_string_member("title");
			}
			else
			{
				title = Utils.URLtoFeedName(url);
			}

			string icon_url = "";
			if(object.has_member("iconUrl"))
			{
				icon_url = object.get_string_member("iconUrl");
			}
			if(icon_url != "" && !m_utils.downloadIcon(id, icon_url))
			{
				icon_url = "";
			}

			bool hasIcon = (icon_url == "") ? false : true;

			feeds.add(
				new feed(
					id,
					title,
					url,
					hasIcon,
					0,
					{ catID },
					xmlURL)
			);
		}

		return true;
	}

	public bool getTagList(Gee.LinkedList<category> categories)
	{
		string response = m_connection.getRequest("reader/api/0/tag/list?output=json");
		string prefix = "user/-/label/";

		if(response == "" || response == null)
			return false;

		var parser = new Json.Parser();
		try
		{
			parser.load_from_data(response, -1);
		}
		catch (Error e)
		{
			logger.print(LogMessage.ERROR, "getTagList: Could not load message response");
			logger.print(LogMessage.ERROR, e.message);
			return false;
		}
		Json.Array array = parser.get_root().get_object().get_array_member("tags");

		for (int i = 0; i < array.get_length (); i++)
		{
			Json.Object object = array.get_object_element(i);
			string categorieID = object.get_string_member("id");


			if(!categorieID.has_prefix(prefix))
				continue;

			categories.add(
				new category (
					categorieID,
					categorieID.substring(prefix.length),
					0,
					i+1,
					CategoryID.MASTER.to_string(),
					1
				)
			);
		}

		return true;
	}

	public int getUnreadCounts()
	{
		int count = 0;
		string response = m_connection.getRequest("reader/api/0/unread-count?output=json");

		var parser = new Json.Parser();
		try
		{
			parser.load_from_data(response, -1);
		}
		catch (Error e)
		{
			logger.print(LogMessage.ERROR, "getTagList: Could not load message response");
			logger.print(LogMessage.ERROR, e.message);
		}
		Json.Array array = parser.get_root().get_object().get_array_member("unreadcounts");

		for (int i = 0; i < array.get_length (); i++)
		{
			Json.Object object = array.get_object_element(i);
			if(object.get_string_member("id") == "user/-/state/com.google/reading-list")
			{
				count = (int)object.get_int_member("count");
			}
		}

		return count;
	}

	public string? getStreamContents(
										Gee.LinkedList<article> articles,
										string? feedID = null,
										string? labelID = null,
										string? exclude = null,
										int count = 400,
										string order = "d",
										string? checkpoint = null
								)
	{
		var now = new DateTime.now_local();
		string request = "reader/api/0/stream/contents";

		if(feedID != null)
			request += "/" + feedID;
		else if(labelID != null)
			request += "/" + labelID;


		request += "?output=json";

		if(exclude != null)
			request += "&xt=" + exclude;

		request += "&r=" + order;
		request += "&n=" + count.to_string();
		request += "&client=FeedReader";
		request += "&ck=" + now.to_unix().to_string();
		request += "&c=" + checkpoint;

		logger.print(LogMessage.DEBUG, "getStreamContents: %s".printf(request));

		string response = m_connection.getRequest(request);

		var parser = new Json.Parser();
		try{
			parser.load_from_data(response, -1);
		}
		catch (Error e) {
			logger.print(LogMessage.ERROR, "getStreamContents: Could not load message response");
			logger.print(LogMessage.ERROR, e.message);
		}

		var root = parser.get_root().get_object();
		var array = root.get_array_member("items");
		uint length = array.get_length();

		for(uint i = 0; i < length; i++)
		{
			Json.Object object = array.get_object_element(i);
			string id = object.get_string_member("id");
			bool marked = false;
			bool read = false;
			var cats = object.get_array_member("categories");
			uint cat_length = cats.get_length();

			for(uint j = 0; j < cat_length; j++)
			{
				string cat = cats.get_string_element(j);
				if(cat.has_suffix("com.google/starred"))
					marked = true;
				else if(cat.has_suffix("com.google/read"))
					read = true;
			}

			string mediaString = "";
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
						mediaString = mediaString + attachment.get_string_member("href") + ",";
					}
				}
			}

			articles.add(new article(
									id,
									object.get_string_member("title"),
									object.get_array_member("alternate").get_object_element(0).get_string_member("href"),
									object.get_object_member("origin").get_string_member("streamId"),
									read ? ArticleStatus.READ : ArticleStatus.UNREAD,
									marked ? ArticleStatus.MARKED : ArticleStatus.UNMARKED,
									object.get_object_member("summary").get_string_member("content"),
									"",
									(object.get_string_member("author") == "") ? null : object.get_string_member("author"),
									new DateTime.from_unix_local(object.get_int_member("published")),
									-1,
									"",
									mediaString
							)
						);
		}


		if(root.has_member("continuation") && root.get_string_member("continuation") != "")
			return root.get_string_member("continuation");

		return null;
	}

	public void editTags(string articleIDs, string? addTag = null, string? removeTag = null)
	{
		string path = "reader/api/0/edit-tag";
		string[] arrayID = articleIDs.split(",");

		string request = "T=" + m_connection.getToken();

		if(addTag != null)
		{
			request += "&a=" + addTag;
		}

		if(removeTag != null)
		{
			request += "&r=" + removeTag;
		}

		foreach(string id in arrayID)
		{
			request += "&i=-/" + id;
		}

		string response = m_connection.postRequest(path, request, "application/x-www-form-urlencoded");
	}

	public void markAllAsRead(string streamID)
	{
		string path = "reader/api/0/mark-all-as-read";

		string request = "T=" + m_connection.getToken();
		request += "&s=" + streamID;

		string response = m_connection.postRequest(path, request, "application/x-www-form-urlencoded");
	}

}
