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
		var window = ((FeedApp)GLib.Application.get_default()).getWindow();
		if(window != null)
		{
			var interfacestate = window.getInterfaceState();
			selectedRow = interfacestate.getFeedListSelectedRow().split(" ", 2);
			state = interfacestate.getArticleListState();
			searchTerm = interfacestate.getSearchTerm();
		}

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


		bool only_unread = false;
		bool only_marked = false;

		switch(state)
		{
			case ArticleListState.ALL:
				break;
			case ArticleListState.UNREAD:
				only_unread = true;
				break;
			case ArticleListState.MARKED:
				only_marked = true;
				break;
		}

		var articles = dbUI.get_default().read_articles(
			selectedRow[1],
			IDtype,
			only_unread,
			only_marked,
			searchTerm,
			newArticlesCount,
			0,
			newArticlesCount);

		return articles.size;
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
		var settingMenu = new GLib.Menu();
		settingMenu.append(Menu.settings, "win.settings");
		settingMenu.append(Menu.reset, "win.reset");

		var urlMenu = new GLib.Menu();
		urlMenu.append(Menu.bugs, "win.bugs");
		urlMenu.append(Menu.bounty, "win.bounty");

		var aboutMenu = new GLib.Menu();
		aboutMenu.append(Menu.shortcuts, "win.shortcuts");
		aboutMenu.append(Menu.about, "win.about");
		aboutMenu.append(Menu.quit, "app.quit");

		var menu = new GLib.Menu();
		menu.append_section("", settingMenu);
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

	public static void saveImageDialog(string imagePath, Gtk.Window parent)
	{

		try
		{
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
														parent,
														Gtk.FileChooserAction.SAVE,
														_("Cancel"),
														Gtk.ResponseType.CANCEL,
														_("Save"),
														Gtk.ResponseType.ACCEPT);
			save_dialog.set_do_overwrite_confirmation(true);
			save_dialog.set_modal(true);
			save_dialog.set_current_folder(GLib.Environment.get_home_dir());
			save_dialog.set_current_name("Article_Image" + map.get(mimeType));
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

	public static void testGOA()
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
		catch(GLib.Error e)
		{
			Logger.error("UtilsUI.testGOA: %s".printf(e.message));
		}
	}
}
