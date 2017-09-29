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
		Logger.debug("fresh backend: login");

		if(!Utils.ping(m_utils.getUnmodifiedURL()))
			return LoginResponse.NO_CONNECTION;

		return m_connection.getSID();
	}

	public bool getSubscriptionList(Gee.List<Feed> feeds)
	{
		var response = m_connection.getRequest("reader/api/0/subscription/list?output=json");

		if(response.status != 200)
			return false;

		var parser = new Json.Parser();
		try
		{
			parser.load_from_data(response.data, -1);
		}
		catch (Error e)
		{
			Logger.error("getTagList: Could not load message response");
			Logger.error(e.message);
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

			string? icon_url = null;
			if(object.has_member("iconUrl"))
				icon_url = object.get_string_member("iconUrl");

			feeds.add(
				new Feed(
					id,
					title,
					url,
					0,
					{ catID },
					icon_url,
					xmlURL)
			);
		}

		return true;
	}

	public bool getTagList(Gee.List<category> categories)
	{
		var response = m_connection.getRequest("reader/api/0/tag/list?output=json");
		string prefix = "user/-/label/";

		if(response.status != 200)
			return false;

		var parser = new Json.Parser();
		try
		{
			parser.load_from_data(response.data, -1);
		}
		catch (Error e)
		{
			Logger.error("getTagList: Could not load message response");
			Logger.error(e.message);
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
		var response = m_connection.getRequest("reader/api/0/unread-count?output=json");

		if(response.status != 200)
			return 0;

		int count = 0;

		var parser = new Json.Parser();
		try
		{
			parser.load_from_data(response.data, -1);
		}
		catch (Error e)
		{
			Logger.error("getTagList: Could not load message response");
			Logger.error(e.message);
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
										Gee.LinkedList<Article> articles,
										string? feedID = null,
										string? labelID = null,
										string? exclude = null,
										int count = 400,
										string order = "d",
										string? checkpoint = null
								)
	{
		var now = new DateTime.now_local();
		string path = "reader/api/0/stream/contents";

		if(feedID != null)
			path += "/" + feedID;
		else if(labelID != null)
			path += "/" + labelID;


		var msg = new freshMessage();
		msg.add("output", "json");
		msg.add("r", order);
		msg.add("n", count.to_string());
		msg.add("client", "FeedReader");
		msg.add("ck", now.to_unix().to_string());

		if(exclude != null)
			msg.add("xt", exclude);

		if(checkpoint != null)
			msg.add("c", checkpoint);

		Logger.debug("getStreamContents: %s".printf(msg.get()));

		var response = m_connection.getRequest(path + "?" + msg.get());

		if(response.status != 200)
			return null;

		var parser = new Json.Parser();
		try
		{
			parser.load_from_data(response.data, -1);
		}
		catch(Error e)
		{
			Logger.error("getStreamContents: Could not load message response");
			Logger.error(e.message);
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
					if(attachment.has_member("type"))
					{
						if(attachment.get_string_member("type").contains("audio")
						|| attachment.get_string_member("type").contains("video"))
						{
							media.add(attachment.get_string_member("href"));
						}
					}
				}
			}

			string? author = null;
			if(object.has_member("author"))
			{
				author = (object.get_string_member("author") == "") ? null : object.get_string_member("author");
			}


			articles.add(new Article(
									id,
									object.get_string_member("title"),
									object.get_array_member("alternate").get_object_element(0).get_string_member("href"),
									object.get_object_member("origin").get_string_member("streamId"),
									read ? ArticleStatus.READ : ArticleStatus.UNREAD,
									marked ? ArticleStatus.MARKED : ArticleStatus.UNMARKED,
									object.get_object_member("summary").get_string_member("content"),
									"",
									author,
									new DateTime.from_unix_local(object.get_int_member("published")),
									-1,
									null,
									media
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

		var msg = new freshMessage();
		msg.add("T", m_connection.getToken());

		if(addTag != null)
			msg.add("a", addTag);

		if(removeTag != null)
			msg.add("r", removeTag);

		foreach(string id in arrayID)
		{
			msg.add("r", "-/" + id);
		}

		var response = m_connection.postRequest(path,  msg.get(), "application/x-www-form-urlencoded");

		if(response.status != 200)
		{
			Logger.debug(path + " " + msg.get());
			Logger.debug(response.status.to_string());
		}
	}

	public void markAllAsRead(string streamID)
	{
		string path = "reader/api/0/mark-all-as-read";

		var msg = new freshMessage();
		msg.add("T", m_connection.getToken());
		msg.add("s", streamID);
		msg.add("ts", dbDaemon.get_default().getNewestArticle());

		var response = m_connection.postRequest(path, msg.get(), "application/x-www-form-urlencoded");

		if(response.status != 200)
		{
			Logger.debug(path + " " + msg.get());
			Logger.debug(response.status.to_string());
		}
	}

	public Response editStream(
							string action,
							string[]? streamID = null,
							string? title = null,
							string? add = null,
							string? remove = null
						)
	{
		string path = "reader/api/0/subscription/edit";

		var msg = new freshMessage();
		msg.add("T", m_connection.getToken());
		msg.add("ac", action);

		if(streamID != null)
		{
			foreach(string s in streamID)
				msg.add("s", s);
		}

		if(title != null)
			msg.add("t", title);

		if(add != null)
			msg.add("a", add);

		if(remove != null)
			msg.add("r", remove);

		var response = m_connection.postRequest(path, msg.get(), "application/x-www-form-urlencoded");

		if(response.status != 200)
		{
			Logger.debug(path + " " + msg.get());
			Logger.debug(response.status.to_string());
		}

		return response;
	}

	public string composeTagID(string title)
	{
		return "user/-/label/%s".printf(title);
	}

	public void renameTag(string tagID, string title)
	{
		string path = "reader/api/0/rename-tag";

		var msg = new freshMessage();
		msg.add("T", m_connection.getToken());
		msg.add("s", tagID);
		msg.add("dest", composeTagID(title));

		var response = m_connection.postRequest(path, msg.get(), "application/x-www-form-urlencoded");


		if(response.status != 200)
		{
			Logger.debug(path + " " + msg.get());
			Logger.debug(response.status.to_string());
		}
	}

	public void deleteTag(string tagID)
	{
		string path = "reader/api/0/disable-tag";

		var msg = new freshMessage();
		msg.add("T", m_connection.getToken());
		msg.add("s", tagID);

		var response = m_connection.postRequest(path, msg.get(), "application/x-www-form-urlencoded");

		if(response.status != 200)
		{
			Logger.debug(path + " " + msg.get());
			Logger.debug(response.status.to_string());
		}
	}

}
