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

using GLib;
using Gtk;

namespace FeedReader {

	public const string QUICKLIST_ABOUT_STOCK = N_("About FeedReader");

	dbUI dataBase;
	GLib.Settings settings_general;
	GLib.Settings settings_state;
	GLib.Settings settings_feedly;
	GLib.Settings settings_ttrss;
	GLib.Settings settings_inoreader;
	GLib.Settings settings_owncloud;
	GLib.Settings settings_tweaks;
	GLib.Settings settings_share;
	FeedDaemon feedDaemon_interface;
	Logger logger;
	Share share;


	public class rssReaderApp : Gtk.Application {

		private readerUI m_window;
		public signal void callback(OAuth type, string? oauthVerifier);

		protected override void startup()
		{
			settings_general = new GLib.Settings ("org.gnome.feedreader");
			settings_state = new GLib.Settings ("org.gnome.feedreader.saved-state");
			settings_feedly = new GLib.Settings ("org.gnome.feedreader.feedly");
			settings_ttrss = new GLib.Settings ("org.gnome.feedreader.ttrss");
			settings_owncloud = new GLib.Settings ("org.gnome.feedreader.owncloud");
			settings_inoreader = new GLib.Settings ("org.gnome.feedreader.inoreader");
			settings_tweaks = new GLib.Settings ("org.gnome.feedreader.tweaks");
			settings_share = new GLib.Settings ("org.gnome.feedreader.share");

			logger = new Logger("ui");
			share = new Share();

			logger.print(LogMessage.INFO, "FeedReader " + AboutInfo.version);
			startDaemon();

			if(debug)
			{
				dataBase = new dbUI("debug.db");
			}
			else
			{
				dataBase = new dbUI();
			}

			dataBase.init();
			base.startup();

			if(GLib.Environment.get_variable("DESKTOP_SESSION") == "gnome")
			{
				var menu = new GLib.Menu();
				menu.append(Menu.settings, "win.settings");
				menu.append(Menu.reset, "win.reset");
				menu.append(Menu.about, "win.about");
				menu.append(Menu.quit, "app.quit");
				this.app_menu = menu;

				var quit_action = new SimpleAction("quit", null);
				quit_action.activate.connect(this.quit);
				this.add_action(quit_action);
			}
		}

		public override void activate()
		{
			base.activate();
			DBusConnection.setup();

			WebKit.WebContext.get_default().set_web_extensions_directory("/usr/share/FeedReader/");

			if (m_window == null)
			{
				m_window = new readerUI(this);
				m_window.set_icon_name("feedreader");
				if(settings_tweaks.get_boolean("sync-on-startup"))
					sync();
			}

			m_window.show_all();
			DBusConnection.connectSignals(m_window);
			feedDaemon_interface.updateBadge();
			feedDaemon_interface.checkOnlineAsync();
		}

		public override int command_line(ApplicationCommandLine command_line)
		{
			var args = command_line.get_arguments();
			string verifier = "";
			if(args.length > 1)
			{
				logger.print(LogMessage.DEBUG, "FeedReader: callback %s".printf(args[1]));
				var type = Utils.parseArg(args[1], out verifier);
				callback(type , verifier);
			}



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
			logger.print(LogMessage.INFO, "FeedReader: start daemon");
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
			stdout.printf("Git Commit: %s\n", g_GIT_SHA1);
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
		{ "debug", 0, 0, OptionArg.NONE, ref debug, "stat in debug mode", null },
		{ null }
	};

	private static bool version = false;
	private static bool about = false;
	private static bool debug = false;

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
