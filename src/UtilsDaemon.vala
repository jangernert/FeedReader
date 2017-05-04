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

public class FeedReader.UtilsDaemon : GLib.Object {

    public static void generatePreviews(Gee.List<article> articles)
	{
		string noPreview = _("No Preview Available");
		foreach(var Article in articles)
		{
			if(!dbDaemon.get_default().article_exists(Article.getArticleID()))
			{
				if(Article.getPreview() != null && Article.getPreview() != "")
				{
					continue;
				}
				if(!dbDaemon.get_default().preview_empty(Article.getArticleID()))
				{
					continue;
				}
				else if(Article.getHTML() != "" && Article.getHTML() != null)
				{
					Logger.debug("Utils: generate preview for article: " + Article.getArticleID());
					string output = libVilistextum.parse(Article.getHTML(), 1);
					output = output.strip();

					if(output == "" || output == null)
					{
						Logger.error("generatePreviews: no Preview");
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

    public static void checkHTML(Gee.List<article> articles)
	{
		foreach(var Article in articles)
		{
			if(!dbDaemon.get_default().article_exists(Article.getArticleID()))
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

    public static uint getRelevantArticles(int newArticlesCount)
	{
		string[] selectedRow = {};
		ArticleListState state = ArticleListState.ALL;
		string searchTerm = "";
		string topRow = Settings.state().get_string("articlelist-top-row");
		selectedRow = Settings.state().get_string("feedlist-selected-row").split(" ", 2);
		state = (ArticleListState)Settings.state().get_enum("show-articles");
		if(Settings.tweaks().get_boolean("restore-searchterm"))
			searchTerm = Settings.state().get_string("search-term");

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

		int count = dbDaemon.get_default().getArticleCountNewerThanID(topRow, selectedRow[1], IDtype, state, searchTerm);

		Logger.debug(@"getRelevantArticles: $count");
		return count;
	}

}
