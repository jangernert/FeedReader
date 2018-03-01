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

public class FeedReader.Utils : GLib.Object {

	private static Soup.Session? m_session;

	public static Soup.Session getSession()
	{
		if(m_session == null)
		{
			m_session = new Soup.Session();
			m_session.user_agent = Constants.USER_AGENT;
			m_session.ssl_strict = false;
			m_session.timeout = 5;
		}

		return m_session;
	}

	public static void generatePreviews(Gee.List<Article> articles)
	{
		string noPreview = _("No Preview Available");
		foreach(var Article in articles)
		{
			if(!DataBase.readOnly().article_exists(Article.getArticleID()))
			{
				if(Article.getPreview() != null && Article.getPreview() != "")
				{
					continue;
				}
				if(!DataBase.readOnly().preview_empty(Article.getArticleID()))
				{
					continue;
				}
				else if(Article.getHTML() != "" && Article.getHTML() != null)
				{
					Logger.debug("Utils: generate preview for article: " + Article.getArticleID());
					string output = libVilistextum.parse(Article.getHTML(), 1);
					if(output != null)
						output = output.strip();

					if(output == "" || output == null)
					{
						Logger.info("generatePreviews: no Preview");
						Article.setPreview(noPreview);
						Article.setTitle(Utils.UTF8fix(Article.getTitle(), true));
						continue;
					}

					string xml = "<?xml";

					while(output.has_prefix(xml))
					{
						int end = output.index_of_char('>');
						output = output.slice(end+1, output.length).chug();
						output = output.strip();
					}

					output = output.replace("\n"," ");
					output = output.replace("_"," ");

					Article.setPreview(output.chug());
				}
				else
				{
					Logger.debug("no html to create preview from");
					Article.setPreview(noPreview);
				}
				Article.setTitle(Utils.UTF8fix(Article.getTitle(), true));
			}
		}
	}

	public static void checkHTML(Gee.List<Article> articles)
	{
		foreach(var Article in articles)
		{
			if(!DataBase.readOnly().article_exists(Article.getArticleID()))
			{
				string modified_html = _("No Text available for this article :(");
				if(Article.getHTML() != "")
				{
					modified_html = Article.getHTML().replace("src=\"//","src=\"http://");
				}
				Article.setHTML(modified_html);
			}
		}
	}

	public static string UTF8fix(string? old_string, bool removeHTML = false)
	{
		if(old_string == null)
		{
			Logger.warning("Utils.UTF8fix: string is NULL");
			return "NULL";
		}

		int rm_html = 0;
		if(removeHTML)
			rm_html = 1;

		string? output = old_string.replace("\n"," ").strip();

		output = libVilistextum.parse(old_string, rm_html);

		if(output != null)
		{
			output = output.replace("\n"," ").strip();
			if(output != "")
			{
				return output;
			}
		}
		return old_string;
	}

	public static string[] getDefaultExpandedCategories()
	{
		return {CategoryID.MASTER.to_string(), CategoryID.TAGS.to_string()};
	}

	/*public static GLib.DateTime convertStringToDate(string date)
	{
		return new GLib.DateTime(
			new TimeZone.local(),
			int.parse(date.substring(0, date.index_of_nth_char(4))),															// year
			int.parse(date.substring(date.index_of_nth_char(5), date.index_of_nth_char(7) - date.index_of_nth_char(5))),		// month
			int.parse(date.substring(date.index_of_nth_char(8), date.index_of_nth_char(10) - date.index_of_nth_char(8))),		// day
			int.parse(date.substring(date.index_of_nth_char(11), date.index_of_nth_char(13) - date.index_of_nth_char(11))),		// hour
			int.parse(date.substring(date.index_of_nth_char(14), date.index_of_nth_char(16) - date.index_of_nth_char(14))),		// min
			int.parse(date.substring(date.index_of_nth_char(17), date.index_of_nth_char(19) - date.index_of_nth_char(17)))		// sec
		);
	}*/

	public static bool springCleaningNecessary()
	{
		var lastClean = new DateTime.from_unix_local(Settings.state().get_int("last-spring-cleaning"));
		var now = new DateTime.now_local();

		var difference = now.difference(lastClean);
		bool doCleaning = false;

		Logger.debug("last clean: %s".printf(lastClean.format("%Y-%m-%d %H:%M:%S")));
		Logger.debug("now: %s".printf(now.format("%Y-%m-%d %H:%M:%S")));
		Logger.debug("difference: %f".printf(difference/GLib.TimeSpan.DAY));

		if((difference/GLib.TimeSpan.DAY) >= Settings.general().get_int("spring-clean-after"))
			doCleaning = true;

		return doCleaning;
	}

	// thanks to
	// http://kuikie.com/snippet/79-8/vala/strings/vala-generate-random-string/%7B$ROOT_URL%7D/terms/
	public static string string_random(int length = 8, string charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890")
	{
		string random = "";

		for(int i=0;i<length;i++){
			int random_index = Random.int_range(0,charset.length);
			string ch = charset.get_char(charset.index_of_nth_char(random_index)).to_string();
			random += ch;
		}

		return random;
	}

	public static bool arrayContains(string[] array, string key)
	{
		foreach(string s in array)
		{
			if(s == key)
				return true;
		}

		return false;
	}

	public static void copyAutostart()
	{
		string desktop = "org.gnome.FeedReader-autostart.desktop";
		string filename = GLib.Environment.get_user_data_dir() + "/" + desktop;


		if(Settings.tweaks().get_boolean("feedreader-autostart") && !FileUtils.test(filename, GLib.FileTest.EXISTS))
		{
			try
			{
				var origin = File.new_for_path(Constants.INSTALL_PREFIX + "/share/FeedReader/" + desktop);
				var destination = File.new_for_path(filename);
	        	origin.copy(destination, FileCopyFlags.NONE);
			}
			catch(GLib.Error e)
			{
				Logger.error("Utils.copyAutostart: %s".printf(e.message));
			}
		}
	}

	public static string printTlsCertificateFlags(GLib.TlsCertificateFlags flag)
	{
		string errors = "";
		int flags = flag;

		if(flags - GLib.TlsCertificateFlags.GENERIC_ERROR >= 0)
		{
			errors += "GENERIC_ERROR ";
			flags -= GLib.TlsCertificateFlags.VALIDATE_ALL;
		}

		if(flags - GLib.TlsCertificateFlags.INSECURE >= 0)
		{
			errors += "INSECURE ";
			flags -= GLib.TlsCertificateFlags.INSECURE;
		}

		if(flags - GLib.TlsCertificateFlags.REVOKED >= 0)
		{
			errors += "REVOKED ";
			flags -= GLib.TlsCertificateFlags.REVOKED;
		}

		if(flags - GLib.TlsCertificateFlags.EXPIRED >= 0)
		{
			errors += "EXPIRED ";
			flags -= GLib.TlsCertificateFlags.EXPIRED;
		}

		if(flags - GLib.TlsCertificateFlags.NOT_ACTIVATED >= 0)
		{
			errors += "NOT_ACTIVATED ";
			flags -= GLib.TlsCertificateFlags.NOT_ACTIVATED;
		}

		if(flags - GLib.TlsCertificateFlags.BAD_IDENTITY >= 0)
		{
			errors += "BAD_IDENTITY ";
			flags -= GLib.TlsCertificateFlags.BAD_IDENTITY;
		}

		if(flags - GLib.TlsCertificateFlags.UNKNOWN_CA >= 0)
		{
			errors += "UNKNOWN_CA ";
			flags -= GLib.TlsCertificateFlags.UNKNOWN_CA;
		}

		return errors;
	}

	public static bool ping(string link)
	{
		Logger.debug("Ping: " + link);
		var uri = new Soup.URI(link);

		if(uri == null)
		{
			Logger.error(@"Ping failed: can't parse url $link! Seems to be not valid.");
			return false;
		}

		var message = new Soup.Message.from_uri("HEAD", uri);

		if(message == null)
		{
			Logger.error(@"Ping failed: can't send message to $link! Seems to be not valid.");
			return false;
		}

		var status = getSession().send_message(message);

		Logger.debug(@"Ping: status $status");

		if(status >= 200 && status <= 208)
		{
			Logger.debug("Ping successful");
			return true;
		}

		Logger.error(@"Ping: failed %u - %s".printf(status, Soup.Status.get_phrase(status)));

		return false;
	}


	public static bool remove_directory(string path, uint level = 0)
	{
		++level;
		bool flag = false;

		try
		{
			var directory = GLib.File.new_for_path(path);

			var enumerator = directory.enumerate_children(GLib.FileAttribute.STANDARD_NAME, 0);

			GLib.FileInfo file_info;
			while((file_info = enumerator.next_file()) != null)
			{
				string file_name = file_info.get_name();

				if((file_info.get_file_type()) == GLib.FileType.DIRECTORY)
				{
					remove_directory(path + file_name + "/", level);
		    	}

				var file = directory.get_child(file_name);
				file.delete();
			}

			if(level == 1)
			{
				directory.delete();
			}
		}
		catch (IOError.NOT_FOUND e)
		{
		}
		catch(GLib.Error e)
		{
			Logger.error("Utils - remove_directory: " + e.message);
		}


		return flag;
	}


	public static string shortenURL(string url)
	{
		string longURL = url;
		if(longURL.has_prefix("https://"))
		{
			longURL = longURL.substring(8);
		}
		else if(longURL.has_prefix("http://"))
		{
			longURL = longURL.substring(7);
		}

		if(longURL.has_prefix("www."))
		{
			longURL = longURL.substring(4);
		}

		if(longURL.has_suffix("api/"))
		{
			longURL = longURL.substring(0, longURL.length - 4);
		}

		return longURL;
	}

	// thx to geary :)
	public static string prepareSearchQuery(string raw_query)
	{
		// Two goals here:
		//   1) append an * after every term so it becomes a prefix search
		//      (see <https://www.sqlite.org/fts3.html#section_3>), and
		//   2) strip out common words/operators that might get interpreted as
		//      search operators.
		// We ignore everything inside quotes to give the user a way to
		// override our algorithm here.  The idea is to offer one search query
		// syntax for Geary that we can use locally and via IMAP, etc.

		string quote_balanced = parseSearchTerm(raw_query).replace("'", " ");
		if(countChar(raw_query, '"') % 2 != 0)
		{
			// Remove the last quote if it's not balanced.  This has the
			// benefit of showing decent results as you type a quoted phrase.
			int last_quote = raw_query.last_index_of_char('"');
			assert(last_quote >= 0);
			quote_balanced = raw_query.splice(last_quote, last_quote + 1, " ");
		}

		string[] words = quote_balanced.split_set(" \t\r\n:()%*\\");
		bool in_quote = false;
		StringBuilder prepared_query = new StringBuilder();
		foreach(string s in words)
		{
			s = s.strip();

			int quotes = countChar(s, '"');
			if(!in_quote && quotes > 0)
			{
				in_quote = true;
				--quotes;
			}

			if(!in_quote)
			{
				string lower = s.down();
				if(lower == "" || lower == "and" || lower == "or" || lower == "not" || lower == "near" || lower.has_prefix("near/"))
					continue;

				if(s.has_prefix("-"))
					s = s.substring(1);

				if(s == "")
					continue;

				s = "\"" + s + "*\"";
			}

			if(in_quote && quotes % 2 != 0)
				in_quote = false;

			prepared_query.append(s);
			prepared_query.append(" ");
		}

		assert(!in_quote);

		return prepared_query.str.strip();
	}

	public static int countChar(string s, unichar c)
	{
	    int count = 0;
	    for (int index = 0; (index = s.index_of_char(c, index)) >= 0; ++index, ++count)
	        ;
	    return count;
	}

	public static string parseSearchTerm(string searchTerm)
	{
		if(searchTerm.has_prefix("title: "))
		{
			return searchTerm.substring(7);
		}

		if(searchTerm.has_prefix("author: "))
		{
			return searchTerm.substring(8);
		}

		if(searchTerm.has_prefix("content: "))
		{
			return searchTerm.substring(9);
		}

		return searchTerm;
	}

	public static bool categoryIsPopulated(string catID, Gee.List<Feed> feeds)
	{
		foreach(Feed feed in feeds)
		{
			var ids = feed.getCatIDs();
			foreach(string id in ids)
			{
				if(id == catID)
				{
					return true;
				}
			}
		}

		return false;
	}

	public static uint categoryGetUnread(string catID, Gee.List<Feed> feeds)
	{
		uint unread = 0;

		foreach(Feed feed in feeds)
		{
			var ids = feed.getCatIDs();
			foreach(string id in ids)
			{
				if(id == catID)
				{
					unread += feed.getUnread();
					break;
				}
			}
		}

		return unread;
	}

	public static void resetSettings(GLib.Settings settings)
	{
		Logger.warning("Resetting setting " + settings.schema_id);
		var keys = settings.list_keys();
		foreach(string key in keys)
		{
			settings.reset(key);
		}
	}

	public static string URLtoFeedName(string? url)
	{
		if(url == null)
			return "";

		var feedname = new GLib.StringBuilder(url);

		if(feedname.str.has_suffix("/"))
			feedname.erase(feedname.str.char_count()-1);

		if(feedname.str.has_prefix("https://"))
			feedname.erase(0, 8);

		if(feedname.str.has_prefix("http://"))
			feedname.erase(0, 7);

		if(feedname.str.has_prefix("www."))
			feedname.erase(0, 4);

		return feedname.str;
	}

	public static async bool file_exists(string path_str, FileType expected_type)
	{
		var path = GLib.File.new_for_path(path_str);
		try
		{
			var info = yield path.query_info_async("standard::type", FileQueryInfoFlags.NONE);
			return info.get_file_type () == expected_type;
		}
		catch(Error e)
		{
			return false;
		}
	}

	public static async bool ensure_path(string path_str)
	{
		var path = GLib.File.new_for_path(path_str);
		if(yield file_exists(path_str, FileType.DIRECTORY))
			return true;

		try
		{
			path.make_directory_with_parents();
			return true;
		}
		catch(IOError.EXISTS e)
		{
			return true;
		}
		catch(Error e)
		{
			Logger.error(@"ensure_path: Failed to create folder $path_str: " + e.message);
			return false;
		}
	}

	public static string gsettingReadString(GLib.Settings setting, string key)
	{
		string val = setting.get_string(key);
		if(val == "")
			Logger.warning("Utils.gsettingReadString: failed to read %s %s".printf(setting.schema_id, key));

		return val;
	}

	public static void gsettingWriteString(GLib.Settings setting, string key, string val)
	{
		if(val == "" || val == null)
			Logger.warning("Utils.gsettingWriteString: resetting %s %s".printf(setting.schema_id, key));

		if(!setting.set_string(key, val))
			Logger.error("Utils.gsettingWriteString: writing %s %s failed".printf(setting.schema_id, key));
	}

	public static async uint8[] inputStreamToArray(InputStream stream, Cancellable? cancellable=null) throws Error
	{
		Array<uint8> result = new Array<uint8>();
		uint8[] buffer = new uint8[1024];
		while(true)
		{
			size_t bytesRead = 0;
			yield stream.read_all_async(buffer, Priority.DEFAULT_IDLE, cancellable, out bytesRead);
			if (bytesRead  == 0)
				break;
			result.append_vals(buffer, (uint)bytesRead);
		}

		return result.data;
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
		var feed = DataBase.readOnly().read_feed(feedID);
		article.insert(feed_pos, feed != null ? feed.getTitle() : "");


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

		string font = Settings.general().get_string("font");
		var desc = Pango.FontDescription.from_string(font);
		string fontfamilly = desc.get_family();
		uint fontsize = (uint)GLib.Math.roundf(desc.get_size()/Pango.SCALE);
		string small_size = (fontsize - 2).to_string();
		string large_size = (fontsize * 2).to_string();
		string normal_size = fontsize.to_string();

		string fontfamily_id = "$FONTFAMILY";
		int fontfamilly_pos = article.str.index_of(fontfamily_id);
		article.erase(fontfamilly_pos, fontfamily_id.length);
		article.insert(fontfamilly_pos, fontfamilly);

		string fontsize_id = "$FONTSIZE";
		string sourcefontsize_id = "$SMALLSIZE";
		int fontsize_pos = article.str.index_of(fontsize_id);
		article.erase(fontsize_pos, fontsize_id.length);
		article.insert(fontsize_pos, normal_size);

		string largesize_id = "$LARGESIZE";
		int largesize_pos = article.str.index_of(largesize_id);
		article.erase(largesize_pos, largesize_id.length);
		article.insert(largesize_pos, large_size);

		for(int i = article.str.index_of(sourcefontsize_id, 0); i != -1; i = article.str.index_of(sourcefontsize_id, i))
		{
			article.erase(i, sourcefontsize_id.length);
			article.insert(i, small_size);
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
		// if backend = local RSS -> return true;
		if(Settings.general().get_string("plugin") == "local")
			return true;

		if(!FeedReaderBackend.get_default().supportFeedManipulation())
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
		return FeedReaderBackend.get_default().isOnline();
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

		if(!DataBase.readOnly().haveCategories()
		&& !FeedReaderBackend.get_default().supportTags()
		&& !DataBase.readOnly().haveFeedsWithoutCat())
			return true;

		return false;
	}

	public static void saveImageDialog(string imagePath)
	{

		try
		{
			string articleName = "Article.pdf";
			string? articleID = ColumnView.get_default().displayedArticle();
			if(articleID != null)
				articleName = DataBase.readOnly().read_article(articleID).getTitle();

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
			Logger.error("Utils.saveImageDialog: %s".printf(e.message));
		}
	}

	public static void playMedia(string[] args, string url)
	{
		Gtk.init(ref args);
		Gst.init(ref args);
		Logger.init(true);

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

	public static uint getRelevantArticles()
	{
		var interfacestate = MainWindow.get_default().getInterfaceState();
		string[] selectedRow = interfacestate.getFeedListSelectedRow().split(" ", 2);
		ArticleListState state = interfacestate.getArticleListState();
		string searchTerm = interfacestate.getSearchTerm();
		string? topRow = interfacestate.getArticleListTopRow();

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

		int count = 0;

		if(topRow != null)
			count = DataBase.readOnly().getArticleCountNewerThanID(topRow, selectedRow[1], IDtype, state, searchTerm);

		Logger.debug(@"getRelevantArticles: $count");
		return count;
	}
}
