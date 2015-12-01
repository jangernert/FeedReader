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
		public signal void newFeedList();
		public signal void updateFeedList();
		public signal void newArticleList();
		public signal void updateArticleList();

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
			var sync_button = new Gtk.Button.with_label("Sync");
			sync_button.clicked.connect(on_sync_button_click);

			var spin = new Gtk.SpinButton.with_range(1, 200, 1);

			var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
			box.pack_start(spin);
			box.pack_end(sync_button);
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
			catLabel.set_xalign(0);
			var catSpin = new Gtk.SpinButton.with_range(1, 20, 1);
			catSpin.set_value(5);
			var box3 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
			box3.pack_start(catLabel);
			box3.pack_start(catSpin);

			var feedLabel = new Gtk.Label("feeds per cat");
			feedLabel.set_size_request(70, 0);
			feedLabel.set_xalign(0);
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
		}

		void on_sync_button_click (Gtk.Button button)
		{

		}
	}

	[DBus (name = "org.gnome.feedreader")]
	public class FeedDaemonServer : Object {
		public signal void syncStarted();
		public signal void syncFinished();
		public signal void springCleanStarted();
		public signal void springCleanFinished();
		public signal void updateFeedlistUnreadCount(string feedID, bool increase);
		public signal void newFeedList();
		public signal void updateFeedList();
		public signal void newArticleList();
		public signal void updateArticleList();
		public signal void writeInterfaceState();

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

		public void changeArticle(string articleID, ArticleStatus status)
		{

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

		}

		public void markAllItemsRead()
		{

		}

		public void updateBadge()
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
		    conn.register_object ("/org/gnome/feedreader", new FeedDaemonServer());
		} catch (IOError e) {
		    logger.print(LogMessage.WARNING, "daemon: Could not register service. Will shut down!");
		    logger.print(LogMessage.WARNING, e.message);
		    exit(-1);
		}
		logger.print(LogMessage.DEBUG, "daemon: bus aquired");
	}


	dbDaemon dataBase;
	GLib.Settings settings_general;
	GLib.Settings settings_state;
	GLib.Settings settings_tweaks;
	Logger logger;



	int main (string[] args)
	{
		Gtk.init(ref args);
		settings_general = new GLib.Settings ("org.gnome.feedreader");
		settings_state = new GLib.Settings ("org.gnome.feedreader.saved-state");
		settings_tweaks = new GLib.Settings ("org.gnome.feedreader.tweaks");

		logger = new Logger("debugger");
		dataBase = new dbDaemon("debug.db");
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
