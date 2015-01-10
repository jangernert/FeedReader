[DBus (name = "org.gnome.feedreader")]
public class FeedDaemonServer : Object {

	private Unity.LauncherEntry m_launcher;
	private bool m_loggedin;
	
	public FeedDaemonServer()
	{
		m_loggedin = false;
		stdout.printf("daemon: constructor\n");
		if(!server.login())
		{
			loginDialog();
		}
		else
			m_loggedin = true;

		stdout.printf("init\n");
		int sync_timeout = feedreader_settings.get_int("sync");
		m_launcher = Unity.LauncherEntry.get_for_desktop_id("feedreader.desktop");
		updateBadge();
		stdout.printf("daemon: add timeout\n");
		GLib.Timeout.add_seconds_full(GLib.Priority.DEFAULT, sync_timeout, () => {
			if(!feedreader_settings.get_boolean("currently-updating"))
			{
		   		stdout.printf ("Timeout!\n");
				startSync();
			}
			return true;
		});
	}

    public void startSync () {
		sync.begin((obj, res) => {
			sync.end(res);
		});
    }
    

    public signal void syncStarted();
    public signal void syncFinished();
    public signal void loginDialog();
    
    private async void sync()
	{
		if(!m_loggedin)
		{
			if(server.login())
				m_loggedin = true;
		}
		
		//stdout.printf("daemon: sync started\n");
		syncStarted();
		feedreader_settings.set_boolean("currently-updating", true);
		yield server.sync_content();
		updateBadge();
		feedreader_settings.set_boolean("currently-updating", false);
		syncFinished();
		//stdout.printf("daemon: sync finished\n");
	}
	
	public bool login()
	{
		stdout.printf("daemon: login\n");
		return server.login();
	}
	
	public void changeUnread(string articleID, int read)
	{
		server.setArticleIsRead(articleID, read);
	}
	
	public void changeMarked(string articleID, int marked)
	{
		server.setArticleIsMarked(articleID, marked);
	}
	
	public void updateBadge()
	{
		var count = dataBase.get_unread_total();
		m_launcher.count = count;
		if(count > 0)
			m_launcher.count_visible = true;
		else
			m_launcher.count_visible = false;
	}
}

[DBus (name = "org.gnome.feedreaderError")]
public errordomain FeedError
{
    SOME_ERROR
}

void on_bus_aquired (DBusConnection conn) {
    try {
        conn.register_object ("/org/gnome/feedreader", new FeedDaemonServer ());
    } catch (IOError e) {
        stderr.printf ("Could not register service\n");
        stderr.printf("%s\n", e.message);
        exit(-1);
    }
    stdout.printf("daemon: bus aquired\n");
}


dbManager dataBase;
GLib.Settings feedreader_settings;
feed_server server;
extern void exit(int exit_code);

void main () {
	
	dataBase = new dbManager();
	dataBase.init();
	feedreader_settings = new GLib.Settings ("org.gnome.feedreader");
	Notify.init("FeedReader");
	
	server = new feed_server(feedreader_settings.get_enum("account-type"));
	
	Bus.own_name (BusType.SESSION, "org.gnome.feedreader", BusNameOwnerFlags.NONE,
		          on_bus_aquired,
		          () => {},
		          () => {
		          			stderr.printf ("Could not aquire name\n"); 
		              		exit(-1);
		              	}
		          );
	//stdout.printf("daemon: mainloop\n");
    new MainLoop ().run ();
}

