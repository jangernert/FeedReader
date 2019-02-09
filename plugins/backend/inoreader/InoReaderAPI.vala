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

public class FeedReader.InoReaderAPI : GLib.Object {

public enum InoSubscriptionAction {
	EDIT,
	SUBSCRIBE,
	UNSUBSCRIBE
}

private InoReaderConnection m_connection;
private InoReaderUtils m_utils;
private string m_userID;

public InoReaderAPI (InoReaderUtils utils)
{
	m_utils = utils;
	m_connection = new InoReaderConnection(m_utils);
}


public LoginResponse login()
{
	if(m_utils.getAccessToken() == "")
	{
		m_connection.getToken();
	}

	if(getUserID())
	{
		return LoginResponse.SUCCESS;
	}

	return LoginResponse.UNKNOWN_ERROR;
}

public bool ping() {
	return Utils.ping("http://www.inoreader.com/");
}

private bool getUserID()
{
	var response = m_connection.send_request("user-info");

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
		Logger.info("Inoreader: userID = " + m_userID);

		if(root.has_member("userEmail"))
			m_utils.setEmail(root.get_string_member("userEmail"));

		if(root.has_member("userName"))
			m_utils.setUser(root.get_string_member("userName"));

		return true;
	}

	return false;
}

public bool getFeeds(Gee.List<Feed> feeds)
{
	var response = m_connection.send_request("subscription/list");

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
	var root = parser.get_root().get_object();
	var array = root.get_array_member("subscriptions");
	uint length = array.get_length();

	for (uint i = 0; i < length; i++)
	{
		Json.Object object = array.get_object_element(i);

		string feedID = object.get_string_member("id");
		string url = object.has_member("htmlUrl") ? object.get_string_member("htmlUrl") : object.get_string_member("url");

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
				object.get_string_member("iconUrl"),
				object.get_string_member("url")
				)
			);
	}

	return true;
}

public bool getCategoriesAndTags(Gee.List<Feed> feeds, Gee.List<Category> categories, Gee.List<Tag> tags)
{
	var response = m_connection.send_request("tag/list");

	if(response.status != 200)
		return false;

	var parser = new Json.Parser();
	try{
		parser.load_from_data(response.data, -1);
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

			++orderID;
		}
	}
	return true;
}


public int getTotalUnread()
{
	var response = m_connection.send_request("unread-count");

	if(response.status != 200)
		return 0;

	var parser = new Json.Parser();
	try{
		parser.load_from_data(response.data, -1);
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


public string? updateArticles(Gee.List<string> ids, int count, string? continuation = null)
{
	var message_string = "n=" + count.to_string();
	message_string += "&xt=user/-/state/com.google/read";
	if(continuation != null)
		message_string += "&c=" + continuation;
	var response = m_connection.send_request("stream/items/ids", message_string);

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
	if(!root.has_member("itemRefs"))
		return null;
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
	var message_string = "n=" + count.to_string();

	if(whatToGet == ArticleStatus.UNREAD)
		message_string += "&xt=user/-/state/com.google/read";
	if(whatToGet == ArticleStatus.READ)
		message_string += "&it=user/-/state/com.google/read";
	else if(whatToGet == ArticleStatus.MARKED)
		message_string += "&it=user/-/state/com.google/starred";

	if(continuation != null)
		message_string += "&c=" + continuation;


	string api_endpoint = "stream/contents";
	if(feed_id != null)
		api_endpoint += "/" + GLib.Uri.escape_string(feed_id);
	else if(tagID != null)
		api_endpoint += "/" + GLib.Uri.escape_string(tagID);
	var response = m_connection.send_request(api_endpoint, message_string);

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
		id = id.substring(id.last_index_of_char('/')+1);
		var tags = new Gee.ArrayList<string>();
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
				     null,
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


public void edidTag(string articleIDs, string tagID, bool add = true)
{
	var message_string = "";
	if(add)
		message_string += "a=";
	else
		message_string += "r=";

	message_string += tagID;

	var id_array = articleIDs.split(",");
	foreach(string id in id_array)
	{
		message_string += "&i=" + id;
	}
	m_connection.send_request("edit-tag", message_string);
}

public void markAsRead(string? streamID = null)
{
	var settingsState = new GLib.Settings("org.gnome.feedreader.saved-state");
	string message_string = "s=%s&ts=%i".printf(streamID, settingsState.get_int("last-sync"));
	Logger.debug(message_string);
	m_connection.send_request("mark-all-as-read", message_string);
}

public string composeTagID(string tagName)
{
	return "user/%s/label/%s".printf(m_userID, tagName);
}

public void deleteTag(string tagID)
{
	var message_string = "s=" + tagID;
	m_connection.send_request("disable-tag", message_string);
}

public void renameTag(string tagID, string title)
{
	var message_string = "s=" + tagID;
	message_string += "&dest=" + composeTagID(title);
	m_connection.send_request("rename-tag", message_string);
}

public bool editSubscription(InoSubscriptionAction action, string[] feedID, string? title, string? add, string? remove)
{
	var message_string = "ac=";

	switch(action)
	{
	case InoSubscriptionAction.EDIT:
		message_string += "edit";
		break;
	case InoSubscriptionAction.SUBSCRIBE:
		message_string += "subscribe";
		break;
	case InoSubscriptionAction.UNSUBSCRIBE:
		message_string += "unsubscribe";
		break;
	}

	foreach(string s in feedID)
		message_string += "&s=" + GLib.Uri.escape_string(s);

	if(title != null)
		message_string += "&t=" + title;

	if(add != null)
		message_string += "&a=" + add;

	if(remove != null)
		message_string += "&r=" + remove;


	return m_connection.send_request("subscription/edit", message_string).status == 200;
}
}
