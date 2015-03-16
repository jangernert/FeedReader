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

				string prefix = "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>";
				if(output.has_prefix(prefix))
					output = output.slice(prefix.length, output.length);

				int length = 300;
				if(output.length < 300)
					length = output.length;

				output = output.replace("\n"," ");
				output = output.replace("_"," ");
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
				modified_html = article.getHTML().replace("src=\"//","src=\"http://");
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

	public static string buildArticle(string html, string title, string url, string author, string date, string feedID)
	{
		var article = new GLib.StringBuilder();
		string author_date = "posted by %s %s".printf(author, date);

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
