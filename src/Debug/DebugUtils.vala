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

public class FeedReader.DebugUtils : GLib.Object {

	private const string dummyHTML =
	"""
		<h1>HTML Ipsum Presents</h1>
		<p>
			<strong>Pellentesque habitant morbi tristique</strong> senectus et netus et malesuada fames ac turpis egestas.
			Vestibulum tortor quam, feugiat vitae, ultricies eget, tempor sit amet, ante.
			Donec eu libero sit amet quam egestas semper.
			<em>Aenean ultricies mi vitae est.</em> Mauris placerat eleifend leo.
			Quisque sit amet est et sapien ullamcorper pharetra.
			Vestibulum erat wisi, condimentum sed, <code>commodo vitae</code>, ornare sit amet, wisi.
			Aenean fermentum, elit eget tincidunt condimentum, eros ipsum rutrum orci, sagittis tempus lacus enim ac dui.
			<a href="#">Donec non enim</a> in turpis pulvinar facilisis. Ut felis.
		</p>
		<h2>Header Level 2</h2>
		<ol>
		   <li>Lorem ipsum dolor sit amet, consectetuer adipiscing elit.</li>
		   <li>Aliquam tincidunt mauris eu risus.</li>
		</ol>
		<blockquote>
			<p>
				Lorem ipsum dolor sit amet, consectetur adipiscing elit.
				Vivamus magna. Cras in mi at felis aliquet congue. Ut a est eget ligula molestie gravida.
				Curabitur massa. Donec eleifend, libero at sagittis mollis, tellus est malesuada tellus, at luctus turpis elit sit amet quam.
				Vivamus pretium ornare est.
			</p>
		</blockquote>
		<h3>Header Level 3</h3>
		<ul>
		   <li>Lorem ipsum dolor sit amet, consectetuer adipiscing elit.</li>
		   <li>Aliquam tincidunt mauris eu risus.</li>
		</ul>
		<pre><code>
		#header h1 a {
			display: block;
			width: 300px;
			height: 80px;
		}
		</code></pre>
	""";

	private const string dummyPreview =
	"""
		Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor
		invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et
		justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem
		ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy
		eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et
		accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem
		ipsum dolor sit amet.
	""";

	public static void grabArticle(string url)
	{
		var grabber = new Grabber(url, null, null);
		if(grabber.process())
		{
			grabber.print();

			string html = grabber.getArticle();
			string title = Utils.UTF8fix(grabber.getTitle());
			string xml = "<?xml";

			while(html.has_prefix(xml))
			{
				int end = html.index_of_char('>');
				html = html.slice(end+1, html.length).chug();
			}

			string path = GLib.Environment.get_home_dir() + "/debug-article/%s.html".printf(title);

			if(FileUtils.test(path, GLib.FileTest.EXISTS))
				GLib.FileUtils.remove(path);

			var file = GLib.File.new_for_path(path);
			var stream = file.create(FileCreateFlags.REPLACE_DESTINATION);

			stream.write(html.data);
			logger.print(LogMessage.DEBUG, "Grabber: article html written to " + path);

			string output = libVilistextum.parse(html, 1);

			if(output == "" || output == null)
			{
				logger.print(LogMessage.ERROR, "could not generate preview text");
				return;
			}

			output = output.replace("\n"," ");
			output = output.replace("_"," ");

			path = GLib.Environment.get_home_dir() + "/debug-article/%s.txt".printf(title);

			if(FileUtils.test(path, GLib.FileTest.EXISTS))
				GLib.FileUtils.remove(path);

			file = GLib.File.new_for_path(path);
			stream = file.create(FileCreateFlags.REPLACE_DESTINATION);

			stream.write(output.data);
			logger.print(LogMessage.DEBUG, "Grabber: preview written to " + path);
		}
		else
		{
			logger.print(LogMessage.ERROR, "Grabber: article could not be processed " + url);
		}
	}

	public static void grabImages(string htmlFile, string url)
	{
		var html_cntx = new Html.ParserCtxt();
        html_cntx.use_options(Html.ParserOption.NOERROR + Html.ParserOption.NOWARNING);
        Html.Doc* doc = html_cntx.read_file(htmlFile);
        if (doc == null)
        {
            logger.print(LogMessage.DEBUG, "Grabber: parsing failed");
    		return;
    	}
		grabberUtils.repairURL("//img", "src", doc, url);
		grabberUtils.saveImages(doc, "", "");

		string html = "";
		doc->dump_memory_enc(out html);
        html = html.replace("<h3/>", "<h3></h3>");

    	int pos1 = html.index_of("<iframe", 0);
    	int pos2 = -1;
    	while(pos1 != -1)
    	{
    		pos2 = html.index_of("/>", pos1);
    		string broken_iframe = html.substring(pos1, pos2+2-pos1);
    		string fixed_iframe = broken_iframe.substring(0, broken_iframe.length) + "></iframe>";
    		html = html.replace(broken_iframe, fixed_iframe);
    		int pos3 = html.index_of("<iframe", pos1+7);
    		if(pos3 == pos1)
    			break;
    		else
    			pos1 = pos3;
    	}

		var file = GLib.File.new_for_path(GLib.Environment.get_home_dir() + "/debug-article/ArticleLocalImages.html");
		var stream = file.create(FileCreateFlags.REPLACE_DESTINATION);
		stream.write(html.data);
		delete doc;
	}

	public static void dummyFeeds(int catcount, int feedcount)
	{
		var cats = new Gee.LinkedList<category>();
		var feeds = new Gee.LinkedList<feed>();

		for(int i = 1; i <= catcount; ++i)
		{
			cats.add(new category(i.to_string(), "dummy category %i".printf(i), 0, i, CategoryID.MASTER, 1));
		}

		foreach(category cat in cats)
		{
			for(int i = 1; i <= feedcount; ++i)
			{
				feeds.add(new feed("%s%i".printf(cat.getCatID(), i), "dummy feed %s.%i".printf(cat.getCatID(),i), "https://www.google.com/", false, 0, {cat.getCatID()}));
			}
		}

		// write categories
		dataBase.reset_exists_flag();
		dataBase.write_categories(cats);
		dataBase.delete_nonexisting_categories();

		// write feeds
		dataBase.reset_subscribed_flag();
		dataBase.write_feeds(feeds);
		dataBase.delete_articles_without_feed();
		dataBase.delete_unsubscribed_feeds();
	}

	public static void dummyArticles(int count, int newCount)
	{
		logger.print(LogMessage.DEBUG, "DebugUtils: insert dummy Articles");
		if(newCount > count)
			return;

		int oldCount = count - newCount;

		var feeds = dataBase.read_feeds();
		int feedCount = feeds.size;
		var random = new GLib.Rand.with_seed(0);
		var articles = new Gee.LinkedList<article>();

		int newestArticle = dataBase.getHighestRowID();

		for(int i = 0; i < newCount; ++i)
		{
			int feedNumber = random.int_range(0, feedCount);
			string feedID = feeds.get(feedNumber).getFeedID();
			++newestArticle;

			var Article = new article(
									newestArticle.to_string(),
									"dummy Article",
									"http://jangernert.github.io/FeedReader/",
									feedID,
									ArticleStatus.UNREAD,
									ArticleStatus.UNMARKED,
									dummyHTML,
									dummyPreview.replace("\n", " "),
									"John Doe",
									new DateTime.now_local(),
									-1,
									""
							);
			articles.add(Article);
		}

		var oldArticles = dataBase.read_articles(FeedID.ALL, FeedListType.FEED, false, false, "", oldCount);
		foreach(var Article in oldArticles)
		{
			articles.add(Article);
		}

		dataBase.update_articles(articles);
		dataBase.write_articles(articles);
	}
}
