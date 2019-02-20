

namespace FeedReader.Main {
	private const GLib.OptionEntry[] options = {
		{ "version", 0, 0, OptionArg.NONE, ref version, "FeedReader version number", null },
		{ "about", 0, 0, OptionArg.NONE, ref about, "spawn about dialog", null },
		{ "verbose", 0, 0, OptionArg.NONE, ref verbose, "Spit out all the debug information", null },
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
	private static bool verbose = false;
	private static string? media = null;
	private static string? pingURL = null;
	private static string? feedURL = null;
	private static string? grabArticle = null;
	private static string? grabImages = null;
	private static string? articleUrl = null;
	private static bool unreadCount = false;

	public static int main (string[] args)
	{
		Ivy.Stacktrace.register_handlers();

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

		FeedReaderApp.m_verbose = verbose;

		if(version)
		{
			stdout.printf("Version: %s\n", AboutInfo.version);
			stdout.printf("Git Commit: %s\n", Constants.GIT_SHA1);
			return 0;
		}

		if(about)
		{
			FeedReader.show_about(args);
			return 0;
		}

		if(media != null)
		{
			Utils.playMedia(args, media);
			return 0;
		}

		if(pingURL != null)
		{
			Logger.init(verbose);
			if(!Utils.ping(pingURL))
			{
				Logger.error("Ping failed");
			}
			return 0;
		}

		if(feedURL != null)
		{
			Logger.init(verbose);
			Logger.debug(@"Adding feed $feedURL");
			FeedReaderBackend.get_default().addFeed(feedURL, "", false);
			return 0;
		}

		if(grabImages != null && articleUrl != null)
		{
			Logger.init(verbose);
			FeedServer.grabImages(grabImages, articleUrl);
			return 0;
		}

		if(grabArticle != null)
		{
			Logger.init(verbose);
			FeedServer.grabArticle(grabArticle);
			return 0;
		}

		if(unreadCount)
		{
			var old_stdout =(owned)stdout;
			stdout = FileStream.open("/dev/null", "w");
			Logger.init(verbose);
			stdout =(owned)old_stdout;
			stdout.printf("%u\n", DataBase.readOnly().get_unread_total());
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
}
