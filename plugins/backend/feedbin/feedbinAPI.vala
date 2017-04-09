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

public class FeedReader.feedbinAPI : Object {

	private feedbinConnection m_connection;
	private feedbinUtils m_utils;

	public feedbinAPI()
	{
		m_connection = new feedbinConnection();
		m_utils = new feedbinUtils();
	}

	public LoginResponse login()
	{
		Logger.debug("feedbin backend: login");

		if(!Utils.ping("https://feedbin.com/"))
			return LoginResponse.NO_CONNECTION;

		return LoginResponse.SUCCESS;
	}

	public bool getSubscriptionList(Gee.LinkedList<feed> feeds)
	{
		var response = m_connection.getRequest("subscriptions.json");

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
		Json.Array array = parser.get_root().get_array();

		for (int i = 0; i < array.get_length (); i++)
		{
			Json.Object object = array.get_object_element(i);

			string url = object.get_string_member("site_url");
			string id = object.get_int_member("feed_id").to_string();
			string xmlURL = object.get_string_member("feed_url");

			string title = "No Title";
			if(object.has_member("title"))
			{
				title = object.get_string_member("title");
			}
			else
			{
				title = Utils.URLtoFeedName(url);
			}

			feeds.add(
				new feed(
					id,
					title,
					url,
					Utils.downloadIcon(id, url),
					0,
					{ "0" },
					xmlURL)
			);
		}

		return true;
	}

	public bool getTaggings(Gee.LinkedList<category> categories, Gee.LinkedList<feed> feeds)
	{
		var response = m_connection.getRequest("taggings.json");

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
		Json.Array array = parser.get_root().get_array();

		for (int i = 0; i < array.get_length (); i++)
		{
			Json.Object object = array.get_object_element(i);

			string id = "catID%i".printf(i);
			string name = object.get_string_member("name");
			string feedID = object.get_int_member("feed_id").to_string();

			string? id2 = m_utils.catExists(categories, name);

			if(id2 == null)
			{
				categories.add(
					new category (
						id,
						name,
						0,
						i+1,
						CategoryID.MASTER.to_string(),
						1
					)
				);

				m_utils.addFeedToCat(feeds, feedID, id);
			}
			else
			{
				m_utils.addFeedToCat(feeds, feedID, id2);
			}


		}

		return true;
	}



	public int getEntries(Gee.LinkedList<article> articles, int page, bool starred, DateTime? timestamp, string? feedID = null)
	{
		string request = "entries.json?per_page=100";
		request += "&page=%i".printf(page);
		request += "&starred=%s".printf(starred ? "true" : "false");
		if(timestamp != null)
		{
			var t = GLib.TimeVal();
			if(timestamp.to_timeval(out t))
			{
				request += "&since=%s".printf(t.to_iso8601());
			}
		}

		request += "&include_enclosure=true";

		if(feedID != null)
			request = "feeds/%s/%s".printf(feedID, request);

		Logger.debug(request);

		string response = m_connection.getRequest(request).data;

		var parser = new Json.Parser();
		try
		{
			parser.load_from_data(response, -1);
		}
		catch(Error e)
		{
			Logger.error("getEntries: Could not load message response");
			Logger.error(e.message);
			Logger.error(response);
		}

		var root = parser.get_root();

		if(root.get_node_type() != Json.NodeType.ARRAY)
		{
			Logger.error(response);
			return 0;
		}

		var array = root.get_array();
		uint length = array.get_length();

		Logger.debug("article count: %u".printf(length));

		for(uint i = 0; i < length; i++)
		{
			Json.Object object = array.get_object_element(i);
			string id = object.get_int_member("id").to_string();

			var time = new GLib.DateTime.now_local();

			var t = GLib.TimeVal();
			if(t.from_iso8601(object.get_string_member("published")))
			{
				time = new DateTime.from_timeval_local(t);
			}

			articles.add(new article(
								id,
								object.get_string_member("title"),
								object.get_string_member("url"),
								object.get_int_member("feed_id").to_string(),
								ArticleStatus.READ,
								ArticleStatus.UNMARKED,
								object.get_string_member("content"),
								object.get_string_member("summary"),
								object.get_string_member("author"),
								time,
								-1,
								"",
								""
							)
						);
		}

		return (int)length;
	}

	public Gee.LinkedList<string> unreadEntries()
	{
		string response = m_connection.getRequest("unread_entries.json").data;
		response = response.substring(1, response.length-2);
		var a = response.split(",");
		var ids = new Gee.LinkedList<string>();

		foreach(string s in a)
		{
			ids.add(s);
		}

		return ids;
	}

	public Gee.LinkedList<string> starredEntries()
	{
		string response = m_connection.getRequest("starred_entries.json").data;
		response = response.substring(1, response.length-2);
		var a = response.split(",");
		var ids = new Gee.LinkedList<string>();

		foreach(string s in a)
		{
			ids.add(s);
		}

		return ids;
	}

	public void createUnreadEntries(string articleIDs, bool read)
	{
		var ids = articleIDs.split(",");
		Json.Array array = new Json.Array();
		foreach(string id in ids)
		{
			array.add_int_element(int64.parse(id));
		}

		Json.Object object = new Json.Object();
		object.set_array_member("unread_entries", array);

		var root = new Json.Node(Json.NodeType.OBJECT);
		root.set_object(object);

		var gen = new Json.Generator();
		gen.set_root(root);
		string json = gen.to_data(null);

		if(!read)
			m_connection.postRequest("unread_entries.json", json);
		else
			m_connection.deleteRequest("unread_entries.json", json);
	}

	public void createStarredEntries(string articleID, bool starred)
	{
		Json.Array array = new Json.Array();
		array.add_int_element(int64.parse(articleID));

		Json.Object object = new Json.Object();
		object.set_array_member("starred_entries", array);

		var root = new Json.Node(Json.NodeType.OBJECT);
		root.set_object(object);

		var gen = new Json.Generator();
		gen.set_root(root);
		string json = gen.to_data(null);

		if(starred)
			m_connection.postRequest("starred_entries.json", json);
		else
			m_connection.deleteRequest("starred_entries.json", json);
	}

	public void deleteFeed(string feedID)
	{
		m_connection.deleteRequest("subscriptions/%s.json".printf(feedID));
	}

	public void renameFeed(string feedID, string title)
	{
		Json.Object object = new Json.Object();
		object.set_string_member("title", title);

		var root = new Json.Node(Json.NodeType.OBJECT);
		root.set_object(object);

		var gen = new Json.Generator();
		gen.set_root(root);
		string json = gen.to_data(null);

		Logger.debug(json);

		var response = m_connection.postRequest("subscriptions/%s/update.json".printf(feedID), json);

		Logger.debug("subscriptions/%s/update.json".printf(feedID));
		Logger.debug(response.data);
	}

}
