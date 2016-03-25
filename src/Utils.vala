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
		logger.print(LogMessage.DEBUG, "Utils: generatePreviews");
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
					string output = libVilistextum.parse(Article.getHTML(), 1);
					output = output.strip();

					if(output == "" || output == null)
					{
						logger.print(LogMessage.ERROR, "generatePreviews: no Preview");
						Article.setPreview(noPreview);
						Article.setTitle(UTF8fix(Article.getTitle()));
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

					Article.setPreview(output);
				}
				else
				{
					logger.print(LogMessage.DEBUG, "no html to create preview from");
					Article.setPreview(noPreview);
				}
				Article.setTitle(UTF8fix(Article.getTitle()));
			}
		}
	}

	public static string UTF8fix(string old_string)
	{
		string? output = libVilistextum.parse(old_string, 0);

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
		selectedRow = settings_state.get_string("feedlist-selected-row").split(" ", 2);
		state = (ArticleListState)settings_state.get_enum("show-articles");
		if(settings_tweaks.get_boolean("restore-searchterm"))
			searchTerm = settings_state.get_string("search-term");

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

		logger.print(LogMessage.DEBUG, "getRelevantArticles: %u".printf(articles.size));
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

		string theme_id = "$THEME";
		int theme_pos = article.str.index_of(theme_id);
		article.erase(theme_pos, theme_id.length);
		article.insert(theme_pos, theme);

		string select_id = "$UNSELECTABLE";
		int select_pos = article.str.index_of(select_id);

		if(settings_tweaks.get_boolean("article-select-text"))
		{
			article.erase(select_pos-1, select_id.length+1);
		}
		else
		{
			article.erase(select_pos, select_id.length);
			article.insert(select_pos, "unselectable");
		}


		string fontsize = "intial";
		string sourcefontsize = "0.75rem";
		switch(settings_general.get_enum("fontsize"))
		{
			case FontSize.SMALL:
				fontsize = "smaller";
				sourcefontsize = "0.5rem";
				break;

			case FontSize.NORMAL:
				fontsize = "medium";
				sourcefontsize = "0.75rem";
				break;

			case FontSize.LARGE:
				fontsize = "large";
				sourcefontsize = "1.0rem";
				break;

			case FontSize.HUGE:
				fontsize = "xx-large";
				sourcefontsize = "1.2rem";
				break;
		}

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


		string css;
		try{
			GLib.FileUtils.get_contents("/usr/share/FeedReader/ArticleView/style.css", out css);
		}
		catch(GLib.Error e){
			logger.print(LogMessage.ERROR, e.message);
		}
		string css_id = "$CSS";
		int css_pos = article.str.index_of(css_id);
		article.erase(css_pos, css_id.length);
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

	public static void copyAutostart()
	{
		string filename = GLib.Environment.get_home_dir() + "/.config/autostart/feedreader-autostart.desktop";

		if(settings_tweaks.get_boolean("feedreader-autostart") && !FileUtils.test(filename, GLib.FileTest.EXISTS))
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
}
