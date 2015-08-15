public class FeedReader.Utils : GLib.Object {


	public static void generatePreviews(ref GLib.List<article> articles)
	{
		string noPreview = _("No Preview Available");
		foreach(var article in articles)
		{
			if(article.getPreview() != null && article.getPreview() != "")
			{
				continue;
			}
			if(!dataBase.preview_empty(article.getArticleID()))
			{
				//article.setPreview(dataBase.read_preview(article.getArticleID()));
				continue;
			}
			else if(article.getHTML() != "" && article.getHTML() != null)
			{
				string filename = GLib.Environment.get_tmp_dir() + "/" + "articleHtml.XXXXXX";
				int outputfd = GLib.FileUtils.mkstemp(filename);
				try{
					GLib.FileUtils.set_contents(filename, article.getHTML());
				}
				catch(GLib.FileError e){
					logger.print(LogMessage.ERROR, "error writing html to tmp file - %s".printf(e.message));
				}
				GLib.FileUtils.close(outputfd);

				string output = "";
				string[] spawn_args = {"html2text", "-utf8", "-nobs", "-style", "pretty", "-rcfile", "/usr/share/FeedReader/html2textrc", filename};
				try{
					GLib.Process.spawn_sync(null, spawn_args, null , GLib.SpawnFlags.SEARCH_PATH, null, out output, null, null);
				}
				catch(GLib.SpawnError e){
					logger.print(LogMessage.ERROR, "html2text: %s".printf(e.message));
				}

				output = output.strip();

				if(output == "" || output == null)
				{
					logger.print(LogMessage.ERROR, "html2text could not generate preview text");
					article.setPreview(noPreview);
					logger.print(LogMessage.DEBUG, filename);
					continue;
				}

				string xml = "<?xml";

				if(output.has_prefix(xml))
				{
					int end = output.index_of_char('>');
					output = output.slice(end+1, output.length);
				}


				int length = 300;
				if(output.length < length)
					length = output.length;

				output = output.slice(0, length);
				output = output.slice(0, output.last_index_of(" "));
				output = output.strip();

				output = output.replace("\n"," ");
				output = output.replace("_"," ");




				article.setPreview(output);
			}
			else
			{
				logger.print(LogMessage.DEBUG, "no html to create preview from");
				article.setPreview(noPreview);
			}
		}
	}


	public static void checkHTML(ref GLib.List<article> articles)
	{
		foreach(var article in articles)
		{
			string modified_html = _("No Text available for this article :(");
			if(article.getHTML() != "")
			{
				modified_html = article.getHTML().replace("src=\"//","src=\"http://").replace("target=\"_blank\"", "");
			}

			article.setHTML(modified_html);
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
		string[] selectedRow = settings_state.get_string("feedlist-selected-row").split(" ", 2);

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

		var state = (ArticleListState)settings_state.get_boolean("show-articles");
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
			settings_state.get_string("search-term"),
			newArticlesCount,
			0,
			newArticlesCount);

		return articles.length();
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

	public static string buildURL(OAuth serviceType)
	{
		string url = "";

		switch(serviceType)
		{
			case OAuth.FEEDLY:
				url = FeedlySecret.base_uri + "/v3/auth/auth" + "?client_secret=" + FeedlySecret.apiClientSecret + "&client_id=" + FeedlySecret.apiClientId
					+ "&redirect_uri=" + FeedlySecret.apiRedirectUri + "&scope=" + FeedlySecret.apiAuthScope + "&response_type=code&state=getting_code";
				break;

			case OAuth.READABILITY:
				url = ReadabilitySecrets.base_uri + "oauth/authorize/" + "?oauth_token=" + settings_readability.get_string("oauth-request-token");
				break;

			case OAuth.POCKET:
				url = "https://getpocket.com/auth/authorize?request_token="
						+ settings_pocket.get_string("oauth-request-token")
						+ "&redirect_uri=" + GLib.Uri.escape_string(PocketSecrets.oauth_callback);
				break;

			case OAuth.INSTAPAPER:
				break;

			case OAuth.EVERNOTE:
				url = EvernoteSecrets.base_uri
					+ "OAuth.action?oauth_token="
					+ settings_evernote.get_string("oauth-request-token")
					+ "&supportLinkedSandbox=true&suggestedNotebookName="
					+ GLib.Uri.escape_string("FeedReader");
				break;
		}

		logger.print(LogMessage.DEBUG, url);
		return url;
	}


	public static OAuth parseArg(string arg)
	{
		if(arg == PocketSecrets.oauth_callback)
			return OAuth.POCKET;

		if(arg == InstapaperSecrets.oauth_callback)
			return OAuth.INSTAPAPER;

		if(arg == FeedlySecret.apiRedirectUri)
			return OAuth.FEEDLY;

		if(arg.has_prefix(EvernoteSecrets.oauth_callback))
		{
			string needle = "verifier=";
			int verifier_start = arg.index_of(needle)+(needle.length);
			if(verifier_start != -1)
			{
				int verifier_end = arg.index_of("&", verifier_start);
				string verifier = arg.substring(verifier_start, verifier_end-verifier_start);
				settings_evernote.set_string("oauth-verifier", verifier);
			}
			return OAuth.EVERNOTE;
		}

		if(arg.has_prefix(ReadabilitySecrets.oauth_callback))
		{
			int verifier_start = arg.index_of("=")+1;
			int verifier_end = arg.index_of("&", verifier_start);
			string verifier = arg.substring(verifier_start, verifier_end-verifier_start);
			settings_readability.set_string("oauth-verifier", verifier);
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

}
