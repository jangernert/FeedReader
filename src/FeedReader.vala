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

	public class FeedReaderApp : Gtk.Application {

		private MainWindow m_window;
		private bool m_online = true;
		private static FeedReaderApp? m_app = null;
		public signal void callback(string content);


		public new static FeedReaderApp get_default()
		{
			if(m_app == null)
				m_app = new FeedReaderApp();

			return m_app;
		}

		public bool isOnline()
		{
			return m_online;
		}

		public void setOnline(bool online)
		{
			m_online = online;
		}

		protected override void startup()
		{
			Logger.init();
			Logger.info("FeedReader " + AboutInfo.version);

			Settings.state().set_boolean("ui-running", true);

			base.startup();
		}

		public override void activate()
		{
			WebKit.WebContext.get_default().set_web_extensions_directory(Constants.INSTALL_PREFIX + "/" + Constants.INSTALL_LIBDIR);

			if(m_window == null)
			{
				m_window = MainWindow.get_default();
				m_window.set_icon_name("org.gnome.FeedReader");
				Gtk.IconTheme.get_default().add_resource_path("/org/gnome/FeedReader/icons");

				FeedReaderBackend.get_default().newFeedList.connect(() => {
					Logger.debug("FeedReader: newFeedList");
					ColumnView.get_default().newFeedList();
				});

				FeedReaderBackend.get_default().refreshFeedListCounter.connect(() => {
					Logger.debug("FeedReader: refreshFeedListCounter");
					ColumnView.get_default().refreshFeedListCounter();
				});

				FeedReaderBackend.get_default().reloadFavIcons.connect(() => {
					Logger.debug("FeedReader: reloadFavIcons");
					ColumnView.get_default().reloadFavIcons();
				});

				FeedReaderBackend.get_default().updateArticleList.connect(() => {
					Logger.debug("FeedReader: updateArticleList");
					ColumnView.get_default().updateArticleList();
				});

				FeedReaderBackend.get_default().syncStarted.connect(() => {
					Logger.debug("FeedReader: syncStarted");
					MainWindow.get_default().writeInterfaceState();
					ColumnView.get_default().getHeader().setRefreshButton(true);
				});

				FeedReaderBackend.get_default().syncFinished.connect(() => {
					Logger.debug("FeedReader: syncFinished");
					ColumnView.get_default().syncFinished();
					MainWindow.get_default().showContent(Gtk.StackTransitionType.SLIDE_LEFT, true);
					ColumnView.get_default().getHeader().setRefreshButton(false);
				});

				FeedReaderBackend.get_default().springCleanStarted.connect(() => {
					Logger.debug("FeedReader: springCleanStarted");
					MainWindow.get_default().showSpringClean();
				});

				FeedReaderBackend.get_default().springCleanFinished.connect(() => {
					Logger.debug("FeedReader: springCleanFinished");
					MainWindow.get_default().showContent();
				});

				FeedReaderBackend.get_default().showArticleListOverlay.connect(() => {
					Logger.debug("FeedReader: showArticleListOverlay");
					ColumnView.get_default().showArticleListOverlay();
				});

				FeedReaderBackend.get_default().setOffline.connect(() => {
					Logger.debug("FeedReader: setOffline");
					if(FeedReaderApp.get_default().isOnline())
					{
						FeedReaderApp.get_default().setOnline(false);
						ColumnView.get_default().setOffline();
					}
				});

				FeedReaderBackend.get_default().setOnline.connect(() => {
					Logger.debug("FeedReader: setOnline");
					if(!FeedReaderApp.get_default().isOnline())
					{
						FeedReaderApp.get_default().setOnline(true);
						ColumnView.get_default().setOnline();
					}
				});

				FeedReaderBackend.get_default().feedAdded.connect((error, errmsg) => {
					Logger.debug("FeedReader: feedAdded");
					ColumnView.get_default().footerSetReady();
					if(error)
						ColumnView.get_default().footerShowError(errmsg);
				});

				FeedReaderBackend.get_default().opmlImported.connect(() => {
					Logger.debug("FeedReader: opmlImported");
					ColumnView.get_default().footerSetReady();
					ColumnView.get_default().newFeedList();
				});

				FeedReaderBackend.get_default().updateSyncProgress.connect((progress) => {
					Logger.debug("FeedReader: updateSyncProgress");
					ColumnView.get_default().getHeader().updateSyncProgress(progress);
				});

				FeedReaderBackend.get_default().updateBadge();
				FeedReaderBackend.get_default().checkOnlineAsync.begin();
			}

			m_window.show_all();
			m_window.present();

			base.activate();
		}

		public override int command_line(ApplicationCommandLine command_line)
		{
			var args = command_line.get_arguments();
			if(args.length > 1)
			{
				Logger.debug("FeedReader: callback %s".printf(args[1]));
				callback(args[1]);
			}

			activate();

			return 0;
		}

		protected override void shutdown()
		{
			Settings.state().set_boolean("ui-running", false);
			Logger.debug("Shutdown!");
			Gst.deinit();
			base.shutdown();
		}

		public async void sync()
		{
			SourceFunc callback = sync.callback;
			ThreadFunc<void*> run = () => {
				FeedReaderBackend.get_default().startSync();
				Idle.add((owned) callback);
				return null;
			};

			new GLib.Thread<void*>("sync", run);
			yield;
		}

		public void cancelSync()
		{
			FeedReaderBackend.get_default().cancelSync();
		}

		private FeedReaderApp()
		{
			GLib.Object(application_id: "org.gnome.FeedReader", flags: ApplicationFlags.HANDLES_COMMAND_LINE);
		}
	}


	public static int main (string[] args)
	{
		Ivy.Stacktrace.register_handlers();
		Posix.atexit(() => {
			Settings.state().set_boolean("ui-running", false);
		});

		try
		{
			var opt_context = new OptionContext();
			opt_context.set_help_enabled(true);
			opt_context.add_main_entries(options, null);
			opt_context.parse(ref args);
		}
		catch(OptionError e)
		{
			print(e.message + "\n");
			return 0;
		}

		if(version)
		{
			stdout.printf("Version: %s\n", AboutInfo.version);
			stdout.printf("Git Commit: %s\n", Constants.GIT_SHA1);
			return 0;
		}

		if(about)
		{
			show_about(args);
			return 0;
		}

		if(media != null)
		{
			UtilsUI.playMedia(args, media);
			return 0;
		}

		if(pingURL != null)
		{
			Logger.init();
			if(!Utils.ping(pingURL))
				Logger.error("Ping failed");
			return 0;
		}

		if(feedURL != null)
		{
			Logger.init();
			Logger.debug(@"Adding feed $feedURL");
			FeedReaderBackend.get_default().addFeed(feedURL, "", false, true);
			return 0;
		}

		if(grabImages != null && articleUrl != null)
		{
			Logger.init();
			FeedServer.grabImages(grabImages, articleUrl);
			return 0;
		}

		if(grabArticle != null)
		{
			Logger.init();
			FeedServer.grabArticle(grabArticle);
			return 0;
		}

		if(unreadCount)
		{
			var old_stdout =(owned)stdout;
			stdout = FileStream.open("/dev/null", "w");
			Logger.init();
			stdout =(owned)old_stdout;
			stdout.printf("%u\n", dbDaemon.get_default().get_unread_total());
			return 0;
		}

		try
		{
			Gst.init_check(ref args);
		}
		catch(GLib.Error e)
		{
			Logger.error("Gst.init: " + e.message);
		}

		var app = FeedReaderApp.get_default();
		app.run(args);

		return 0;
	}

	private const GLib.OptionEntry[] options = {
		{ "version", 0, 0, OptionArg.NONE, ref version, "FeedReader version number", null },
		{ "about", 0, 0, OptionArg.NONE, ref about, "spawn about dialog", null },
		{ "playMedia", 0, 0, OptionArg.STRING, ref media, "start media player with URL", "URL" },
		{ "ping", 0, 0, OptionArg.STRING, ref pingURL, "test the ping function with given URL", "URL" },
		{ "addFeed", 0, 0, OptionArg.STRING, ref feedURL, "add the feed to the collection", "URL" },
		{ "grabArticle", 0, 0, OptionArg.STRING, ref grabArticle, "use the ContentGrabber to grab the given URL", "URL" },
		{ "grabImages", 0, 0, OptionArg.STRING, ref grabImages, "download all images of the html-document", "PATH" },
		{ "url", 0, 0, OptionArg.STRING, ref articleUrl, "url of the article needed to do grabImages", "URL" },
		{ "unreadCount", 0, 0, OptionArg.NONE, ref unreadCount, "current count of unread articles in the database", null },
		{ null }
	};

	private static bool version = false;
	private static bool about = false;
	private static string? media = null;
	private static string? pingURL = null;
	private static string? feedURL = null;
	private static string? grabArticle = null;
	private static string? grabImages = null;
	private static string? articleUrl = null;
	private static bool unreadCount = false;

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
		dialog.present();

		Gtk.main();
	}

}
