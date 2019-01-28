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

public class FeedReader.bazquxAPI : GLib.Object {

public enum bazquxSubscriptionAction {
	EDIT,
	SUBSCRIBE,
	UNSUBSCRIBE
}

private bazquxConnection m_connection;
private bazquxUtils m_utils;
private string m_userID;

public bazquxAPI(bazquxUtils utils)
{
	m_utils = utils;
	m_connection = new bazquxConnection(utils);
}

public LoginResponse login()
{
	if(m_utils.getAccessToken() == "")
	{
		var result = m_connection.getToken();
		if(getUserID())
			return result;
	}
	else if(getUserID())
		return LoginResponse.SUCCESS;

	return LoginResponse.UNKNOWN_ERROR;
}

public bool ping()
{
	return m_connection.ping();
}

private bool getUserID()
{
	Logger.debug("getUserID: getting user info");
	var msg = new bazquxMessage();
	msg.add("output", "json");
	var response = m_connection.send_get_request("user-info", msg.get());

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
	if(root.has_member("userId"))
	{
		m_userID = root.get_string_member("userId");
		m_utils.setUserID(m_userID);
		Logger.info("bazqux: userID = " + m_userID);

		return true;
	}

	return false;
}

public bool getFeeds(Gee.List<Feed> feeds)
{
	var msg = new bazquxMessage();
	msg.add("output", "json");
	var response = m_connection.send_get_request("subscription/list", msg.get());

	if(response.status != 200)
		return false;

	Logger.debug(response.data);
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
	var root = parser.get_root().get_object();
	var array = root.get_array_member("subscriptions");
	uint length = array.get_length();

	for (uint i = 0; i < length; i++)
	{
		Json.Object object = array.get_object_element(i);

		string feedID = object.get_string_member("id");
		string url = object.has_member("htmlUrl") ? object.get_string_member("htmlUrl") : object.get_string_member("url");
		string? icon_url = object.get_string_member("iconUrl");

		uint catCount = object.get_array_member("categories").get_length();
		var categories = new Gee.ArrayList<string>();
		for(uint j = 0; j < catCount; ++j)
		{
			categories.add(object.get_array_member("categories").get_object_element(j).get_string_member("id"));
		}
		feeds.add(
			new Feed(
				feedID,
				object.get_string_member("title"),
				url,
				0,
				categories,
				icon_url
				)
			);
	}
	return true;
}

public bool getCategoriesAndTags(Gee.List<Feed> feeds, Gee.List<Category> categories, Gee.List<Tag> tags)
{
	var msg = new bazquxMessage();
	msg.add("output", "json");
	var response = m_connection.send_get_request("tag/list", msg.get());

	if(response.status != 200)
		return false;

	var parser = new Json.Parser();
	try
	{
		parser.load_from_data(response.data, -1);
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

	var db = DataBase.readOnly();
	for (uint i = 0; i < length; i++)
	{
		Json.Object object = array.get_object_element(i);
		string id = object.get_string_member("id");
		int start = id.last_index_of_char('/') + 1;
		string title = id.substring(start);

		if(id.contains("/label/"))
		{
			if(m_utils.tagIsCat(id, feeds))
			{
				categories.add(
					new Category(
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
			else
			{
				tags.add(
					new Tag(
						id,
						title,
						db.getTagColor()
						)
					);
			}
		}
	}
	return true;
}


public int getTotalUnread()
{
	var msg = new bazquxMessage();
	msg.add("output", "json");
	var response = m_connection.send_get_request("unread-count", msg.get());

	if(response.status != 200)
		return 0;

	var parser = new Json.Parser();
	try
	{
		parser.load_from_data(response.data, -1);
	}
	catch(Error e)
	{
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


public string? updateArticles(Gee.List<string> ids, int count, string? continuation = null)
{
	var msg = new bazquxMessage();
	msg.add("output", "json");
	msg.add("n", count.to_string());
	msg.add("xt", "user/-/state/com.google/read");
	if(continuation != null)
		msg.add("c", continuation);

	var response = m_connection.send_get_request("stream/items/ids", msg.get());

	if(response.status != 200)
		return null;

	var parser = new Json.Parser();
	try
	{
		parser.load_from_data(response.data, -1);
	}
	catch(Error e)
	{
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

public string? getArticles(Gee.List<Article> articles, int count, ArticleStatus whatToGet = ArticleStatus.ALL, string? continuation = null, string? tagID = null, string? feed_id = null)
{
	var msg = new bazquxMessage();
	msg.add("output", "json");
	msg.add("n", count.to_string());

	if(whatToGet == ArticleStatus.UNREAD)
		msg.add("xt", "user/-/state/com.google/read");
	if(whatToGet == ArticleStatus.READ)
		msg.add("s", "user/-/state/com.google/read");
	else if(whatToGet == ArticleStatus.MARKED)
		msg.add("s", "user/-/state/com.google/starred");

	if( continuation != null )
		msg.add("c", continuation);

	string api_endpoint = "stream/contents";
	if(feed_id != null)
		api_endpoint += "/" + feed_id;
	else if(tagID != null)
		api_endpoint += "/" + tagID;
	var response = m_connection.send_get_request(api_endpoint, msg.get());

	if(response.status != 200)
		return null;

	var parser = new Json.Parser();
	try
	{
		parser.load_from_data(response.data, -1);
	}
	catch(Error e)
	{
		Logger.error("getArticles: Could not load message response");
		Logger.error(e.message);
	}

	var root = parser.get_root().get_object();
	var array = root.get_array_member("items");
	uint length = array.get_length();

	var db = DataBase.readOnly();
	for (uint i = 0; i < length; i++)
	{
		Json.Object object = array.get_object_element(i);
		string id = object.get_string_member("id");
		id = id.substring(id.last_index_of_char('/') + 1);
		bool marked = false;
		bool read = false;
		var cats = object.get_array_member("categories");
		uint cat_length = cats.get_length();

		var tags = new Gee.ArrayList<string>();
		for (uint j = 0; j < cat_length; j++)
		{
			string cat = cats.get_string_element(j);
			if(cat.has_suffix("com.google/starred"))
				marked = true;
			else if(cat.has_suffix("com.google/read"))
				read = true;
			else if(cat.contains("/label/") && db.getTagName(cat) != null)
				tags.add(cat);
		}

		var enclosures = new Gee.ArrayList<Enclosure>();
		if(object.has_member("enclosure"))
		{
			var attachments = object.get_array_member("enclosure");

			uint mediaCount = 0;
			if(attachments != null)
				mediaCount = attachments.get_length();

			for(int j = 0; j < mediaCount; ++j)
			{
				var attachment = attachments.get_object_element(j);

				enclosures.add(
					new Enclosure(id, attachment.get_string_member("href"),
					              EnclosureType.from_string(attachment.get_string_member("type")))
					);
			}
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
				     object.get_string_member("author"),
				     new DateTime.from_unix_local(object.get_int_member("published")),
				     -1,
				     tags,
				     enclosures
				     )
		             );
	}

	if(root.has_member("continuation") && root.get_string_member("continuation") != "")
		return root.get_string_member("continuation");

	return null;
}


public void edidTag(string articleID, string tagID, bool add = true)
{
	var msg = new bazquxMessage();
	msg.add("output", "json");

	if(add)
		msg.add("a", tagID);
	else
		msg.add("r", tagID);

	msg.add("i", "tag:google.com,2005:reader/item/" + articleID);
	m_connection.send_post_request("edit-tag", msg.get());
}

public void markAsRead(string? streamID = null)
{
	var msg = new bazquxMessage();
	msg.add("output", "json");
	msg.add("s", streamID);
	msg.add("ts", "%i000000".printf(Settings.state().get_int("last-sync")));
	m_connection.send_post_request("mark-all-as-read", msg.get());
}

public string composeTagID(string tagName)
{
	return "user/%s/label/%s".printf(m_userID, tagName);
}

public void deleteTag(string tagID)
{
	var msg = new bazquxMessage();
	msg.add("output", "json");
	msg.add("s", tagID);
	m_connection.send_post_request("disable-tag", msg.get());
}

public void renameTag(string tagID, string title)
{
	var msg = new bazquxMessage();
	msg.add("output", "json");
	msg.add("s", tagID);
	msg.add("dest", composeTagID(title));
	m_connection.send_post_request("rename-tag", msg.get());
}

public bool editSubscription(bazquxSubscriptionAction action, string feedID, string? title = null, string? add = null, string? remove = null)
{
	var msg = new bazquxMessage();
	msg.add("output", "json");

	switch(action)
	{
	case bazquxSubscriptionAction.EDIT:
		msg.add("ac", "edit");
		break;
	case bazquxSubscriptionAction.SUBSCRIBE:
		msg.add("ac", "subscribe");
		break;
	case bazquxSubscriptionAction.UNSUBSCRIBE:
		msg.add("ac", "unsubscribe");
		break;
	}

	msg.add("s", feedID);

	if(title != null)
		msg.add("t", title);

	if(add != null)
		msg.add("a", add);

	if(remove != null)
		msg.add("r", remove);


	var response = m_connection.send_post_request("subscription/edit", msg.get());

	return response.status == 200;
}
}
