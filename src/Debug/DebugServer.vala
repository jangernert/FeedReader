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

	public class FeedReaderDebuggerWindow : Gtk.ApplicationWindow
	{

		internal FeedReaderDebuggerWindow (FeedReaderDebugger app) {
			Object(application: app, title: "FeedReader Debugger");

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
			//start_button.clicked.connect();

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
			//update_button.clicked.connect();
			var new_button = new Gtk.Button.with_label("new");
			//new_button.clicked.connect();

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
			var update_button = new Gtk.Button.with_label("update");
			//update_button.clicked.connect();
			var new_button = new Gtk.Button.with_label("new");
			//new_button.clicked.connect();

			var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
			box.pack_start(update_button);
			box.pack_start(new_button);
			box.margin = 10;

			var frame = new Gtk.Frame ("FeedList");
			frame.add(box);
			return frame;
		}

		void on_reset_button_click (Gtk.Button button)
		{

		}

		void on_sync_button_click (Gtk.Button button)
		{

		}
	}

	[DBus (name = "org.gnome.feedreader")]
	public class FeedReaderDebugger : Gtk.Application
	{
		protected override void activate()
		{
			new FeedReaderDebuggerWindow (this).show ();
		}

		internal FeedReaderDebugger()
		{
			Object(application_id: "org.example.FeedReaderDebugger");

		}

		public int isLoggedIn()
		{
			return LoginResponse.SUCCESS;
		}

		public bool supportTags()
		{
			return true;
		}

		public void updateBadge(){}
	}

	dbDaemon dataBase;
	GLib.Settings settings_general;
	GLib.Settings settings_state;
	GLib.Settings settings_tweaks;
	Logger logger;

	public int main(string[] args)
	{
		settings_general = new GLib.Settings ("org.gnome.feedreader");
		settings_state = new GLib.Settings ("org.gnome.feedreader.saved-state");
		settings_tweaks = new GLib.Settings ("org.gnome.feedreader.tweaks");
		logger = new Logger("daemon");
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
		return new FeedReaderDebugger ().run (args);
	}

	void on_bus_aquired (DBusConnection conn) {
		try {
			conn.register_object ("/org/gnome/feedreader", new FeedReaderDebugger());
		} catch (IOError e) {
			logger.print(LogMessage.WARNING, "daemon: Could not register service. Will shut down!");
			logger.print(LogMessage.WARNING, e.message);
			exit(-1);
		}
		logger.print(LogMessage.DEBUG, "daemon: bus aquired");
	}

	[DBus (name = "org.gnome.feedreaderError")]
	public errordomain FeedError
	{
		SOME_ERROR
	}
}
