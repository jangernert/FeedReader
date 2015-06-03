public class FeedReader.Utils : GLib.Object {


	public static void generatePreviews(ref GLib.List<article> articles)
	{
		string noPreview = _("No Preview Available");
		foreach(var article in articles)
		{
			if(!dataBase.preview_empty(article.getArticleID()))
			{
				article.setPreview(dataBase.read_preview(article.getArticleID()));
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
				string[] spawn_args = {"html2text", "-utf8", "-nobs", "-style", "pretty", filename};
				try{
					GLib.Process.spawn_sync(null, spawn_args, null , GLib.SpawnFlags.SEARCH_PATH, null, out output, null, null);
				}
				catch(GLib.SpawnError e){
					logger.print(LogMessage.ERROR, "html2text: %s".printf(e.message));
				}

				if(output == "" || output == null)
				{
					article.setPreview(noPreview);
					continue;
				}

				string prefix1 = "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>";
				string prefix2 = "<?xml version=\"1.0\"?>";

				if(output.has_prefix(prefix1))
					output = output.slice(prefix1.length, output.length);

				if(output.has_prefix(prefix2))
					output = output.slice(prefix2.length, output.length);

				int length = 300;
				if(output.length < 300)
					length = output.length;

				var replaceList = new GLib.List<StringReplace>();
				replaceList.append(new StringReplace("\n", " "));
				replaceList.append(new StringReplace("&#xD;", " "));
				replaceList.append(new StringReplace("_", " "));
				replaceList.append(new StringReplace("&#xE4;", "ä"));
				replaceList.append(new StringReplace("&#xF6;", "ö"));
				replaceList.append(new StringReplace("&#xFC;", "ü"));
				replaceList.append(new StringReplace("&#xDC;", "Ü"));
				replaceList.append(new StringReplace("&#x201E;", "„"));
				replaceList.append(new StringReplace("&#x201D;", "”"));
				replaceList.append(new StringReplace("&#xA0;", " "));
				replaceList.append(new StringReplace("&#x2019;", "´"));
				replaceList.append(new StringReplace("&#xDF;", "ß"));


				//output = output.replace("\n"," ");
				//output = output.replace("_"," ");

				foreach(var pair in replaceList)
				{
					output = output.replace(pair.getToReplace(),pair.getReplaceWith());
				}


				output = output.slice(0, length);
				output = output.slice(0, output.last_index_of(" "));
				output = output.chug();

				article.setPreview(output);
			}
			else
			{
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

		int IDtype = 0;

		logger.print(LogMessage.DEBUG, "selectedRow 0: %s".printf(selectedRow[0]));
		logger.print(LogMessage.DEBUG, "selectedRow 1: %s".printf(selectedRow[1]));

		switch(selectedRow[0])
		{
			case "feed":
				IDtype = FeedList.FEED;
				break;

			case "cat":
				IDtype = FeedList.CATEGORY;
				break;

			case "tag":
				IDtype = FeedList.TAG;
				break;
		}

		var articles = dataBase.read_articles(
			selectedRow[1],
			IDtype,
			settings_state.get_boolean("only-unread"),
			settings_state.get_boolean("only-marked"),
			settings_state.get_string("search-term"),
			newArticlesCount,
			0,
			newArticlesCount);

		return articles.length();
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

}
