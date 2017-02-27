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

public class FeedReader.FeedHQAPI : GLib.Object {

	public enum FeedHQSubscriptionAction {
		EDIT,
		SUBSCRIBE,
		UNSUBSCRIBE
	}

	private FeedHQConnection m_connection;
	private FeedHQUtils m_utils;
	private string m_userID;

	public FeedHQAPI ()
	{
		m_connection = new FeedHQConnection();
		m_utils = new FeedHQUtils();
	}


	public LoginResponse login()
	{
		Logger.debug("FeedHQ Login");

		if(m_utils.getAccessToken() == "")
		{
			var result = m_connection.getToken();
			if(m_connection.postToken() && getUserID())
				return result;
		}
		else if(getUserID())
			return LoginResponse.SUCCESS;

		return LoginResponse.UNKNOWN_ERROR;
	}

	public bool ping()
	{
		return Utils.ping("https://feedhq.org");
	}

	private bool getUserID()
	{
		var msg = new feedhqMessage();
		msg.add("output", "json");
		string response = m_connection.send_get_request("user-info", msg.get());
		var parser = new Json.Parser();
		try{
			parser.load_from_data(response, -1);
		}
		catch (Error e) {
			Logger.error("getUserID: Could not load message response");
			Logger.error(e.message);
			return false;
		}
		var root = parser.get_root().get_object();

		if(root.has_member("userId"))
		{
			m_userID = root.get_string_member("userId");
			m_utils.setUserID(m_userID);
			Logger.info("FeedHQ: userID = " + m_userID);

			if(root.has_member("userName"))
				m_utils.setUser(root.get_string_member("userName"));
			return true;
		}

		return false;
	}

	public bool getFeeds(Gee.LinkedList<feed> feeds)
	{
		var msg = new feedhqMessage();
		msg.add("output", "json");
		string response = m_connection.send_get_request("subscription/list", msg.get());
		if(response == "" || response == null)
			return false;

		var parser = new Json.Parser();
		try
		{
			parser.load_from_data(response, -1);
		}
		catch(Error e)
		{
			Logger.error("getFeeds: Could not load message response");
			Logger.error(e.message);
			return false;
		}
		var root = parser.get_root().get_object();
		var array = root.get_array_member("subscriptions");
		uint length = array.get_length();

		for (uint i = 0; i < length; i++)
		{
			Json.Object object = array.get_object_element(i);

			string feedID = object.get_string_member("id").replace("/", "_");
			string url = object.has_member("htmlUrl") ? object.get_string_member("htmlUrl") : object.get_string_member("url");
			string icon_url = object.has_member("iconUrl") ? object.get_string_member("iconUrl") : "";

			if(icon_url != "" && !m_utils.downloadIcon(feedID, "https:"+icon_url))
				icon_url = "";
			else if(!Utils.downloadIcon(feedID, url))
				icon_url = "something";

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
			string[] categories = {};

			for(uint j = 0; j < catCount; ++j)
			{
				categories += object.get_array_member("categories").get_object_element(j).get_string_member("id").replace("/", "_");
			}
			feeds.add(
				new feed (
						feedID,
						title,
						url,
						(icon_url == "") ? false : true,
						0,
						categories
					)
			);
		}
		return true;
	}

	public bool getCategoriesAndTags(Gee.LinkedList<feed> feeds, Gee.LinkedList<category> categories, Gee.LinkedList<tag> tags)
	{
		var msg = new feedhqMessage();
		string response = m_connection.send_get_request("tag/list", msg.get());
		if(response == "" || response == null)
			return false;

		var parser = new Json.Parser();
		try
		{
			parser.load_from_data(response, -1);
		}
		catch(Error e)
		{
			Logger.error("getCategoriesAndTags: Could not load message response");
			Logger.error(e.message);
			return false;
		}
		var root = parser.get_root().get_object();
		var array = root.get_array_member("tags");
		uint length = array.get_length();
		int orderID = 0;

		for (uint i = 0; i < length; i++)
		{
			Json.Object object = array.get_object_element(i);
			string id = object.get_string_member("id");
			int start = id.last_index_of_char('/') + 1;
			string title = id.substring(start);

			if(id.contains("/label/"))
			{
					categories.add(
						new category(
							id.replace("/", "_"),
							title,
							0,
							orderID,
							CategoryID.MASTER.to_string(),
							1
						)
					);
				++orderID;
			}
		}
		return true;
	}


	public int getTotalUnread()
	{
		var msg = new feedhqMessage();
		msg.add("output", "json");
		string response = m_connection.send_get_request("unread-count", msg.get());

		var parser = new Json.Parser();
		try{
			parser.load_from_data(response, -1);
		}
		catch (Error e) {
			Logger.error("getTotalUnread: Could not load message response");
			Logger.error(e.message);
		}

		var root = parser.get_root().get_object();
		var array = root.get_array_member("unreadcounts");
		uint length = array.get_length();
		int count = 0;

		for (uint i = 0; i < length; i++)
		{
			Json.Object object = array.get_object_element(i);
			if(object.get_string_member("id").has_prefix("feed/"))
			{
				count += (int)object.get_int_member("count");
			}

		}

		Logger.debug("getTotalUnread %i".printf(count));
		return count;
	}


	public string? updateArticles(Gee.LinkedList<string> ids, int count, string? continuation = null)
	{
		var msg = new feedhqMessage();
		msg.add("output", "json");
		msg.add("n", count.to_string());
		msg.add("s", "user/-/state/com.google/read");
		if(continuation != null)
			msg.add("c", continuation);

		string response = m_connection.send_get_request("stream/items/ids", msg.get());

		var parser = new Json.Parser();
		try
		{
			parser.load_from_data(response, -1);
		}
		catch (Error e) {
			Logger.error("updateArticles: Could not load message response");
			Logger.error(e.message);
		}

		var root = parser.get_root().get_object();
		var array = root.get_array_member("itemRefs");
		uint length = array.get_length();

		for (uint i = 0; i < length; i++)
		{
			Json.Object object = array.get_object_element(i);
			ids.add(object.get_string_member("id").replace(",", "_").replace("/", "~"));
		}

		if(root.has_member("continuation") && root.get_string_member("continuation") != "")
			return root.get_string_member("continuation");

		return null;
	}

	public string? getArticles(Gee.LinkedList<article> articles, int count, ArticleStatus whatToGet = ArticleStatus.ALL, string? continuation = null, string? tagID = null, string? feed_id = null)
	{
		var msg = new feedhqMessage();
		msg.add("output", "json");
		msg.add("n", count.to_string());

		if(whatToGet == ArticleStatus.UNREAD)
			msg.add("xt", "user/-/state/com.google/read");
		if(whatToGet == ArticleStatus.READ)
			msg.add("s", "user/-/state/com.google/read");
		else if(whatToGet == ArticleStatus.MARKED)
			msg.add("s", "user/-/state/com.google/starred");

		if(continuation != null)
			msg.add("c", continuation);

		string api_endpoint = "stream/contents";
		if(feed_id != null)
			api_endpoint += "/" + GLib.Uri.escape_string(feed_id.replace("_", "/"));
		else if(tagID != null)
			api_endpoint += "/" + GLib.Uri.escape_string(tagID.replace("_", "/"));
		string response = m_connection.send_get_request(api_endpoint, msg.get());

		var parser = new Json.Parser();
		try{
			parser.load_from_data(response, -1);
		}
		catch (Error e) {
			Logger.error("getCategoriesAndTags: Could not load message response");
			Logger.error(e.message);
		}

		var root = parser.get_root().get_object();
		var array = root.get_array_member("items");
		uint length = array.get_length();

		for (uint i = 0; i < length; i++)
		{

			Json.Object object = array.get_object_element(i);
			string id = object.get_string_member("id").replace(",", "_").replace("/", "~");
			string tagString = "";
			bool marked = false;
			bool read = false;
			var cats = object.get_array_member("categories");
			uint cat_length = cats.get_length();

			for (uint j = 0; j < cat_length; j++)
			{
				string cat = cats.get_string_element(j);
				if(cat.has_suffix("com.google/starred"))
					marked = true;
				else if(cat.has_suffix("com.google/read"))
					read = true;
				else if(cat.contains("/label/"))
					tagString += cat;
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
									object.get_object_member("origin").get_string_member("streamId").replace("/", "_"),
									read ? ArticleStatus.READ : ArticleStatus.UNREAD,
									marked ? ArticleStatus.MARKED : ArticleStatus.UNMARKED,
									"",
									"",
									"",
									new DateTime.from_unix_local(object.get_int_member("published")),
									-1,
									tagString,
									mediaString
							)
						);
		}

		if(root.has_member("continuation") && root.get_string_member("continuation") != "")
			return root.get_string_member("continuation");

		return null;
	}


	public void edidTag(string articleID, string tagID, bool add = true)
	{
		var msg = new feedhqMessage();
		msg.add("output", "json");

		if(add)
			msg.add("a", tagID);
		else
			msg.add("r", tagID);

		msg.add("i", articleID.replace("_", ",").replace("~", "/"));
		m_connection.send_post_request("edit-tag", msg.get());
	}

	public void markAsRead(string streamID)
	{
		var msg = new feedhqMessage();
		msg.add("output", "json");
		msg.add("s", streamID.replace("_", "/"));
		msg.add("ts", "%i000000".printf(Settings.state().get_int("last-sync")));
		Logger.debug(msg.get());
		m_connection.send_post_request("mark-all-as-read", msg.get());
	}

	public string composeTagID(string tagName)
	{
		return "user/%s/label/%s".printf(m_userID, tagName).replace("/", "_");
	}

	public void deleteTag(string tagID)
	{
		var msg = new feedhqMessage();
		msg.add("output", "json");
		msg.add("s", tagID);
		m_connection.send_post_request("disable-tag", msg.get());
	}

	public void renameTag(string tagID, string title)
	{
		var msg = new feedhqMessage();
		msg.add("output", "json");
		msg.add("s", tagID.replace("_", "/"));
		msg.add("dest", composeTagID(title).replace("_", "/"));
		m_connection.send_post_request("rename-tag", msg.get());
	}

	public void editSubscription(FeedHQSubscriptionAction action, string[] feedID, string? title = null, string? add = null, string? remove = null)
	{
		var msg = new feedhqMessage();
		msg.add("output", "json");

		switch(action)
		{
			case FeedHQSubscriptionAction.EDIT:
				msg.add("ac", "edit");
				break;
			case FeedHQSubscriptionAction.SUBSCRIBE:
				msg.add("ac", "subscribe");
				break;
			case FeedHQSubscriptionAction.UNSUBSCRIBE:
				msg.add("ac", "unsubscribe");
				break;
		}

		foreach(string s in feedID)
			msg.add("s", s.replace("_", "/"));

		if(title != null)
			msg.add("t", title);

		if(add != null && add != "")
			msg.add("a", add.replace("_", "/"));


		if(remove != null && remove != "")
			msg.add("r", remove.replace("_", "/"));

		Logger.debug(msg.get());
		m_connection.send_post_request("subscription/edit", msg.get());
	}

	public void import(string opml)
	{
		string response = m_connection.send_post_request("subscription/import", opml);
		Logger.debug("feedhq.import: " + response);
	}
}
