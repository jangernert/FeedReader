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

// TODO: Make a general-purpose HttpClient module with these errors
public errordomain FeedbinError {
	INVALID_FORMAT,
	MULTIPLE_CHOICES,
	NO_CONNECTION,
	NOT_AUTHORIZED,
	NOT_FOUND,
	UNKNOWN_ERROR
}

public class FeedbinAPI : Object {
	private const string BASE_URI = "https://api.feedbin.com/v2/";

	private Soup.Session m_session;
	public string username { get ; set; }
	public string password { get ; set; }

	public FeedbinAPI(string username, string password, string? user_agent = null)
	{
		this.username = username;
		this.password = password;
		m_session = new Soup.Session();

		if(user_agent != null)
			m_session.user_agent = user_agent;

		m_session.authenticate.connect((msg, auth, retrying) => {
			if(!retrying)
				auth.authenticate(this.username, this.password);
		});
	}

	private Soup.Message request(string method, string path, string? input = null) throws FeedbinError
	{
		var message = new Soup.Message(method, BASE_URI+path);

		if(method == "POST" || method == "PUT")
			message.request_headers.append("Content-Type", "application/json; charset=utf-8");

		if(input != null)
			message.request_body.append_take(input.data);

		m_session.send_message(message);
		var status = message.status_code;
		if(status < 200 || status >= 400)
		{
			switch(status)
			{
			case Soup.Status.CANT_RESOLVE:
			case Soup.Status.CANT_RESOLVE_PROXY:
			case Soup.Status.CANT_CONNECT:
			case Soup.Status.CANT_CONNECT_PROXY:
				throw new FeedbinError.NO_CONNECTION(@"Connection to $BASE_URI failed");
			case Soup.Status.UNAUTHORIZED:
				throw new FeedbinError.NOT_AUTHORIZED(@"Not authorized to $method $path");
			case Soup.Status.NOT_FOUND:
				throw new FeedbinError.NOT_FOUND(@"$method $path not found");
			}
			string phrase = Soup.Status.get_phrase(status);
			throw new FeedbinError.UNKNOWN_ERROR(@"Unexpected status $status ($phrase) for $method $path");
		}
		return message;
	}

	// TODO: Move to DateUtils
	private static DateTime string_to_datetime(string s) throws FeedbinError
	{
		var time = TimeVal();
		if(!time.from_iso8601(s))
			throw new FeedbinError.INVALID_FORMAT(@"Expected date but got $s");
		return new DateTime.from_timeval_utc(time);
	}

	// TODO: JSON utils?
	private static DateTime get_datetime_member(Json.Object obj, string name) throws FeedbinError
	{
		var s = obj.get_string_member(name);
		return string_to_datetime(s);
	}

	private Soup.Message post_request(string path, string input) throws FeedbinError
	{
		return request("POST", path, input);
	}

	private Soup.Message delete_request(string path, string? input = null) throws FeedbinError
	{
		return request("DELETE", path, input);
	}

	private Soup.Message get_request(string path) throws FeedbinError
	{
		return request("GET", path);
	}

	private Json.Node get_json(string path) throws FeedbinError
	{
		string content;
		var response = get_request(path);
		content = (string)response.response_body.flatten().data;
		if(content == null)
		{
			throw new FeedbinError.INVALID_FORMAT(@"GET $path returned no content but expected JSON");
		}

		var parser = new Json.Parser();
		try
		{
			parser.load_from_data(content, -1);
		}
		catch (Error e)
		{
			throw new FeedbinError.INVALID_FORMAT(@"GET $path returned invalid JSON: " + e.message + "\nContent is: $content");
		}
		return parser.get_root();
	}

	private Soup.Message post_json_object(string path, Json.Object obj) throws FeedbinError
	{
		var root = new Json.Node(Json.NodeType.OBJECT);
		root.set_object(obj);

		var gen = new Json.Generator();
		gen.set_root(root);
		var data = gen.to_data(null);

		return post_request(path, data);
	}

	public bool login() throws FeedbinError
	{
		try
		{
			var res = get_request("authentication.json");
			return res.status_code == Soup.Status.OK;
		}
		catch(FeedbinError.NOT_AUTHORIZED e)
		{
			return false;
		}
	}

	public struct Subscription {
		int64 id;
		DateTime created_at;
		int64 feed_id;
		string? title;
		string? feed_url;
		string? site_url;

		public Subscription.from_json(Json.Object object) throws FeedbinError
		{
			id = object.get_int_member("id");
			created_at = get_datetime_member(object, "created_at");
			feed_id = object.get_int_member("feed_id");
			title = object.get_string_member("title");
			feed_url = object.get_string_member("feed_url");
			site_url = object.get_string_member("site_url");
		}
	}

	public Subscription get_subscription(int64 subscription_id) throws FeedbinError
	{
		var root = get_json(@"subscriptions/$subscription_id.json");
		return Subscription.from_json(root.get_object());
	}

	public Gee.List<Subscription?> get_subscriptions() throws FeedbinError
	{
		var root = get_json("subscriptions.json");
		var subscriptions = new Gee.ArrayList<Subscription?>();
		var array = root.get_array();
		for(var i = 0; i < array.get_length(); ++i)
		{
			var node = array.get_object_element(i);
			subscriptions.add(Subscription.from_json(node));
		}
		return subscriptions;
	}

	public void delete_subscription(int64 subscription_id) throws FeedbinError
	{
		delete_request(@"subscriptions/$subscription_id.json");
	}

	public int64 add_subscription(string url) throws FeedbinError
	{
		Json.Object object = new Json.Object();
		object.set_string_member("feed_url", url);

		var response = post_json_object("subscriptions.json", object);
		if(response.status_code == 300)
			throw new FeedbinError.MULTIPLE_CHOICES("Site $url has multiple feeds to subscribe to");

		var location = response.response_headers.get_one("Location");
		if(location == null) {
			throw new FeedbinError.UNKNOWN_ERROR(@"Feedbin API error adding feed $url: no Location header");
		}

		var last_slash = location.last_index_of_char('/');
		location = location.substring(last_slash + 1);
		var last_dot = location.last_index_of_char('.');
		location = location.substring(0, last_dot);
		return int64.parse(location);
	}

	public void rename_subscription(int64 subscription_id, string title) throws FeedbinError
	{
		Json.Object object = new Json.Object();
		object.set_string_member("title", title);
		post_json_object(@"subscriptions/$subscription_id/update.json", object);
	}

	public struct Tagging
	{
		int64 id;
		int64 feed_id;
		string name;

		public Tagging.from_json(Json.Object object)
		{
			id = object.get_int_member("id");
			feed_id = object.get_int_member("feed_id");
			name = object.get_string_member("name");
		}
	}

	public void add_tagging(int64 feed_id, string tag_name) throws FeedbinError
	{
		Json.Object object = new Json.Object();
		object.set_int_member("feed_id", feed_id);
		object.set_string_member("name", tag_name);

		post_json_object("taggings.json", object);
		// TODO: Return id
	}

	public void delete_tagging(int64 tagging_id) throws FeedbinError
	{
		delete_request(@"taggings/$tagging_id.json");
	}

	public Gee.List<Tagging?> get_taggings() throws FeedbinError
	{
		var root = get_json("taggings.json");
		var taggings = new Gee.ArrayList<Tagging?>();
		var array = root.get_array();
		for(var i = 0; i < array.get_length(); ++i)
		{
			var object = array.get_object_element(i);
			taggings.add(Tagging.from_json(object));
		}
		return taggings;
	}

	public struct Entry
	{
		int64 id;
		int64 feed_id;
		string? title;
		string? url;
		string? author;
		string? content;
		string? summary;
		DateTime published;
		DateTime created_at;

		public Entry.from_json(Json.Object object) throws FeedbinError
		{
			id = object.get_int_member("id");
			feed_id = object.get_int_member("feed_id");
			title = object.get_string_member("title");
			url = object.get_string_member("url");
			author = object.get_string_member("author");
			content = object.get_string_member("content");
			summary = object.get_string_member("summary");
			published = get_datetime_member(object, "published");
			created_at = get_datetime_member(object, "created_at");
		}
	}

	public Gee.List<Entry?> get_entries(int page, bool only_starred, DateTime? since, int64? feed_id = null) throws FeedbinError
	{
		string starred = only_starred ? "true" : "false";
		string path = @"entries.json?per_page=100&page=$page&starred=$starred&include_enclosure=true";
		if(since != null)
		{
			var t = GLib.TimeVal();
			if(since.to_timeval(out t))
			{
				path += "&since=" + t.to_iso8601();
			}
		}

		if(feed_id != null)
			path = @"feeds/$feed_id/$path";

		Json.Node root;
		try
		{
			root = get_json(path);
		}
		catch(FeedbinError.NOT_FOUND e)
		{
			return Gee.List.empty<Entry?>();
		}

		var entries = new Gee.ArrayList<Entry?>();
		var array = root.get_array();
		for(var i = 0; i < array.get_length(); ++i)
		{
			var object = array.get_object_element(i);
			entries.add(Entry.from_json(object));
		}
		return entries;
	}

	private Gee.Set<int64?> get_x_entries(string path) throws FeedbinError
	{
		var root = get_json(path);
		var array = root.get_array();
		// We have to set the hash function here manually or contains() won't
		// work right -- presumably because it's trying to do pointer comparisons?
		var ids = new Gee.HashSet<int64?>(
			(n) => { return int64_hash(n); },
			(a, b) => { return int64_equal(a, b); });
		for(var i = 0; i < array.get_length(); ++i)
		{
			ids.add(array.get_int_element(i));
		}
		return ids;
	}

	public Gee.Set<int64?> get_unread_entries() throws FeedbinError
	{
		return get_x_entries("unread_entries.json");
	}

	public Gee.Set<int64?> get_starred_entries() throws FeedbinError
	{
		return get_x_entries("starred_entries.json");
	}

	private void set_entries_status(string type, Gee.Collection<int64?> entry_ids, bool create) throws FeedbinError
	{
		Json.Array array = new Json.Array();
		foreach(var id in entry_ids)
		{
			array.add_int_element(id);
		}

		Json.Object object = new Json.Object();
		object.set_array_member(type, array);

		string path = create ? @"$type.json" : @"$type/delete.json";
		post_json_object(path, object);
	}

	public void set_entries_read(Gee.Collection<int64?> entry_ids, bool read) throws FeedbinError
	{
		set_entries_status("unread_entries", entry_ids, !read);
	}

	public void set_entries_starred(Gee.Collection<int64?> entry_ids, bool starred) throws FeedbinError
	{
		set_entries_status("starred_entries", entry_ids, starred);
	}

}
