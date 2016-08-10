//	This file is part of FeedReader.
//
//	FeedReader is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	FeedReader is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with FeedReader.  If not, see <http://www.gnu.org/licenses/>.

extern void exit(int exit_code);

namespace FeedReader {

	public class FeedReaderDebuggerWindow : Gtk.Window
	{
		public signal void syncStarted();
		public signal void syncFinished();
		public signal void newFeedList();
		public signal void updateFeedList();
		public signal void newArticleList();
		public signal void updateArticleList();
		public signal void showArticleListOverlay();

		private Gtk.Button m_sync_button;

		internal FeedReaderDebuggerWindow () {
			this.title = "FeedReader Debugger";

			var grid = new Gtk.Grid();
			grid.expand = true;
			grid.valign = Gtk.Align.CENTER;
			grid.halign = Gtk.Align.CENTER;
			grid.row_spacing = 5;
			grid.column_spacing = 5;
			grid.margin = 10;
			var reset_button = new Gtk.Button.with_label("Reset DB");
			reset_button.clicked.connect(on_reset_button_click);
			var start_button = new Gtk.Button.with_label("Start FeedReader");
			start_button.clicked.connect(() => {
				string[] spawn_args = {"feedreader", "--debug"};
				try{
					GLib.Process.spawn_async("/", spawn_args, null , GLib.SpawnFlags.SEARCH_PATH, null, null);
				}catch(GLib.SpawnError e){
					logger.print(LogMessage.ERROR, "spawning command line: %s".printf(e.message));
				}
			});

			var sync = setupSync();
			var articleList = setupArticleList();
			var feedlist = setupFeedList();

			grid.attach(start_button, 0, 1, 1, 1);
			grid.attach_next_to(reset_button, start_button, Gtk.PositionType.BOTTOM, 1, 1);
			grid.attach_next_to(sync, reset_button, Gtk.PositionType.BOTTOM, 1, 1);
			grid.attach_next_to(articleList, sync, Gtk.PositionType.BOTTOM, 1, 1);
			grid.attach_next_to(feedlist, articleList, Gtk.PositionType.BOTTOM, 1, 1);

			var bar = new Gtk.HeaderBar ();
	        bar.show_close_button = true;
			bar.set_title("FeedReader Debugger");

			this.destroy.connect (() => {
				Gtk.main_quit ();
			});

			this.set_titlebar(bar);
			this.add(grid);
			this.set_icon_name("feedreader");
			show_all();
		}

		private Gtk.Bin setupSync()
		{
			var spin = new Gtk.SpinButton.with_range(1, 200, 1);
			spin.set_value(20.0);
			m_sync_button = new Gtk.Button.with_label("Sync");
			if(dataBase.isTableEmpty("feeds"))
				m_sync_button.set_sensitive(false);

			m_sync_button.clicked.connect(() => {
				int count = spin.get_value_as_int();
				bool showOverlay = (count > 0) ? true : false;
				syncStarted();
				settings_state.set_boolean("currently-updating", true);

				GLib.Timeout.add_seconds_full(GLib.Priority.DEFAULT, 5, () => {
					if(count > 0)
					{
						int before = dataBase.getHighestRowID();

						if(count >= 10)
						{
							count -= 10;
							DebugUtils.dummyArticles(settings_general.get_int("max-articles"), 10);
						}
						else
						{
							DebugUtils.dummyArticles(settings_general.get_int("max-articles"), count);
							count = 0;
						}

						updateFeedList();
						updateArticleList();
						setNewRows(before);
					}

					if(count == 0)
					{
						if(showOverlay)
							showArticleListOverlay();

						settings_state.set_boolean("currently-updating", false);
						syncFinished();
						return false;
					}

					return true;
				});
			});

			var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
			box.pack_start(spin);
			box.pack_end(m_sync_button);
			box.margin = 10;

			var frame = new Gtk.Frame ("Simulate Sync");
			frame.add(box);
			return frame;
		}

		private Gtk.Bin setupArticleList()
		{
			var update_button = new Gtk.Button.with_label("update");
			update_button.clicked.connect(() => {
				updateArticleList();
			});
			var new_button = new Gtk.Button.with_label("new");
			new_button.clicked.connect(() => {
				newArticleList();
			});

			var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
			box.pack_start(update_button);
			box.pack_start(new_button);
			box.margin = 10;

			var frame = new Gtk.Frame ("ArticleList");
			frame.add(box);
			return frame;
		}

		private Gtk.Bin setupFeedList()
		{
			var catLabel = new Gtk.Label("categories");
			catLabel.set_size_request(70, 0);
			catLabel.set_alignment(0, 0.5f);
			var catSpin = new Gtk.SpinButton.with_range(1, 20, 1);
			catSpin.set_value(5);
			var box3 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
			box3.pack_start(catLabel);
			box3.pack_start(catSpin);

			var feedLabel = new Gtk.Label("feeds per cat");
			feedLabel.set_size_request(70, 0);
			feedLabel.set_alignment(0, 0.5f);
			var feedSpin = new Gtk.SpinButton.with_range(1, 20, 1);
			feedSpin.set_value(5);
			var box4 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
			box4.pack_start(feedLabel);
			box4.pack_start(feedSpin);

			var update_button = new Gtk.Button.with_label("update");
			update_button.clicked.connect(() => {
				updateFeedList();
			});
			var new_button = new Gtk.Button.with_label("new");
			new_button.clicked.connect(() => {
				newFeedList();
			});
			var fill_button = new Gtk.Button.with_label("fill");
			fill_button.clicked.connect(() => {
				DebugUtils.dummyFeeds(catSpin.get_value_as_int(), feedSpin.get_value_as_int());
				m_sync_button.set_sensitive(true);
			});

			var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
			box.pack_start(update_button);
			box.pack_start(new_button);

			var box2 = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
			box2.pack_start(box3);
			box2.pack_start(box4);
			box2.pack_start(fill_button);
			box2.pack_start(box);
			box2.margin = 10;

			var frame = new Gtk.Frame ("FeedList");
			frame.add(box2);
			return frame;
		}

		void on_reset_button_click (Gtk.Button button)
		{
			dataBase.resetDB();
			dataBase.init();
			m_sync_button.set_sensitive(false);
		}

		private void setNewRows(int before)
		{
			int after = dataBase.getHighestRowID();
			int newArticles = after-before;
			logger.print(LogMessage.DEBUG, "FeedServer: new articles: %i".printf(newArticles));

			if(newArticles > 0 && settings_state.get_boolean("no-animations"))
			{
				logger.print(LogMessage.DEBUG, "UI NOT running: setting \"articlelist-new-rows\"");
				int newCount = settings_state.get_int("articlelist-new-rows") + (int)Utils.getRelevantArticles(newArticles);
				settings_state.set_int("articlelist-new-rows", newCount);
			}
		}
	}

	[DBus (name = "org.gnome.feedreader")]
	public class FeedDaemonServer : Object {
		public signal void syncStarted();
		public signal void syncFinished();
		public signal void springCleanStarted();
		public signal void springCleanFinished();
		public signal void newFeedList();
		public signal void updateFeedList();
		public signal void newArticleList();
		public signal void updateArticleList();
		public signal void writeInterfaceState();
		public signal void showArticleListOverlay();

		public FeedDaemonServer()
		{
			logger.print(LogMessage.DEBUG, "daemon: constructor");
			var window = new FeedReaderDebuggerWindow();
			window.newFeedList.connect(() => {
				newFeedList();
			});
			window.updateFeedList.connect(() => {
				updateFeedList();
			});
			window.newArticleList.connect(() => {
				newArticleList();
			});
			window.updateArticleList.connect(() => {
				updateArticleList();
			});

			window.showArticleListOverlay.connect(() => {
				showArticleListOverlay();
			});

			window.syncStarted.connect(() => {
				syncStarted();
			});

			window.syncFinished.connect(() => {
				syncFinished();
			});
		}

		public void startSync()
		{

		}

		public void startInitSync()
		{

		}


		public bool supportTags()
		{
			return false;
		}

		public void scheduleSync(int time)
		{

		}

		public LoginResponse login(Backend type)
		{
			return LoginResponse.SUCCESS;
		}

		public LoginResponse isLoggedIn()
		{
			return LoginResponse.SUCCESS;
		}

		public bool isOnline()
		{
			return true;
		}

		public int getVersion()
		{
			return DBusAPIVersion;
		}

		public void changeArticle(string articleID, ArticleStatus status)
		{
			if(status == ArticleStatus.READ || status == ArticleStatus.UNREAD)
			{
				bool increase = true;
				if(status == ArticleStatus.READ)
					increase = false;

				dataBase.update_article.begin(articleID, "unread", status, (obj, res) => {
					dataBase.update_article.end(res);
					updateFeedList();
					updateBadge();
				});
			}
			else if(status == ArticleStatus.MARKED || status == ArticleStatus.UNMARKED)
			{
				dataBase.update_article.begin(articleID, "marked", status, (obj, res) => {
					dataBase.update_article.end(res);
				});
			}
		}

		public async bool checkOnlineAsync()
		{
			return true;
		}

		public string createTag(string caption)
		{
			return "";
		}

		public void tagArticle(string articleID, string tagID, bool add)
		{

		}

		public void updateTagColor(string tagID, int color)
		{

		}

		public void resetDB()
		{

		}

		public void markFeedAsRead(string feedID, bool isCat)
		{
			if(isCat)
			{
				dataBase.markCategorieRead.begin(feedID, (obj, res) => {
					dataBase.markCategorieRead.end(res);
					updateBadge();
					newFeedList();
					updateArticleList();
				});
			}
			else
			{
				dataBase.markFeedRead.begin(feedID, (obj, res) => {
					dataBase.markFeedRead.end(res);
					updateBadge();
					newFeedList();
					updateArticleList();
				});
			}
		}

		public void markAllItemsRead()
		{
			dataBase.markAllRead.begin((obj, res) => {
				dataBase.markAllRead.end(res);
				updateBadge();
				newFeedList();
				updateArticleList();
			});
		}

		public void updateBadge()
		{

		}

		public string addCategory(string title, string? parentID = null, bool createLocally = false)
		{
			return "";
		}

		public void addFeed(string feedURL, string cat, bool isID)
		{

		}
	}

	[DBus (name = "org.gnome.feedreaderError")]
	public errordomain FeedError
	{
		SOME_ERROR
	}

	void on_bus_aquired (DBusConnection conn) {
		try {
			daemon = new FeedDaemonServer();
		    conn.register_object ("/org/gnome/feedreader", daemon);
		} catch (IOError e) {
		    logger.print(LogMessage.WARNING, "daemon: Could not register service. Will shut down!");
		    logger.print(LogMessage.WARNING, e.message);
		    exit(-1);
		}
		logger.print(LogMessage.DEBUG, "daemon: bus aquired");
	}


	dbDaemon dataBase;
	FeedServer server;
	GLib.Settings settings_general;
	GLib.Settings settings_state;
	GLib.Settings settings_feedly;
	GLib.Settings settings_tweaks;
	Logger logger;
	FeedDaemonServer daemon;
	Notify.Notification notification;
	bool m_notifyActionSupport = false;



	int main (string[] args)
	{
		Gtk.init(ref args);
		settings_general = new GLib.Settings ("org.gnome.feedreader");
		settings_state = new GLib.Settings ("org.gnome.feedreader.saved-state");
		settings_tweaks = new GLib.Settings ("org.gnome.feedreader.tweaks");

		logger = new Logger("debugger");
		dataBase = new dbDaemon("debug.db");
		server = new FeedServer(Backend.NONE);
		dataBase.init();

		Bus.own_name (BusType.SESSION, "org.gnome.feedreader", BusNameOwnerFlags.NONE,
				      on_bus_aquired,
				      () => {
				      			settings_state.set_boolean("currently-updating", false);
								settings_state.set_boolean("spring-cleaning", false);
				      },
				      () => {
				      			logger.print(LogMessage.WARNING, "daemon: Could not aquire name (already running). Will shut down!");
				          		exit(-1);
				          	}
				      );
		Gtk.main();
		return 0;
	}
}
