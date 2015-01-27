using GLib;
using Gtk;

dbManager dataBase;
GLib.Settings settings_general;
GLib.Settings settings_state;
GLib.Settings settings_feedly;
GLib.Settings settings_ttrss;
FeedDaemon feedDaemon_interface;


[DBus (name = "org.gnome.feedreader")]
interface FeedDaemon : Object {
    public abstract void startSync() throws IOError;
    public abstract int login(int type) throws IOError;
    public abstract int isLoggedIn() throws IOError;
    public abstract void changeUnread(string articleID, int read) throws IOError;
    public abstract void changeMarked(string articleID, int marked) throws IOError;
    public abstract void updateBadge() throws IOError;
    public signal void syncStarted();
    public signal void syncFinished();
    public signal void updateFeedlistUnreadCount(string feedID, bool increase);
}


public class rssReaderApp : Gtk.Application {

	private readerUI m_window;
	
	 
	protected override void startup () {
		startDaemon();
		
		dataBase = new dbManager();
		dataBase.init();
		
		settings_general = new GLib.Settings ("org.gnome.feedreader");
		settings_state = new GLib.Settings ("org.gnome.feedreader.saved-state");
		settings_feedly = new GLib.Settings ("org.gnome.feedreader.feedly");
		settings_ttrss = new GLib.Settings ("org.gnome.feedreader.ttrss");
		
		try{
			feedDaemon_interface = Bus.get_proxy_sync (BusType.SESSION, "org.gnome.feedreader", "/org/gnome/feedreader");
			
			feedDaemon_interface.updateFeedlistUnreadCount.connect((feedID, increase) => {
		        m_window.updateFeedListCountUnread(feedID, increase);
		    });
			
			feedDaemon_interface.syncStarted.connect(() => {
		        stdout.printf ("sync started\n");
		        m_window.setRefreshButton(true);
		    });
		    
		    feedDaemon_interface.syncFinished.connect(() => {
		        stdout.printf ("sync finished\n");
				m_window.updateFeedList();
				m_window.updateArticleList();
		        m_window.setRefreshButton(false);
		    });
		}catch (IOError e) {
    		stderr.printf ("%s\n", e.message);
		}
		base.startup();
	}
	
	protected override void activate ()
	{
		if (m_window == null)
		{
			m_window = new readerUI(this);
			m_window.set_icon_name ("internet-news-reader");
		}
		
		m_window.show_all();
		feedDaemon_interface.updateBadge();
	}

	public void sync()
	{
		try{
			feedDaemon_interface.startSync();
		}catch (IOError e) {
    		stderr.printf ("%s\n", e.message);
		}
	}
	
	public void startDaemon()
	{
		string[] spawn_args = {"feedreader-daemon"};
		try{
			GLib.Process.spawn_async("/", spawn_args, null , GLib.SpawnFlags.SEARCH_PATH, null, null);
		}catch(GLib.SpawnError e){
			stdout.printf("error spawning command line: %s\n", e.message);
		}
	}

	public rssReaderApp () {
		GLib.Object (application_id: "org.gnome.FeedReader", flags: ApplicationFlags.FLAGS_NONE);
	}
}


public static int main (string[] args) {
	var app = new rssReaderApp();
	app.run(args);

	return 0;
}

