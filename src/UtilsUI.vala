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

public class FeedReader.UtilsUI : GLib.Object {


	public static uint getRelevantArticles(int newArticlesCount)
	{
		string[] selectedRow = {};
		ArticleListState state = ArticleListState.ALL;
		string searchTerm = "";
		var interfacestate = MainWindow.get_default().getInterfaceState();
		selectedRow = interfacestate.getFeedListSelectedRow().split(" ", 2);
		state = interfacestate.getArticleListState();
		searchTerm = interfacestate.getSearchTerm();

		FeedListType IDtype = FeedListType.FEED;

		Logger.debug("selectedRow 0: %s".printf(selectedRow[0]));
		Logger.debug("selectedRow 1: %s".printf(selectedRow[1]));

		switch(selectedRow[0])
		{
			case "feed":
				IDtype = FeedListType.FEED;
				break;

			case "cat":
				IDtype = FeedListType.CATEGORY;
				break;

			case "tag":
				IDtype = FeedListType.TAG;
				break;
		}

		var articles = dbUI.get_default().read_articles(
			selectedRow[1],
			IDtype,
			state,
			searchTerm,
			newArticlesCount,
			0,
			newArticlesCount);

		return articles.size;
	}

	public static string buildArticle(string html, string title, string url, string? author, string date, string feedID)
	{
		var article = new GLib.StringBuilder();
		string author_date = "";
		if(author != null)
			author_date +=  _("posted by: %s, ").printf(author);

		author_date += date;

		try
		{
			uint8[] contents;
			var file = File.new_for_uri("resource:///org/gnome/FeedReader/ArticleView/article.html");
			file.load_contents(null, out contents, null);
			article.assign((string)contents);
		}
		catch(GLib.Error e)
		{
			Logger.error("Utils.buildArticle: %s".printf(e.message));
		}

		string html_id = "$HTML";
		int html_pos = article.str.index_of(html_id);
		article.erase(html_pos, html_id.length);
		article.insert(html_pos, html);

		string author_id = "$AUTHOR";
		int author_pos = article.str.index_of(author_id);
		article.erase(author_pos, author_id.length);
		article.insert(author_pos, author_date);

		string title_id = "$TITLE";
		int title_pos = article.str.index_of(title_id);
		article.erase(title_pos, title_id.length);
		article.insert(title_pos, title);

		string url_id = "$URL";
		int url_pos = article.str.index_of(url_id);
		article.erase(url_pos, url_id.length);
		article.insert(url_pos, url);

		string feed_id = "$FEED";
		int feed_pos = article.str.index_of(feed_id);
		article.erase(feed_pos, feed_id.length);
		article.insert(feed_pos, dbUI.get_default().getFeedName(feedID));


		string theme = "theme ";
		switch(Settings.general().get_enum("article-theme"))
		{
			case ArticleTheme.DEFAULT:
				theme += "default";
				break;

			case ArticleTheme.SPRING:
				theme += "spring";
				break;

			case ArticleTheme.MIDNIGHT:
				theme += "midnight";
				break;

			case ArticleTheme.PARCHMENT:
				theme += "parchment";
				break;
		}

		string theme_id = "$THEME";
		int theme_pos = article.str.index_of(theme_id);
		article.erase(theme_pos, theme_id.length);
		article.insert(theme_pos, theme);

		string select_id = "$UNSELECTABLE";
		int select_pos = article.str.index_of(select_id);

		if(Settings.tweaks().get_boolean("article-select-text"))
		{
			article.erase(select_pos-1, select_id.length+1);
		}
		else
		{
			article.erase(select_pos, select_id.length);
			article.insert(select_pos, "unselectable");
		}

		string fontfamily_id = "$FONTFAMILY";
		string font = Settings.general().get_string("font");
		var desc = Pango.FontDescription.from_string(font);
		string fontfamilly = desc.get_family();
		string fontsize = desc.get_size().to_string().substring(0, 2) + "pt";
		int fontfamilly_pos = article.str.index_of(fontfamily_id);
		article.erase(fontfamilly_pos, fontfamily_id.length);
		article.insert(fontfamilly_pos, fontfamilly);

		string sourcefontsize = "0.75rem";
		string fontsize_id = "$FONTSIZE";
		string sourcefontsize_id = "$SOURCEFONTSIZE";
		int fontsize_pos = article.str.index_of(fontsize_id);
		article.erase(fontsize_pos, fontsize_id.length);
		article.insert(fontsize_pos, fontsize);

		for(int i = article.str.index_of(sourcefontsize_id, 0); i != -1; i = article.str.index_of(sourcefontsize_id, i))
		{
			article.erase(i, sourcefontsize_id.length);
			article.insert(i, sourcefontsize);
		}


		try
		{
			uint8[] contents;
			var file = File.new_for_uri("resource:///org/gnome/FeedReader/ArticleView/style.css");
			file.load_contents(null, out contents, null);
			string css_id = "$CSS";
			int css_pos = article.str.index_of(css_id);
			article.erase(css_pos, css_id.length);
			article.insert(css_pos, (string)contents);
		}
		catch(GLib.Error e)
		{
			Logger.error("Utils.buildArticle: load CSS: " + e.message);
		}

		return article.str;
	}

	public static bool canManipulateContent(bool? online = null)
	{
		try
		{
			// if backend = local RSS -> return true;
			if(Settings.general().get_string("plugin") == "local")
				return true;

			if(!DBusConnection.get_default().supportFeedManipulation())
				return false;

			// when we already know wheather feedreader is online or offline
			if(online != null)
			{
				if(online)
					return true;
				else
					return false;
			}

			// otherwise check if online
			return DBusConnection.get_default().isOnline();
		}
        catch(GLib.Error e)
        {
            Logger.error("UtilsUI.canManipulateContent: %s".printf(e.message));
        }

		return false;
	}

	public static GLib.Menu getMenu()
	{
		var urlMenu = new GLib.Menu();
		urlMenu.append(Menu.bugs, "win.bugs");
		urlMenu.append(Menu.bounty, "win.bounty");

		var aboutMenu = new GLib.Menu();
		aboutMenu.append(Menu.shortcuts, "win.shortcuts");
		aboutMenu.append(Menu.about, "win.about");
		aboutMenu.append(Menu.quit, "app.quit");

		var menu = new GLib.Menu();
		menu.append(Menu.settings, "win.settings");
		menu.append(Menu.reset, "win.reset");
		menu.append_section("", urlMenu);

		if(GLib.Environment.get_variable("XDG_CURRENT_DESKTOP").down() != "pantheon")
		{
			menu.append_section("", aboutMenu);
		}

		return menu;
	}

	public static bool onlyShowFeeds()
	{
		if(Settings.general().get_boolean("only-feeds"))
			return true;

		try
		{
			if(!dbUI.get_default().haveCategories()
			&& !DBusConnection.get_default().supportTags()
			&& !dbUI.get_default().haveFeedsWithoutCat())
				return true;
		}
		catch(GLib.Error e)
		{
			Logger.error("UtilsUI.onlyShowFeeds: %s".printf(e.message));
		}

		return false;
	}

	public static void saveImageDialog(string imagePath)
	{

		try
		{
			string articleName = "Article.pdf";
			string? articleID = ColumnView.get_default().displayedArticle();
			if(articleID != null)
				articleName = dbUI.get_default().read_article(articleID).getTitle();

			var file = GLib.File.new_for_path(imagePath);
			var mimeType = file.query_info("standard::content-type", 0, null).get_content_type();
			var filter = new Gtk.FileFilter();
			filter.add_mime_type(mimeType);

			var map = new Gee.HashMap<string, string>();
			map.set("image/gif", ".gif");
			map.set("image/jpeg", ".jpeg");
			map.set("image/png", ".png");
			map.set("image/x-icon", ".ico");

			var save_dialog = new Gtk.FileChooserDialog("Save Image",
														MainWindow.get_default(),
														Gtk.FileChooserAction.SAVE,
														_("Cancel"),
														Gtk.ResponseType.CANCEL,
														_("Save"),
														Gtk.ResponseType.ACCEPT);
			save_dialog.set_do_overwrite_confirmation(true);
			save_dialog.set_modal(true);
			save_dialog.set_current_folder(GLib.Environment.get_user_data_dir());
			save_dialog.set_current_name(articleName + map.get(mimeType));
			save_dialog.set_filter(filter);
			save_dialog.response.connect((dialog, response_id) => {
				switch(response_id)
				{
					case Gtk.ResponseType.ACCEPT:
						try
						{
							var savefile = save_dialog.get_file();
							uint8[] data;
							string etag;
							file.load_contents(null, out data, out etag);
							savefile.replace_contents(data, null, false, GLib.FileCreateFlags.REPLACE_DESTINATION, null, null);
						}
						catch(Error e)
						{
							Logger.debug("imagePopup: save file: " + e.message);
						}
						break;

					case Gtk.ResponseType.CANCEL:
					default:
						break;
				}
				save_dialog.destroy();
			});
			save_dialog.show();
		}
		catch(GLib.Error e)
		{
			Logger.error("UtilsUI.saveImageDialog: %s".printf(e.message));
		}
	}

	public static void playMedia(string[] args, string url)
	{
		Gtk.init(ref args);
		Gst.init(ref args);
		Logger.init("mediaPlayer");

		var window = new Gtk.Window();
		window.set_size_request(800, 600);
		window.destroy.connect(Gtk.main_quit);
		var header = new Gtk.HeaderBar();
		header.show_close_button = true;

		Gtk.CssProvider provider = new Gtk.CssProvider();
		provider.load_from_resource("/org/gnome/FeedReader/gtk-css/basics.css");
		weak Gdk.Display display = Gdk.Display.get_default();
        weak Gdk.Screen screen = display.get_default_screen();
		Gtk.StyleContext.add_provider_for_screen(screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);

		var player = new FeedReader.MediaPlayer(url);

		window.add(player);
		window.set_titlebar(header);
		window.show_all();

		Gtk.main();
	}

	public static Gtk.Image checkIcon(string name, string fallback, Gtk.IconSize size)
	{
		Gtk.Image icon = null;
		if(Gtk.IconTheme.get_default().lookup_icon(name, 0, Gtk.IconLookupFlags.FORCE_SVG) != null)
            icon = new Gtk.Image.from_icon_name(name, size);
        else
            icon = new Gtk.Image.from_icon_name(fallback, size);

		return icon;
	}

	public static void openInGedit(string text)
	{
		try
		{
			string filename = "file:///tmp/FeedReader_crashed_html.txt";
			FileUtils.set_contents(filename, text);
			Gtk.show_uri_on_window(MainWindow.get_default(), filename, Gdk.CURRENT_TIME);
		}
		catch(GLib.Error e)
		{
			Logger.error("Utils.openInGedit(): %s".printf(e.message));
		}
	}

	/*public static void testGOA()
	{
		try
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
						int expires = -1;
						object.oauth2_based.call_get_access_token_sync(out access_token, out expires);
						stdout.printf("access token 2: %s\n", access_token);
						stdout.printf("expires in: %i\n", expires);
						stdout.printf("client id: %s\n", object.oauth2_based.client_id);
						stdout.printf("client secret: %s\n", object.oauth2_based.client_secret);
					}
					else if(object.oauth_based != null)
					{
						string access_token = "";
						string access_token_secret = "";
						int expires = -1;
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
		catch(GLib.Error e)
		{
			Logger.error("UtilsUI.testGOA: %s".printf(e.message));
		}
	}*/
}
