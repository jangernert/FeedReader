using GLib;
using Gtk;

namespace FeedReader {

	public const string QUICKLIST_ABOUT_STOCK = N_("About FeedReader");

	dbManager dataBase;
	GLib.Settings settings_general;
	GLib.Settings settings_state;
	GLib.Settings settings_feedly;
	GLib.Settings settings_ttrss;
	GLib.Settings settings_readability;
	GLib.Settings settings_pocket;
	GLib.Settings settings_instapaper;
	GLib.Settings settings_evernote;
	FeedDaemon feedDaemon_interface;
	Logger logger;
	Share share;


	[DBus (name = "org.gnome.feedreader")]
	interface FeedDaemon : Object {
		public abstract void startSync() throws IOError;
		public abstract void startInitSync(bool useGrabber) throws IOError;
		public abstract int login(int type) throws IOError;
		public abstract int isLoggedIn() throws IOError;
		public abstract void changeArticle(string articleID, ArticleStatus status) throws IOError;
		public abstract void markFeedAsRead(string feedID, bool isCat) throws IOError;
		public abstract void tagArticle(string articleID, string tagID, bool add) throws IOError;
		public abstract string createTag(string caption) throws IOError;
		public abstract void updateBadge() throws IOError;
		public signal void syncStarted();
		public signal void syncFinished();
		public signal void springCleanStarted();
		public signal void springCleanFinished();
		public signal void updateFeedlistUnreadCount(string feedID, bool increase);
		public signal void newFeedList();
		public signal void updateArticleList();
		public signal void initSyncStage(int stage);
		public signal void initSyncTag(string tagName);
		public signal void initSyncFeed(string feedName);
	}


	public class rssReaderApp : Gtk.Application {

		private readerUI m_window;
		public signal void callback(OAuth type);

		protected override void startup()
		{
			startDaemon();

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
			share = new Share();

			try{
				feedDaemon_interface = Bus.get_proxy_sync (BusType.SESSION, "org.gnome.feedreader", "/org/gnome/feedreader");

				feedDaemon_interface.updateFeedlistUnreadCount.connect((feedID, increase) => {
				    m_window.getContent().updateFeedListCountUnread(feedID, increase);
				});

				feedDaemon_interface.newFeedList.connect(() => {
				    m_window.getContent().newFeedList();
				});

				feedDaemon_interface.updateArticleList.connect(() => {
				    m_window.getContent().updateArticleList();
				});

				feedDaemon_interface.syncStarted.connect(() => {
				    m_window.setRefreshButton(true);
				});

				feedDaemon_interface.syncFinished.connect(() => {
				    logger.print(LogMessage.DEBUG, "sync finished -> update ui");
				    m_window.showContent(Gtk.StackTransitionType.SLIDE_LEFT);
					m_window.getContent().updateArticleList();
					m_window.setRefreshButton(false);
				});

				feedDaemon_interface.springCleanStarted.connect(() => {
				    m_window.showSpringClean();
				});

				feedDaemon_interface.springCleanFinished.connect(() => {
				    m_window.showContent();
				});
			}catch (IOError e) {
				logger.print(LogMessage.ERROR, e.message);
			}
			base.startup();
		}

		public override void activate()
		{
			base.activate();
			if (m_window == null)
			{
				m_window = new readerUI(this);
				m_window.set_icon_name("internet-news-reader");
			}

			m_window.show_all();
			feedDaemon_interface.updateBadge();
		}

		public override int command_line(ApplicationCommandLine command_line)
		{
			var args = command_line.get_arguments();
			if(args.length > 1)
				callback(Utils.parseArg(args[1]));


			activate();

			return 0;
		}

		public void sync()
		{
			try{
				feedDaemon_interface.startSync();
			}catch (IOError e) {
				logger.print(LogMessage.ERROR, e.message);
			}
		}

		public void startDaemon()
		{
			string[] spawn_args = {"feedreader-daemon"};
			try{
				GLib.Process.spawn_async("/", spawn_args, null , GLib.SpawnFlags.SEARCH_PATH, null, null);
			}catch(GLib.SpawnError e){
				logger.print(LogMessage.ERROR, "spawning command line: %s".printf(e.message));
			}
		}

		public readerUI getWindow()
		{
			return m_window;
		}

		public rssReaderApp()
		{
			GLib.Object(application_id: "org.gnome.FeedReader", flags: ApplicationFlags.HANDLES_COMMAND_LINE);
		}
	}


	public static int main (string[] args) {
		try {
			var opt_context = new OptionContext();
			opt_context.set_help_enabled(true);
			opt_context.add_main_entries(options, null);
			opt_context.parse(ref args);
		} catch (OptionError e) {
			print(e.message + "\n");
			return 0;
		}

		if(version)
		{
			stdout.printf("Version: %s\n", AboutInfo.version);
			return 0;
		}

		if(about)
		{
			show_about(args);
			return 0;
		}

		var app = new rssReaderApp();
		app.run(args);

		return 0;
	}

	private const GLib.OptionEntry[] options = {
		{ "version", 0, 0, OptionArg.NONE, ref version, "FeedReader version number", null },
		{ "about", 0, 0, OptionArg.NONE, ref about, "spawn about dialog", null },
		{ null }
	};

	private static bool version = false;
	private static bool about = false;

	static void show_about(string[] args)
	{
		Gtk.init(ref args);
        Gtk.AboutDialog dialog = new Gtk.AboutDialog();

        dialog.response.connect ((response_id) => {
			if(response_id == Gtk.ResponseType.CANCEL || response_id == Gtk.ResponseType.DELETE_EVENT)
				Gtk.main_quit();
		});

		dialog.artists = AboutInfo.artists;
		dialog.authors = AboutInfo.authors;
		dialog.documenters = null;
		dialog.translator_credits = AboutInfo.translators;

		dialog.program_name = AboutInfo.programmName;
		dialog.comments = AboutInfo.comments;
		dialog.copyright = AboutInfo.copyright;
		dialog.version = AboutInfo.version;
		dialog.logo_icon_name = AboutInfo.iconName;
		dialog.license_type = Gtk.License.GPL_3_0;
		dialog.wrap_license = true;

		dialog.website = AboutInfo.website;
		dialog.website_label = AboutInfo.websiteLabel;
		dialog.present ();

		Gtk.main();
	}

}
