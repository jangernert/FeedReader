public class FeedlyAPI : Object {

    public FeedlyConnection connection {get; private set; }
    
    public string token { get; private set; }
    public string user_id { get; private set; }
    private static FeedlyAPI instance;
    public Gee.HashMap<string,int> markers { get; private set; }

    FeedlyAPI() {
    	string devel_token = "AhTSaW97ImEiOiJGZWVkbHkgRGV2ZWxvcGVyIiwiZSI6MTQyODQyNTk1OTEyNiwiaSI6IjY3YjdmNTRjLWU0M2MtNDM3Yi05ZmQ0LWM0MTdkNGVjMzFhMCIsInAiOjgsInQiOjEsInYiOiJwcm9kdWN0aW9uIiwidyI6IjIwMTUuMiIsIngiOiJzdGFuZGFyZCJ9:feedlydev";
        this.connection = new FeedlyConnection (devel_token);
        this.token = devel_token;    
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
            getArticles(categorieID);
            
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
    
    
    public void getArticles(string categorieID) throws Error {
    	
    	int number = 10;
        string entry_id_response = connection.send_get_request_to_feedly("/v3/streams/ids?streamId=%s&unreadOnly=false&count=%i&ranked=oldest".printf(categorieID, number));
        string response = connection.send_post_string_request_to_feedly("/v3/entries/.mget", entry_id_response,"application/json");
        //print(response+"\n");
        var parser = new Json.Parser();
        parser.load_from_data(response, -1);

        var array = parser.get_root().get_array();

        for(int i = 0; i < array.get_length(); i++) {
            Json.Object object = array.get_object_element(i);
            string id = object.get_string_member("id");
            string title = object.has_member("title") ? object.get_string_member("title") : "No title specified";
            string author = object.has_member("author") ? object.get_string_member("author") : "None";
            
            string summaryContent = "";
		    if(object.has_member("summary")){
		        summaryContent = object.get_object_member("summary").get_string_member("content");
		    }
		    
		    string Content = "";
		    if(object.has_member("content")){
		    	Content = object.get_object_member("content").get_string_member("content");
		    }
		    
		    stdout.printf("%s | %s %s\n", id, title, author);
		    
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
