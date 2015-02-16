extern void exit(int exit_code);

namespace FeedReader {

	[DBus (name = "org.gnome.feedreader")]
	public class FeedDaemonServer : Object {

#if WITH_LIBUNITY
		private Unity.LauncherEntry m_launcher;
#endif
		private int m_loggedin;
	
		public FeedDaemonServer()
		{
			logger.print(LogMessage.DEBUG, "daemon: constructor");
			m_loggedin = login(settings_general.get_enum("account-type"));
		
			if(m_loggedin != LoginResponse.SUCCESS)
				logger.print(LogMessage.WARNING, "daemon: not logged in");
		
			int sync_timeout = settings_general.get_int("sync");
#if WITH_LIBUNITY
			m_launcher = Unity.LauncherEntry.get_for_desktop_id("feedreader.desktop");
			updateBadge();
#endif
			logger.print(LogMessage.DEBUG, "daemon: add timeout");
			GLib.Timeout.add_seconds_full(GLib.Priority.DEFAULT, sync_timeout, () => {
				if(!settings_state.get_boolean("currently-updating"))
				{
			   		logger.print(LogMessage.DEBUG, "daemon: Timeout!");
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
		public signal void updateFeedlistUnreadCount(string feedID, bool increase);
		
		private async void sync()
		{
			if(m_loggedin != LoginResponse.SUCCESS)
			{
				m_loggedin = login(settings_general.get_enum("account-type"));
			}
		
			if(m_loggedin == LoginResponse.SUCCESS)
			{
				syncStarted();
				logger.print(LogMessage.INFO, "daemon: sync started");
				settings_state.set_boolean("currently-updating", true);
				yield server.sync_content();
				updateBadge();
				settings_state.set_boolean("currently-updating", false);
				syncFinished();
				logger.print(LogMessage.INFO, "daemon: sync finished");
			}
			else
				logger.print(LogMessage.DEBUG, "Cant sync because login failed");
		}
	
		public int login(int type)
		{
			server = new feed_server(type);
			m_loggedin = server.login();
		
			return m_loggedin;
		}
	
		public int isLoggedIn()
		{
			return m_loggedin;
		}
	
		public void changeUnread(string articleID, int read)
		{
			bool increase = true;
			if(read == ArticleStatus.READ)
				increase = false;
		
			server.setArticleIsRead.begin(articleID, read, (obj, res) => {
				server.setArticleIsRead.end(res);
			});
		
			dataBase.update_article.begin(articleID, "unread", read, (obj, res) => {
				dataBase.update_article.end(res);
			});
		
			dataBase.change_unread.begin(dataBase.getFeedIDofArticle(articleID), read, (obj, res) => {
				dataBase.change_unread.end(res);
				updateFeedlistUnreadCount(dataBase.getFeedIDofArticle(articleID), increase);
				updateBadge();
			});
		
		}
	
		public void changeMarked(string articleID, int marked)
		{
			server.setArticleIsMarked(articleID, marked);
		
			dataBase.update_article.begin(articleID, "marked", marked, (obj, res) => {
				dataBase.update_article.end(res);
			});
		}
	
		public void updateBadge()
		{
#if WITH_LIBUNITY
			var count = dataBase.get_unread_total();
			m_launcher.count = count;
			if(count > 0)
				m_launcher.count_visible = true;
			else
				m_launcher.count_visible = false;
#endif
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
		    logger.print(LogMessage.WARNING, "daemon: Could not register service. Will shut down!");
		    logger.print(LogMessage.WARNING, e.message);
		    exit(-1);
		}
		logger.print(LogMessage.DEBUG, "daemon: bus aquired");
	}


	dbManager dataBase;
	GLib.Settings settings_general;
	GLib.Settings settings_state;
	GLib.Settings settings_feedly;
	GLib.Settings settings_ttrss;
	feed_server server;
	Logger logger;
	

	void main () {
	
		dataBase = new dbManager();
		dataBase.init();
		settings_general = new GLib.Settings ("org.gnome.feedreader");
		settings_state = new GLib.Settings ("org.gnome.feedreader.saved-state");
		settings_feedly = new GLib.Settings ("org.gnome.feedreader.feedly");
		settings_ttrss = new GLib.Settings ("org.gnome.feedreader.ttrss");
		logger = new Logger();
		Notify.init("FeedReader");
	
		Bus.own_name (BusType.SESSION, "org.gnome.feedreader", BusNameOwnerFlags.NONE,
				      on_bus_aquired,
				      () => {
				      			settings_state.set_boolean("currently-updating", false);
				      },
				      () => {
				      			logger.print(LogMessage.WARNING, "daemon: Could not aquire name. Will shut down!"); 
				          		exit(-1);
				          	}
				      );
		new MainLoop ().run ();
	}
	
}

