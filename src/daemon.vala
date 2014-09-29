[DBus (name = "org.gnome.feedreader")]
public class FeedDaemonServer : Object {

	private Unity.LauncherEntry m_launcher;
	
	public FeedDaemonServer()
	{
		stdout.printf("init\n");
		m_launcher = Unity.LauncherEntry.get_for_desktop_id("rss-reader.desktop");
		updateBadge();
		GLib.Timeout.add_seconds_full(GLib.Priority.DEFAULT, 300, () => {
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
		var count = dataBase.read_propertie("unread_articles");
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
ttrss_interface ttrss;
extern void exit(int exit_code);

void main () {
	ttrss = new ttrss_interface();
	dataBase = new dbManager();
	dataBase.init();
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

