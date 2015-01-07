public class FeedlyAPI : Object {

    public FeedlyConnection connection {get; private set; }
    
    public string token { get; private set; }
    public string user_id { get; private set; }
    private Profile profile = null;
    private static FeedlyAPI instance;
    public Gee.HashMap<string,int> markers { get; private set; }

    FeedlyAPI() {
    	string devel_token = "AhHjs057ImEiOiJGZWVkbHkgRGV2ZWxvcGVyIiwiZSI6MTQyODM3Njc2MDUwMSwiaSI6IjliN2ZkYjg3LTljYWUtNGIyNy05NGQyLTEwMGExMTM4YTg2OSIsInAiOjYsInQiOjEsInYiOiJwcm9kdWN0aW9uIiwidyI6IjIwMTQuMjciLCJ4Ijoic3RhbmRhcmQifQ:feedlydev";
        this.connection = new FeedlyConnection (devel_token);
        this.token = devel_token;  
        this.user_id = get_profile ().id;     
    }

    // first call get_api_with_token!
    public static FeedlyAPI get_api () {
        return instance;
    }

    public static FeedlyAPI get_api_with_token() {
        if (instance == null) {
            try {
                instance = new FeedlyAPI ();
            } catch (Error e) {
                error ("Failed to connect to Feedly!");
            }
        }
        return instance;
    }

     /** Returns a user profile */
    public Profile get_profile () throws Error {
        // cache it since it probably not get updated during run
        if (profile == null || profile.id == null || profile.id == "") {

            string response = connection.send_get_request_to_feedly ("/v3/profile/");

            var parser = new Json.Parser ();
            parser.load_from_data (response, -1);
            Json.Object object = parser.get_root ().get_object();
            this.profile = Profile.from_json_object(object);           
        }
        return profile;
    }

    public Gee.ArrayList<feedlyCategory> get_categories () throws Error {
        Gee.ArrayList<feedlyCategory> categories = new Gee.ArrayList<feedlyCategory> ();
        string response = connection.send_get_request_to_feedly ("/v3/categories/");

        var parser = new Json.Parser ();
        parser.load_from_data (response, -1);
        Json.Array array = parser.get_root ().get_array ();

        for (int i = 0; i < array.get_length (); i++) {
            Json.Object object = array.get_object_element (i);

            categories.add (feedlyCategory.from_json_object (object));
        }
        return categories;   
    }
    
    public void getCategories() throws Error {
        string response = connection.send_get_request_to_feedly ("/v3/categories/");

        var parser = new Json.Parser ();
        parser.load_from_data (response, -1);
        Json.Array array = parser.get_root ().get_array ();
        

        for (int i = 0; i < array.get_length (); i++) {
            Json.Object object = array.get_object_element (i);
            
            string categorieID = object.get_string_member("id");
            int unreadCount = get_count_of_unread_articles (categorieID);
            string title = object.get_string_member("label");
            
            stdout.printf("%s | %s %i\n", categorieID, title, unreadCount);
            
            //dataBase.write_categorie(categorieID, title, unreadCount, i+1, -99, 1);
        } 
    }
    
    public void getFeeds() throws Error {
        string response = connection.send_get_request_to_feedly ("/v3/subscriptions/");

        var parser = new Json.Parser ();
        parser.load_from_data (response, -1);
        Json.Array array = parser.get_root ().get_array ();

        for (int i = 0; i < array.get_length (); i++) {
            Json.Object object = array.get_object_element (i);
            
            string feedID = object.get_string_member ("id");
            string title = object.get_string_member ("title");
            string icon_url = object.has_member ("visualUrl") ? object.get_string_member ("visualUrl") : "";
            string url = object.has_member ("website") ? object.get_string_member ("website") : "";
            
            var categories = object.get_array_member("categories");
            var category = categories.get_object_element(0);
            string categorieID = category.get_string_member("id");
            int unreadCount = get_count_of_unread_articles (feedID);
            
            stdout.printf("%s | %s %i\n", category.get_string_member("label"), title, unreadCount);
            //downloadIcon(feedID, icon_url);
            /*dataBase.write_feed(feedID,
								title,
								url,
								if(icon_url == "") ? 0 : 1,
								unreadCount,
								unreadCount;*/
        }
    }
    
    
    private void downloadIcon(string feed_id, string icon_url)
	{
		string icon_path = GLib.Environment.get_home_dir() + "/.local/share/feedreader/data/feed_icons/";
		var path = GLib.File.new_for_path(icon_path);
		try{path.make_directory_with_parents();}catch(GLib.Error e){}
		string local_filename = icon_path + feed_id + ".ico";
					
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

    /** Returns all subscriptions */
    public Gee.ArrayList<Subscription> get_subscriptions () throws Error {
        string response = connection.send_get_request_to_feedly ("/v3/subscriptions/");

        var parser = new Json.Parser ();
        parser.load_from_data (response, -1);
        Json.Array array = parser.get_root ().get_array ();
        Gee.ArrayList<Subscription> subscriptions = new Gee.ArrayList<Subscription> ();

        for (int i = 0; i < array.get_length (); i++) {
            Json.Object object = array.get_object_element (i);
            subscriptions.add (Subscription.from_json_object (object));
        }
        return subscriptions;
    }
    
    

    public Gee.TreeMap<feedlyCategory,Gee.TreeSet<Subscription>> get_sorted_category_subscription_map_with_unread_count () throws Error{
       
        var map = new Gee.HashMap<string,Gee.TreeSet<Subscription>> ();  
        var markers = make_markers ();

        foreach (var sub in get_subscriptions ()) {
            if (markers.has_key (sub.id)) {
                int count = markers.get (sub.id);
                sub.unread_count = count;
            }

            foreach (var cat in sub.category_ids) {
                Gee.TreeSet<Subscription> list;
                if (map.has_key (cat)) 
                    list = map.get (cat);
                else {
                    list = new Gee.TreeSet<Subscription> ();
                    map.set (cat, list);
                }               
                list.add (sub);
            }
        }
        var category_map = new Gee.TreeMap<feedlyCategory,Gee.TreeSet<Subscription>>();
        foreach (var id in map.keys) {
            var label = id.substring(id.last_index_of("/")+1);
            feedlyCategory cat = new feedlyCategory (id,label.splice(0,1,label.up (1)));
            if (markers.has_key (id)) {                
                int count = markers.get (id);
                cat.unread_count = count;
            }
            category_map.set (cat,map.get (id));
        }
                 
        return category_map;
    }

    public Gee.HashMap<string,int> make_markers () throws Error {
        string response = connection.send_get_request_to_feedly ("/v3/markers/counts");

        var parser = new Json.Parser ();
        parser.load_from_data (response, -1);
        Json.Array array = parser.get_root ().get_object ().get_array_member ("unreadcounts");

        markers = new Gee.HashMap<string,int> ();

        for (int i = 0; i < array.get_length (); i++) {
            Json.Object object = array.get_object_element (i);

            markers.set (object.get_string_member ("id"), (int)object.get_int_member ("count"));
        }
        return markers;
    }

        /** Returns all articles for a specified Category (max. 10'000)
     * @param unreadOnly Show only the unread entries?
     */
    public Gee.ArrayList<Entry> get_entries_for_category (feedlyCategory category, bool unreadOnly = true) {
        return this.get_entries_for (category.category_id, unreadOnly, true, 10000);
    }

    /** Returns all articles for a specified Feed (max. 10'000)
     * @param unreadOnly Show only the unread entries?
     */
    //public Gee.ArrayList<Entry>> get_entries_for_feed (Feed feed, bool unreadOnly = true) {
    //    return this.get_entries_for (feed.id, unreadOnly, true, 10000);
    //}

    /** Returns all articles for a specified Subscription (max. 10'000)
     * @param unreadOnly Show only the unread entries?
     */
    public Gee.ArrayList<Entry> get_entries_for_subscription (Subscription subscription, bool unreadOnly = true) throws Error {
        return this.get_entries_for (subscription.id, unreadOnly, true, 10000);
    }

    /**
     * Returns articles
     * @param id All articles grouped by one ID. May be a subscription, feed, tag or category id
     * @param unreadOnly List only the unread entries
     * @param showNewest Newest first?
     * @param number Maximum number of entries
     * @return A bunch of articles
     */
    public Gee.ArrayList<Entry> get_entries_for (string id, bool unread_only = true, bool show_newest = true, int number = 10000) throws Error {
        string entry_id_response = connection.send_get_request_to_feedly ("/v3/streams/ids?streamId=%s&unreadOnly=%s&count=%d&ranked=%s".printf(id,(unread_only ? "true" : "false"),number,(show_newest ? "newest" : "oldest")));
     //  print (entry_id_response +"\n");
        string response = connection.send_post_string_request_to_feedly ("/v3/entries/.mget", entry_id_response,"application/json");
      //print (response+"\n");
        var parser = new Json.Parser ();
        parser.load_from_data (response, -1);

        var array = parser.get_root ().get_array ();
        Gee.ArrayList<Entry> entries = new Gee.ArrayList<Entry>();

        for(int i = 0; i < array.get_length(); i++) {
            Json.Object object = array.get_object_element (i);

            entries.add (Entry.from_json_object(object));
        }
        return entries;
    }

    /** Returns the number of unread articles for an ID (may be a feed, subscription, category or tag */
    public unowned int get_count_of_unread_articles (string id) throws Error {
        string response = connection.send_get_request_to_feedly ("/v3/markers/counts");

        var parser = new Json.Parser ();
        parser.load_from_data (response, -1);

        var object = parser.get_root ().get_object ();

        var unreadcounts = object.get_array_member ("unreadcounts");

        int unread_count = -1;

        for (int i = 0; i < unreadcounts.get_length (); i++) {
            var unread = unreadcounts.get_object_element (i);

            string unread_id = unread.get_string_member ("id");

            if (id == unread_id) {
                unread_count = (int)unread.get_int_member ("count");

                break;
            }
        }

        if(unread_count == -1) {
            error("Unkown id: " + id);
        }

        return unread_count;
    }

    /** Mark a category as read */
    public void mark_as_read_category (feedlyCategory category) {
        this.mark_as_read (category.category_id, "categories");
    }

     /** Mark an article as read */
    public void mark_as_read_entry (Entry entry) {
        this.mark_as_read (entry.id, "entries");
    }

    /** Mark a subscription as read */
    public void mark_as_read_subscription (Subscription subscription) {
        this.mark_as_read (subscription.id, "feeds");
    }

    private void mark_as_read(string id, string type) {
        Json.Object object = new Json.Object();

        object.set_string_member ("action", "markAsRead");

        object.set_string_member ("type", type);

        Json.Array ids = new Json.Array();
        ids.add_string_element (id);

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
      
        connection.send_post_request_to_feedly ("/v3/markers", root);
    }
}
