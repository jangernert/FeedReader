extern void exit(int exit_code);

namespace FeedReader {

	[DBus (name = "org.gnome.feedreader")]
	public class FeedDaemonServer : Object {

#if WITH_LIBUNITY
		private Unity.LauncherEntry m_launcher;
#endif
		private LoginResponse m_loggedin;

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

		public void startSync()
		{
			sync.begin((obj, res) => {
				sync.end(res);
			});
		}

		public void startInitSync(bool useGrabber)
		{
			initSync.begin(useGrabber, (obj, res) => {
				initSync.end(res);
			});
		}


		public signal void syncStarted();
		public signal void syncFinished();
		public signal void springCleanStarted();
		public signal void springCleanFinished();
		public signal void updateFeedlistUnreadCount(string feedID, bool increase);
		public signal void newFeedList();
		public signal void initSyncStage(int stage);
		public signal void initSyncTag(string tagName);
		public signal void initSyncFeed(string feedName);

		private async void sync()
		{
			if(Utils.springCleaningNecessary())
			{
				logger.print(LogMessage.INFO, "daemon: spring cleaning");
				settings_state.set_boolean("spring-cleaning", true);
				springCleanStarted();
				dataBase.springCleaning();
				settings_state.set_boolean("spring-cleaning", false);
				springCleanFinished();
			}

			if(m_loggedin != LoginResponse.SUCCESS)
			{
				m_loggedin = login(settings_general.get_enum("account-type"));
				if(m_loggedin != LoginResponse.SUCCESS)
				{
					exit(-1);
				}
			}

			if(m_loggedin == LoginResponse.SUCCESS && settings_state.get_boolean("currently-updating") == false)
			{
				syncStarted();
				logger.print(LogMessage.INFO, "daemon: sync started");
				settings_state.set_boolean("currently-updating", true);
				yield server.syncContent();
				updateBadge();
				settings_state.set_boolean("currently-updating", false);
				syncFinished();
				logger.print(LogMessage.INFO, "daemon: sync finished");
			}
			else
				logger.print(LogMessage.DEBUG, "Cant sync because login failed or sync already ongoing");
		}


		private async void initSync(bool useGrabber)
		{
			if(m_loggedin != LoginResponse.SUCCESS)
			{
				m_loggedin = login(settings_general.get_enum("account-type"));
			}

			if(m_loggedin == LoginResponse.SUCCESS && settings_state.get_boolean("currently-updating") == false)
			{
				syncStarted();
				logger.print(LogMessage.INFO, "daemon: initSync started");
				settings_state.set_boolean("currently-updating", true);
				settings_state.set_boolean("initial-sync-ongoing", true);
				yield server.InitSyncContent(useGrabber);
				updateBadge();
				settings_state.set_boolean("currently-updating", false);
				settings_state.set_boolean("initial-sync-ongoing", false);
				syncFinished();
				logger.print(LogMessage.INFO, "daemon: initSync finished");
			}
			else
				logger.print(LogMessage.DEBUG, "Cant sync because login failed or sync already ongoing");
		}

		public LoginResponse login(int type)
		{
			logger.print(LogMessage.DEBUG, "daemon: new FeedServer and login");
			server = new FeedServer(type);
			m_loggedin = server.login();

			server.initSyncStage.connect((stage) => {
				logger.print(LogMessage.DEBUG, "daemon: stage %i".printf(stage));
				initSyncStage(stage);
			});

			server.initSyncTag.connect((tagName) => {
				initSyncTag(tagName);
			});

			server.initSyncFeed.connect((feedName) => {
				initSyncFeed(feedName);
			});

			logger.print(LogMessage.DEBUG, "daemon: login status = %i".printf(m_loggedin));
			return m_loggedin;
		}

		public int isLoggedIn()
		{
			return m_loggedin;
		}

		public void changeUnread(string articleIDs, ArticleStatus read)
		{
			bool increase = true;
			if(read == ArticleStatus.READ)
				increase = false;

			server.setArticleIsRead.begin(articleIDs, read, (obj, res) => {
				server.setArticleIsRead.end(res);
			});

			dataBase.update_article.begin(articleIDs, "unread", read, (obj, res) => {
				dataBase.update_article.end(res);
			});

			dataBase.change_unread.begin(dataBase.getFeedIDofArticle(articleIDs), read, (obj, res) => {
				dataBase.change_unread.end(res);
				updateFeedlistUnreadCount(dataBase.getFeedIDofArticle(articleIDs), increase);
				updateBadge();
			});
		}

		public void markFeedAsRead(string feedID, bool isCat)
		{
			if(isCat)
			{
				server.setCategorieRead.begin(feedID, (obj, res) => {
					server.setCategorieRead.end(res);
				});

				dataBase.markCategorieRead.begin(feedID, (obj, res) => {
					dataBase.markCategorieRead.end(res);
					updateBadge();
					newFeedList();
				});
			}
			else
			{
				server.setFeedRead.begin(feedID, (obj, res) => {
					server.setFeedRead.end(res);
				});

				dataBase.markFeedRead.begin(feedID, (obj, res) => {
					dataBase.markFeedRead.end(res);
					updateBadge();
					newFeedList();
				});
			}
		}

		public void changeMarked(string articleID, ArticleStatus marked)
		{
			server.setArticleIsMarked(articleID, marked);

			dataBase.update_article.begin(articleID, "marked", marked, (obj, res) => {
				dataBase.update_article.end(res);
			});
		}

		public void updateBadge()
		{
#if WITH_LIBUNITY
			if(!settings_state.get_boolean("spring-cleaning"))
			{
				var count = dataBase.get_unread_total();
				logger.print(LogMessage.DEBUG, "daemon: update badge count %u".printf(count));
				m_launcher.count = count;
				if(count > 0)
					m_launcher.count_visible = true;
				else
					m_launcher.count_visible = false;
			}
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
		    conn.register_object ("/org/gnome/feedreader", new FeedDaemonServer());
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
	GLib.Settings settings_readability;
	GLib.Settings settings_pocket;
	GLib.Settings settings_instapaper;
	GLib.Settings settings_evernote;
	FeedServer server;
	Logger logger;
	Notify.Notification notification;


	void main () {
		stderr = FileStream.open ("/dev/null", "w");
		dataBase = new dbManager();
		dataBase.init();
		settings_general = new GLib.Settings ("org.gnome.feedreader");
		settings_state = new GLib.Settings ("org.gnome.feedreader.saved-state");
		settings_feedly = new GLib.Settings ("org.gnome.feedreader.feedly");
		settings_ttrss = new GLib.Settings ("org.gnome.feedreader.ttrss");
		settings_readability = new GLib.Settings ("org.gnome.feedreader.readability");
		settings_pocket = new GLib.Settings ("org.gnome.feedreader.pocket");
		settings_instapaper = new GLib.Settings ("org.gnome.feedreader.instapaper");
		settings_evernote = new GLib.Settings ("org.gnome.feedreader.evernote");
		logger = new Logger();
		Notify.init("org.gnome.feedreader");

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
		var mainloop = new GLib.MainLoop();
		mainloop.run();
	}

}
