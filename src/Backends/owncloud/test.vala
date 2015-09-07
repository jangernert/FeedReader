namespace FeedReader {
    GLib.Settings settings_owncloud;
    GLib.Settings settings_general;
    Logger logger;
    const string GETTEXT_PACKAGE = "";

    int main()
    {
        settings_owncloud = new GLib.Settings ("org.gnome.feedreader.owncloud");
        settings_general = new GLib.Settings ("org.gnome.feedreader");
        logger = new Logger();

        var categories = new GLib.List<category>();
        var feeds      = new GLib.List<feed>();
        var articles   = new GLib.List<article>();

        var owncloudAPI = new OwncloudNewsAPI();
        owncloudAPI.login();
        owncloudAPI.getFeeds(ref feeds);
        owncloudAPI.getCategories(ref categories, ref feeds);
        owncloudAPI.getArticles(ref articles, 10);
        //owncloudAPI.getNewArticles(ref articles, 123231);

        //foreach(feed Feed in feeds)
        //{
        //    Feed.print();
        //}

        //foreach(category cat in categories)
        //{
        //    cat.print();
        //}

        return 0;
    }
}
