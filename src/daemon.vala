[DBus (name = "org.gnome.feedreader")]
public class FeedDaemonServer : Object {

	private Unity.LauncherEntry m_launcher;
	
	public FeedDaemonServer()
	{
		stdout.printf("init\n");
		int sync_timeout = feedreader_settings.get_int("sync");
		m_launcher = Unity.LauncherEntry.get_for_desktop_id("feedreader.desktop");
		updateBadge();
		GLib.Timeout.add_seconds_full(GLib.Priority.DEFAULT, sync_timeout, () => {
        	stdout.printf ("Timeout!\n");
			startSync();
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
		syncStarted();
		yield ttrss.getCategories();
		yield ttrss.getFeeds();
		yield ttrss.getHeadlines();
		yield ttrss.updateHeadlines(300);
		updateBadge();
		syncFinished();
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
        exit(-1);
    }
}


dbManager dataBase;
GLib.Settings feedreader_settings;
ttrss_interface ttrss;
extern void exit(int exit_code);

void main () {
	ttrss = new ttrss_interface();
	dataBase = new dbManager();
	dataBase.init();
	feedreader_settings = new GLib.Settings ("org.gnome.feedreader");
	Notify.init("RSS Reader");
	
	if(ttrss.login(null))
	{
		Bus.own_name (BusType.SESSION, "org.gnome.feedreader", BusNameOwnerFlags.NONE,
		              on_bus_aquired,
		              () => {},
		              () => {
		              			stderr.printf ("Could not aquire name\n"); 
		              			exit(-1);
		              		}
		              );
	}
	else
	{
		stdout.printf("error loggin in\n");
		exit(-1);
	}
    new MainLoop ().run ();
}

