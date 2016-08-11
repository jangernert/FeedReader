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
	GLib.Settings settings_tweaks;
	GLib.Settings settings_share;
	GLib.Settings settings_keybindings;
	FeedDaemon feedDaemon_interface;
	Logger logger;
	Share share;


	public class FeedApp : Gtk.Application {

		private readerUI m_window;
		public signal void callback(OAuth type, string? oauthVerifier);

		protected override void startup()
		{
			settings_general = new GLib.Settings("org.gnome.feedreader");
			settings_state = new GLib.Settings("org.gnome.feedreader.saved-state");
			settings_tweaks = new GLib.Settings("org.gnome.feedreader.tweaks");
			settings_share = new GLib.Settings("org.gnome.feedreader.share");

			logger = new Logger("ui");
			share = new Share();

			logger.print(LogMessage.INFO, "FeedReader " + AboutInfo.version);


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

			if(GLib.Environment.get_variable("XDG_CURRENT_DESKTOP").down() == "gnome")
			{
				var quit_action = new SimpleAction("quit", null);
				quit_action.activate.connect(this.quit);
				this.add_action(quit_action);

				this.app_menu = UiUtils.getMenu();
			}
		}

		public override void activate()
		{
			base.activate();
			DBusConnection.setup();

			WebKit.WebContext.get_default().set_web_extensions_directory(InstallPrefix + "/share/FeedReader/");

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

		protected override void shutdown()
		{
			logger.print(LogMessage.DEBUG, "Shutdown!");
			if(settings_tweaks.get_boolean("quit-daemon"))
				feedDaemon_interface.quit();
			base.shutdown();
		}

		public async void sync()
		{
			SourceFunc callback = sync.callback;
			ThreadFunc<void*> run = () => {
				try{
					feedDaemon_interface.startSync();
				}catch (IOError e) {
					logger.print(LogMessage.ERROR, e.message);
				}
				Idle.add((owned) callback);
				return null;
			};

			new GLib.Thread<void*>("sync", run);
			yield;
		}

		public readerUI getWindow()
		{
			return m_window;
		}

		public FeedApp()
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

		if(media != null)
		{
			playMedia(args, media);
			return 0;
		}

		if(test)
		{
			testFunc();
			return 0;
		}

		Gst.init(ref args);
		var app = new FeedApp();
		app.run(args);

		return 0;
	}

	private const GLib.OptionEntry[] options = {
		{ "version", 0, 0, OptionArg.NONE, ref version, "FeedReader version number", null },
		{ "about", 0, 0, OptionArg.NONE, ref about, "spawn about dialog", null },
		{ "debug", 0, 0, OptionArg.NONE, ref debug, "start in debug mode", null },
		{ "playMedia", 0, 0, OptionArg.STRING, ref media, "start media player with URL", "URL" },
		{ "test", 0, 0, OptionArg.NONE, ref test, "test", null },
		{ null }
	};

	private static bool version = false;
	private static bool about = false;
	private static bool debug = false;
	private static string? media = null;
	private static bool test = false;

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

	static void playMedia(string[] args, string url)
	{
		Gtk.init(ref args);
		Gst.init(ref args);

		settings_general = new GLib.Settings ("org.gnome.feedreader");
		logger = new Logger("mediaPlayer");

		var window = new Gtk.Window();
		window.set_size_request(800, 600);
		window.destroy.connect(Gtk.main_quit);
		var header = new Gtk.HeaderBar();
		header.show_close_button = true;

		try
		{
    		Gtk.CssProvider provider = new Gtk.CssProvider();
			provider.load_from_path(InstallPrefix + "/share/FeedReader/gtk-css/basics.css");
			weak Gdk.Display display = Gdk.Display.get_default();
            weak Gdk.Screen screen = display.get_default_screen();
			Gtk.StyleContext.add_provider_for_screen(screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
		}
		catch (Error e){}

		var player = new FeedReader.MediaPlayer(url);

		window.add(player);
		window.set_titlebar(header);
		window.show_all();

		Gtk.main();
	}

	public static void testFunc()
	{
		Goa.Client? client = new Goa.Client.sync();

		if(client != null)
		{
			var accounts = client.get_accounts();
			foreach(var object in accounts)
			{
				stdout.printf("account type: %s\n", object.account.provider_type);
				stdout.printf("account name: %s\n", object.account.provider_name);
				stdout.printf("account identity: %s\n", object.account.identity);
				stdout.printf("account id: %s\n", object.account.id);

				if(object.oauth2_based != null)
				{
					string access_token = "";
					int expires = 0;
					object.oauth2_based.call_get_access_token_sync(out access_token, out expires);
					stdout.printf("access token: %s\n", access_token);
					stdout.printf("expires in: %i\n", expires);
					stdout.printf("client id: %s\n", object.oauth2_based.client_id);
					stdout.printf("client secret: %s\n", object.oauth2_based.client_secret);
				}
				else if(object.oauth_based != null)
				{
					string access_token = "";
					string access_token_secret = "";
					int expires = 0;
					object.oauth_based.call_get_access_token_sync(out access_token, out access_token_secret, out expires);
					stdout.printf("access token: %s\n", access_token);
					stdout.printf("access token secret: %s\n", access_token_secret);
					stdout.printf("expires in: %i\n", expires);
				}
				else if(object.password_based != null)
				{
					string password = "";
					object.password_based.call_get_password_sync ("abc", out password);
					stdout.printf("password: %s\n", password);
					stdout.printf("presentation identity: %s\n", object.account.presentation_identity);
				}
				stdout.printf("\n");
			}
		}
		else
		{
			stdout.printf("goa not available");
		}
	}

}
