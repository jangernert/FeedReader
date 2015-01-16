public class ttrss_utils : GLib.Object {
	
	public static string getURL()
	{
		string tmp_url = feedreader_settings.get_string("url");
		if(tmp_url != ""){
			if(!tmp_url.has_suffix("/"))
				tmp_url = tmp_url + "/";

			if(!tmp_url.has_suffix("/api/"))
				tmp_url = tmp_url + "api/";

			if(!tmp_url.has_prefix("http://"))
					tmp_url = "http://" + tmp_url;
		}
		
		return tmp_url;
	}
	
	public static string getUser()
	{
		return feedreader_settings.get_string ("username");
	}
	
	public static string getPasswd()
	{
		var pwSchema = new Secret.Schema ("org.gnome.feedreader.password", Secret.SchemaFlags.NONE,
		                                  "URL", Secret.SchemaAttributeType.STRING,
		                                  "Username", Secret.SchemaAttributeType.STRING);

		var attributes = new GLib.HashTable<string,string>(str_hash, str_equal);
		attributes["URL"] = feedreader_settings.get_string("url");
		attributes["Username"] = getUser();

		string passwd = "";
		try{passwd = Secret.password_lookupv_sync(pwSchema, attributes, null);}catch(GLib.Error e){
			stdout.printf ("Error: %s\n", e.message);
		}
		if(passwd == null)
		{
			return "";
		}
		
		return passwd;
	}
	
	public static void downloadIcon(string feed_id, string icon_url)
	{
		string icon_path = GLib.Environment.get_home_dir() + "/.local/share/feedreader/data/feed_icons/";
		var path = GLib.File.new_for_path(icon_path);
		try{
			path.make_directory_with_parents();
		}
		catch(GLib.Error e){
			debug(e.message);
		}
		
		string remote_filename = icon_url + feed_id + ".ico";
		string local_filename = icon_path + feed_id + ".ico";
		
							
			
		if(!FileUtils.test(local_filename, GLib.FileTest.EXISTS))
		{
			Soup.Message message_dlIcon;
			message_dlIcon = new Soup.Message("GET", remote_filename);
			var session = new Soup.Session();
			var status = session.send_message(message_dlIcon);
			if (status == 200)
				try{
					FileUtils.set_contents(	local_filename,
											(string)message_dlIcon.response_body.flatten().data,
											(long)message_dlIcon.response_body.length);
				}
				catch(GLib.FileError e){
					error(e.message);
				}
		}
	}
}
