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


	public static void generatePreviews(Gee.LinkedList<article> articles)
	{
		string noPreview = _("No Preview Available");
		foreach(var Article in articles)
		{
			if(!dataBase.article_exists(Article.getArticleID()))
			{
				if(Article.getPreview() != null && Article.getPreview() != "")
				{
					continue;
				}
				if(!dataBase.preview_empty(Article.getArticleID()))
				{
					continue;
				}
				else if(Article.getHTML() != "" && Article.getHTML() != null)
				{
					string tmp_path = GLib.Environment.get_tmp_dir() + "/FeedReader/";
					var path = GLib.File.new_for_path(tmp_path);
					try{
						path.make_directory_with_parents();
					}
					catch(GLib.Error e){
						//logger.print(LogMessage.DEBUG, e.message);
					}

					string filename = tmp_path + "articleHtml.XXXXXX";
					int outputfd = GLib.FileUtils.mkstemp(filename);
					try{
						GLib.FileUtils.set_contents(filename, Article.getHTML());
					}
					catch(GLib.FileError e){
						logger.print(LogMessage.ERROR, "error writing html to tmp file - %s".printf(e.message));
					}
					GLib.FileUtils.close(outputfd);

					string output = "";

#if WITH_VILISTEXTUM
					string[] spawn_args = {"vilistextum", "-a", "-n", "-r", "-t", "-u", "-y", "\"utf-8\"", filename, "-"};
#else
					string[] spawn_args = {"html2text", "-utf8", "-nobs", "-style", "pretty", "-rcfile", "/usr/share/FeedReader/html2textrc", filename};
#endif
					try{
						GLib.Process.spawn_sync(null, spawn_args, null , GLib.SpawnFlags.SEARCH_PATH, null, out output, null, null);
					}
					catch(GLib.SpawnError e){
						logger.print(LogMessage.ERROR, "%s: %s".printf(spawn_args[0], e.message));
					}

					output = output.strip();

					if(output == "" || output == null)
					{
						logger.print(LogMessage.ERROR, "html2text could not generate preview text");
						Article.setPreview(noPreview);
						logger.print(LogMessage.DEBUG, filename);
						continue;
					}

					string xml = "<?xml";

					while(output.has_prefix(xml))
					{
						int end = output.index_of_char('>');
						output = output.slice(end+1, output.length).chug();
					}

					output = output.replace("\n"," ");
					output = output.replace("_"," ");

					Article.setPreview(output);
				}
				else
				{
					logger.print(LogMessage.DEBUG, "no html to create preview from");
					Article.setPreview(noPreview);
				}
			}
			Article.setTitle(decodeTitle(Article.getTitle()));
		}
	}

	private static string decodeTitle(string old_title)
	{
#if DAEMONCODE
		var html_cntx = new Html.ParserCtxt();
        html_cntx.use_options(Html.ParserOption.NOWARNING + Html.ParserOption.NOERROR);
        var doc = html_cntx.read_memory(old_title.to_utf8(), old_title.length, "", "UTF-8");

        if (doc == null)
        {
            logger.print(LogMessage.DEBUG, "decodeTitle: parsing failed");
    		return old_title;
    	}

        string title = "";
        doc->dump_memory_enc(out title);

		string tmp_path = GLib.Environment.get_tmp_dir() + "/FeedReader/";
		var path = GLib.File.new_for_path(tmp_path);
		try{
			path.make_directory_with_parents();
		}
		catch(GLib.Error e){
			//logger.print(LogMessage.DEBUG, e.message);
		}

		string filename = tmp_path + "articleHtml.XXXXXX";
        int outputfd = GLib.FileUtils.mkstemp(filename);
        try{
            GLib.FileUtils.set_contents(filename, title);
        }
        catch(GLib.FileError e){
            logger.print(LogMessage.DEBUG, "decodeTitle: error writing html to tmp file - %s".printf(e.message));
        }
        GLib.FileUtils.close(outputfd);

        string output = "";

#if WITH_VILISTEXTUM
		string[] spawn_args = {"vilistextum", "-a", "-n", "-r", "-t", "-u", "-y", "\"utf-8\"", filename, "-"};
#else
        string[] spawn_args = {"html2text", "-utf8", "-nobs", "-style", "pretty", "-rcfile", "/usr/share/FeedReader/html2textrc", filename};
#endif

		try{
			GLib.Process.spawn_sync(null, spawn_args, null , GLib.SpawnFlags.SEARCH_PATH, null, out output, null, null);
		}
		catch(GLib.SpawnError e){
			logger.print(LogMessage.ERROR, "%s: %s".printf(spawn_args[0], e.message));
        }

#if !WITH_VILISTEXTUM
        string xml = "<?xml";
        while(output.has_prefix(xml))
        {
            int end = output.index_of_char('>');
            output = output.slice(end+1, output.length).chug();
        }
#endif
		return output.strip().replace("\n", " ");
#else
		return old_title;
#endif
	}


	public static void checkHTML(Gee.LinkedList<article> articles)
	{
		foreach(var Article in articles)
		{
			if(!dataBase.article_exists(Article.getArticleID()))
			{
				string modified_html = _("No Text available for this article :(");
				if(Article.getHTML() != "")
				{
					modified_html = Article.getHTML().replace("src=\"//","src=\"http://").replace("target=\"_blank\"", "");
				}
				Article.setHTML(modified_html);
			}
		}
	}


	public static string[] getDefaultExpandedCategories()
	{
		string[] e = {};
		e += "Categories";
		if(settings_general.get_enum("account-type") == Backend.TTRSS)
			e += "Labels";
		else
			e += "Tags";

		return e;
	}

	public static GLib.DateTime convertStringToDate(string date)
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
	}

	public static bool springCleaningNecessary()
	{
		var lastClean = new DateTime.from_unix_local(settings_state.get_int("last-spring-cleaning"));
		var now = new DateTime.now_local();

		var difference = now.difference(lastClean);
		bool doCleaning = false;

		logger.print(LogMessage.DEBUG, "last clean: %s".printf(lastClean.format("%Y-%m-%d %H:%M:%S")));
		logger.print(LogMessage.DEBUG, "now: %s".printf(now.format("%Y-%m-%d %H:%M:%S")));
		logger.print(LogMessage.DEBUG, "difference: %f".printf(difference/GLib.TimeSpan.DAY));

		if((difference/GLib.TimeSpan.DAY) >= settings_general.get_int("spring-clean-after"))
			doCleaning = true;

		return doCleaning;
	}

	public static uint getRelevantArticles(int newArticlesCount)
	{
		string[] selectedRow = {};
		ArticleListState state = ArticleListState.ALL;
		string searchTerm = "";

#if DAEMONCODE
		selectedRow = settings_state.get_string("feedlist-selected-row").split(" ", 2);
		state = (ArticleListState)settings_state.get_boolean("show-articles");
		if(settings_tweaks.get_boolean("restore-searchterm"))
			searchTerm = settings_state.get_string("search-term");
#else
		var window = ((rssReaderApp)GLib.Application.get_default()).getWindow();
		if(window != null)
		{
			var interfacestate = window.getInterfaceState();
			selectedRow = interfacestate.getFeedListSelectedRow().split(" ", 2);
			state = interfacestate.getArticleListState();
			searchTerm = interfacestate.getSearchTerm();
		}
#endif

		FeedListType IDtype = FeedListType.FEED;

		logger.print(LogMessage.DEBUG, "selectedRow 0: %s".printf(selectedRow[0]));
		logger.print(LogMessage.DEBUG, "selectedRow 1: %s".printf(selectedRow[1]));

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

		var articles = dataBase.read_articles(
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

	public static string buildArticle(string html, string title, string url, string author, string date, string feedID)
	{
		var article = new GLib.StringBuilder();
		string author_date = "posted by: %s, %s".printf(author, date);

        string template;
		GLib.FileUtils.get_contents("/usr/share/FeedReader/ArticleView/article.html", out template);
		article.assign(template);

		//int html_pos = article.str.index_of("$HTML");
		int html_pos = 567;
		article.erase(html_pos, 5);
		article.insert(html_pos, html);

		//int author_pos = article.str.index_of("$AUTHOR");
		int author_pos = 508;
		article.erase(author_pos, 7);
		article.insert(author_pos, author_date);

		//int title_pos = article.str.index_of("$TITLE");
		int title_pos = 465;
		article.erase(title_pos, 6);
		article.insert(title_pos, title);

		//int url_pos = article.str.index_of("$URL");
		int url_pos = 459;
		article.erase(url_pos, 4);
		article.insert(url_pos, url);

		//int feed_pos = article.str.index_of("$FEED");
		int feed_pos = 427;
		article.erase(feed_pos, 5);
		article.insert(feed_pos, dataBase.getFeedName(feedID));


		string theme = "theme ";
		switch(settings_general.get_enum("article-theme"))
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

		//int theme_pos = article.str.index_of("$THEME");
		int theme_pos = 368;
		article.erase(theme_pos, 6);
		article.insert(theme_pos, theme);

		string css;
		GLib.FileUtils.get_contents("/usr/share/FeedReader/ArticleView/style.css", out css);

		//int css_pos = article.str.index_of("$CSS");
		int css_pos = 319;
		article.erase(css_pos, 4);
		article.insert(css_pos, css);

		return article.str;
	}

	public static void scale_pixbuf(ref Gdk.Pixbuf icon, int size)
	{
		var width = icon.get_width();
		var height = icon.get_height();

		double aspect_ratio = (double)width/(double)height;
		if(width > height)
		{
			width = size;
			height = (int)((float)size /aspect_ratio);
		}
		else if(height > width)
		{
			height = size;
			width = (int)((float)size /aspect_ratio);
		}
		else
		{
			height = size;
			width = size;
		}

		icon = icon.scale_simple(width, height, Gdk.InterpType.BILINEAR);
	}


	public static OAuth parseArg(string arg, out string verifier)
	{
		if(arg == PocketSecrets.oauth_callback)
			return OAuth.POCKET;

		if(arg == InstapaperSecrets.oauth_callback)
			return OAuth.INSTAPAPER;

		if(arg == FeedlySecret.apiRedirectUri)
			return OAuth.FEEDLY;

		if(arg.has_prefix(ReadabilitySecrets.oauth_callback))
		{
			int verifier_start = arg.index_of("=")+1;
			int verifier_end = arg.index_of("&", verifier_start);
			verifier = arg.substring(verifier_start, verifier_end-verifier_start);
			return OAuth.READABILITY;
		}

		return OAuth.NONE;
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

	public static void copyAutostart()
	{
		string filename = GLib.Environment.get_home_dir() + "/.config/autostart/feedreader-autostart.desktop";

		if(!FileUtils.test(filename, GLib.FileTest.EXISTS))
		{
			var origin = File.new_for_path("/usr/share/FeedReader/feedreader-autostart.desktop");
			var destination = File.new_for_path(filename);
        	origin.copy(destination, FileCopyFlags.NONE);
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


	public static bool ping(string url)
	{
	    try
		{
	        var resolver = GLib.Resolver.get_default();
	        var addresses = resolver.lookup_by_name(url);

			// if can't resolve url to ip
			if(addresses == null)
				return false;

	        var address = addresses.nth_data(0);
	        var client = new GLib.SocketClient();
	        var conn = client.connect(new GLib.InetSocketAddress(address, 80));

			// if can't establish connection to ip
			if(conn == null)
				return false;

	        var message = @"GET / HTTP/1.1\r\nHost: $url\r\n\r\n";
	        ssize_t bytesWritten = conn.output_stream.write(message.data);

			// if can't write message
			if(bytesWritten == -1)
				return false;

	        var response = new GLib.DataInputStream(conn.input_stream);
	        var status_line = response.read_line(null).strip();

			// if no response received
			if(status_line == null)
				return false;

			return true;
	    }
		catch (Error e)
		{
			logger.print(LogMessage.ERROR, "ping failed: %s".printf(url));
			logger.print(LogMessage.ERROR, e.message);
	    }

		return false;
	}


	public static bool remove_directory(string path, uint level = 0)
	{
		++level;
		bool flag = false;
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


	public static bool haveTags()
	{
		switch(settings_general.get_enum("account-type"))
		{
			case Backend.OWNCLOUD:
				return false;
		}

		if(dataBase.getTagCount() == 0)
		{
			return false;
		}

		return true;
	}


	public static bool onlyShowFeeds()
	{
		if(settings_general.get_boolean("only-feeds"))
			return true;

		if(!dataBase.haveCategories() && !Utils.haveTags() && !dataBase.haveFeedsWithoutCat())
			return true;

		return false;
	}
}
