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

public class FeedReader.OldReaderAPI : GLib.Object {

	public enum OldreaderSubscriptionAction {
		EDIT,
		SUBSCRIBE,
		UNSUBSCRIBE
	}

	private OldReaderConnection m_connection;
	private OldReaderUtils m_utils;
	private string m_userID;

	public OldReaderAPI()
	{
		m_utils = new OldReaderUtils();
		m_connection = new OldReaderConnection();
	}

	public LoginResponse login()
	{
		if(m_utils.getAccessToken() == "")
		{
			var response = m_connection.getToken();
			if(response != SUCCESS)
				return response;
		}
		if(getUserID())
		{
			return LoginResponse.SUCCESS;
		}

		return LoginResponse.UNKNOWN_ERROR;
	}

	public bool ping() {
		return Utils.ping("https://theoldreader.com/");
	}

	private bool getUserID()
	{
		Logger.debug("getUserID: getting user info");
		string response = m_connection.send_get_request("user-info?output=json");
		var parser = new Json.Parser();
		try
		{
			parser.load_from_data(response, -1);
		}
		catch(Error e)
		{
			Logger.error("getUserID: Could not load message response");
			Logger.error(e.message);
			return false;
		}
		var root = parser.get_root().get_object();
		if(root.has_member("userId"))
		{
			m_userID = root.get_string_member("userId");
			m_utils.setUserID(m_userID);
			Logger.info("Oldreader: userID = " + m_userID);

			return true;
		}

		return false;
	}

	public bool getFeeds(Gee.LinkedList<feed> feeds)
	{

		string response = m_connection.send_get_request("subscription/list?output=json");
		if(response == "" || response == null)
			return false;
		var parser = new Json.Parser();
		try{
			parser.load_from_data(response, -1);
		}
		catch (Error e) {
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

			string feedID = object.get_string_member("id");
			string url = object.has_member("htmlUrl") ? object.get_string_member("htmlUrl") : object.get_string_member("url");
			string icon_url = object.has_member("iconUrl") ? object.get_string_member("iconUrl") : "";
			if(icon_url != "" && !m_utils.downloadIcon(feedID, "https:"+icon_url))
			{
				icon_url = "";
			}

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
				categories += object.get_array_member("categories").get_object_element(j).get_string_member("id");
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
		string response = m_connection.send_get_request("tag/list?output=json");
		if(response == "" || response == null)
			return false;
		var parser = new Json.Parser();
		try{
			parser.load_from_data(response, -1);
		}
		catch (Error e) {
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
							id,
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
		string response = m_connection.send_get_request("unread-count?output=json");

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
		var message_string = "n=" + count.to_string();
		message_string += "&xt=user/-/state/com.google/read";
		if(continuation != null)
			message_string += "&c=" + continuation;
		string response = m_connection.send_get_request("stream/items/ids?output=json&"+message_string);

		var parser = new Json.Parser();
		try{
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
			ids.add(object.get_string_member("id"));
		}

		if(root.has_member("continuation") && root.get_string_member("continuation") != "")
			return root.get_string_member("continuation");

		return null;
	}

	public string? getArticles(Gee.LinkedList<article> articles, int count, ArticleStatus whatToGet = ArticleStatus.ALL, string? continuation = null, string? tagID = null, string? feed_id = null)
	{
		var message_string = "n=" + count.to_string();

		if(whatToGet == ArticleStatus.UNREAD)
			message_string += "&xt=user/-/state/com.google/read";
		if(whatToGet == ArticleStatus.READ)
			message_string += "&s=user/-/state/com.google/read";
		else if(whatToGet == ArticleStatus.MARKED)
			message_string += "&s=user/-/state/com.google/starred";

			message_string += "&c=" + continuation;


		string api_endpoint = "stream/contents";
		if(feed_id != null)
			api_endpoint += "/" + GLib.Uri.escape_string(feed_id);
		else if(tagID != null)
			api_endpoint += "/" + GLib.Uri.escape_string(tagID);
		string response = m_connection.send_get_request(api_endpoint+"?output=json&"+message_string);

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
			string id = object.get_string_member("id");
			id = id.substring(id.last_index_of_char('/')+1);
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
				else if(cat.contains("/label/") && dbDaemon.get_default().getTagName(cat) != null)
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
									object.get_object_member("origin").get_string_member("streamId"),
									read ? ArticleStatus.READ : ArticleStatus.UNREAD,
									marked ? ArticleStatus.MARKED : ArticleStatus.UNMARKED,
									object.get_object_member("summary").get_string_member("content"),
									"",
									(object.get_string_member("author") == "") ? null : object.get_string_member("author"),
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
		var message_string = "";
		if(add)
			message_string += "a=";
		else
			message_string += "r=";

		message_string += tagID;
		message_string += "&i=" + articleID;
		m_connection.send_post_request("edit-tag?output=json", message_string);
	}

	public void markAsRead(string? streamID = null)
	{
		var settingsState = new GLib.Settings("org.gnome.feedreader.saved-state");
		string message_string = "s=%s&ts=%i000000".printf(streamID, settingsState.get_int("last-sync"));
		m_connection.send_post_request("mark-all-as-read?output=json", message_string);
	}

	public string composeTagID(string tagName)
	{
		return "user/%s/label/%s".printf(m_userID, tagName);
	}

	public void deleteTag(string tagID)
	{
		var message_string = "s=" + tagID;
		m_connection.send_post_request("disable-tag?output=json", message_string);
	}

	public void renameTag(string tagID, string title)
	{
		var message_string = "s=" + tagID;
		message_string += "&dest=" + composeTagID(title);
		m_connection.send_post_request("rename-tag?output=json", message_string);
	}

	public void editSubscription(OldreaderSubscriptionAction action, string[] feedID, string? title = null, string? add = null, string? remove = null)
	{
		var message_string = "ac=";

		switch(action)
		{
			case OldreaderSubscriptionAction.EDIT:
				message_string += "edit";
				break;
			case OldreaderSubscriptionAction.SUBSCRIBE:
				message_string += "subscribe";
				break;
			case OldreaderSubscriptionAction.UNSUBSCRIBE:
				message_string += "unsubscribe";
				break;
		}

		foreach(string s in feedID)
			message_string += "&s=" + s;

		if(title != null)
			message_string += "&t=" + title;

		if(add != null)
			message_string += "&a=" + add;

		if(remove != null)
			message_string += "&r=" + remove;


		m_connection.send_post_request("subscription/edit?output=json", message_string);
	}
}
