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

public class FeedReader.Grabber : GLib.Object {
	private string m_articleURL;
	private string? m_articleID;
	private string? m_feedID;
	private string m_rawHtml;
	private string m_nexPageURL;
	private GrabberConfig m_config;
	private Soup.Session m_session;
	private bool m_firstPage;
	private Html.Doc* m_doc;
	private Xml.Node* m_root;
	private Xml.Ns* m_ns;
	private bool m_foundSomething;
	private bool m_singlePage;


	public string m_author;
	public string m_title;
	public string m_date;
	public string m_html;

	public Grabber(Soup.Session session, string articleURL, string? articleID, string? feedID)
	{
		m_articleURL = articleURL;
		m_articleID = articleID;
		m_feedID = feedID;
		m_firstPage = true;
		m_foundSomething = false;
		m_singlePage = false;
		m_session = session;

		if(m_articleURL.has_prefix("//"))
			m_articleURL = "http:" + m_articleURL;
	}

	~Grabber()
	{
		delete m_doc;
		delete m_root;
		delete m_ns;
	}

	private bool checkConfigFile()
	{
		string filepath = Constants.INSTALL_PREFIX + "/share/FeedReader/GrabberConfig/";

		string hostName = grabberUtils.buildHostName(m_articleURL, false);
		string filename = filepath + hostName + ".txt";
		if(FileUtils.test(filename, GLib.FileTest.EXISTS))
		{
			m_config = new GrabberConfig(filename);
			Logger.debug("Grabber: using config %s.txt".printf(hostName));
			return true;
		}

		Logger.debug("Grabber: no config (%s.txt) found for article: %s".printf(hostName, m_articleURL));

		string newHostName = grabberUtils.buildHostName(m_articleURL, true);
		if(hostName != newHostName)
		{
			filename = filepath + newHostName + ".txt";
			if(FileUtils.test("%s%s.txt".printf(filename, newHostName), GLib.FileTest.EXISTS))
			{
				m_config = new GrabberConfig(filename);
				Logger.debug("Grabber: using config %s.txt".printf(newHostName));
				return true;
			}
		}


		Logger.debug("Grabber: no config (%s.txt) - cutSubdomain - found for article: %s".printf(newHostName, m_articleURL));
		return false;
	}

	public bool process(GLib.Cancellable? cancellable = null)
	{
		Logger.debug("Grabber: process article: " + m_articleURL);

		var uri = new Soup.URI(m_articleURL);
		if(uri == null)
		{
			Logger.error("No valid article-url?!?");
			return false;
		}

		if(!checkContentType())
			return false;

		if(cancellable != null && cancellable.is_cancelled())
			return false;

		bool downloaded = false;

		if(!checkConfigFile())
		{
			// special treatment for sites like youtube
			string youtube = "youtube.com/watch?v=";
			if(m_articleURL.contains(youtube))
			{
				Logger.debug("Grabber: special treatment - youtube video");
				string ytHTML = "<div class=\"videoWrapper\"><iframe width=\"100%\" src=\"https://www.youtube.com/embed/%s\" frameborder=\"0\" allowfullscreen></iframe></div>";
				int start = m_articleURL.index_of(youtube) + youtube.length;
				int end = m_articleURL.index_of("?", start);
				string id = m_articleURL.substring(start, (end == -1) ? -1 : end-start);

				m_html = ytHTML.printf(id);
				return true;
			}

			string oldURL = m_articleURL;

			// download to check if website redirects
			downloaded = download();

			// if URL is different now after redirect
			if(m_articleURL != oldURL)
			{
				// check again after possible redirect
				if(!checkConfigFile())
					return false;
			}
			else
			{
				// url is still the same, so we don't have a grabber config
				return false;
			}
		}

		if(cancellable != null && cancellable.is_cancelled())
			return false;

		Logger.debug("Grabber: config found");

		if(!downloaded && !download())
			return false;


		Logger.debug("Grabber: download success");

		prepArticle();

		Logger.debug("Grabber: empty article preped");

		if(!parse(cancellable))
			return false;

		if(!m_foundSomething)
		{
			Logger.error("Grabber: no body found");
			return false;
		}

		return true;
	}

	private bool checkContentType()
	{
		Logger.debug("Grabber: check contentType");
		var message = new Soup.Message("HEAD", m_articleURL.escape(""));

		if(message == null)
			return false;

		m_session.send_message(message);
		var params = new GLib.HashTable<string, string>(null, null);
		string? contentType = message.response_headers.get_content_type(out params);
		if(contentType != null)
		{
			if(contentType == "text/html")
				return true;
		}

		Logger.debug(@"Grabber: type $contentType");
		Logger.debug(@"Grabber: type != text/html so not going to proceed further");

		return false;
	}

	private bool download()
	{
		var msg = new Soup.Message("GET", m_articleURL.escape(""));
		msg.restarted.connect(() => {
			Logger.debug("Grabber: download redirected - " + msg.status_code.to_string());
			if(msg.status_code == Soup.Status.MOVED_TEMPORARILY
			|| msg.status_code == Soup.Status.MOVED_PERMANENTLY)
			{
				m_articleURL = msg.uri.to_string(false);
				Logger.debug(@"Grabber: new url is: $m_articleURL");
			}
		});

		if(msg == null)
			return false;

		if(Settings.tweaks().get_boolean("do-not-track"))
			msg.request_headers.append("DNT", "1");

		m_session.send_message(msg);

		if(msg.response_body == null)
		{
			Logger.debug("Grabber: download failed - no response");
			return false;
		}

		if((string)msg.response_body.flatten().data == "")
		{
			Logger.debug("Grabber: download failed - empty response");
			return false;
		}

		m_rawHtml = (string)msg.response_body.flatten().data;
		if(!m_rawHtml.validate())
		{
			string needle = "content=\"text/html; charset=";
			int start = m_rawHtml.index_of(needle) + needle.length;
			string locale = "";

			if(start != -1)
			{
				int end = m_rawHtml.index_of("\"", start);
				locale = m_rawHtml.substring(start, end-start);
			}
			else
			{
				needle = "charset=\"";
				start = m_rawHtml.index_of(needle) + needle.length;
				if(start != -1)
				{
					int end = m_rawHtml.index_of("\"", start);
					locale = m_rawHtml.substring(start, end-start);
				}
				else
				{
					return false;
				}
			}

			Logger.info(locale);
			try
			{
				m_rawHtml = GLib.convert(m_rawHtml, -1, "utf-8", locale);
			}
			catch(ConvertError e)
			{
				Logger.error("grabber: failed to convert locale - " + e.message);
			}
		}

		return true;
	}

	private bool parse(GLib.Cancellable? cancellable = null)
	{
		m_nexPageURL = null;
		Logger.debug("Grabber: start parsing");

		// replace strings before parsing html
		unowned Gee.ArrayList<StringPair> replace = m_config.getReplace();
		if(replace.size != 0)
		{
			foreach(StringPair pair in replace)
			{
				m_rawHtml = m_rawHtml.replace(pair.getString1(), pair.getString2());
			}
		}

		Logger.debug("Grabber: parse html");

		// parse html
		var html_cntx = new Html.ParserCtxt();
		html_cntx.use_options(Html.ParserOption.NOERROR + Html.ParserOption.NOWARNING);
		var doc = html_cntx.read_doc(m_rawHtml, "");
		if(doc == null)
		{
			Logger.debug("Grabber: parsing failed");
			return false;
		}

		Logger.debug("Grabber: html parsed");


		// get link to next page of article if there are more than one pages
		if(m_config.getXPathNextPageURL() != null)
		{
			Logger.debug("Grabber: grab next page url");
			m_nexPageURL = grabberUtils.getURL(doc, m_config.getXPathNextPageURL());
		}

		// get link to single-page view if it exists and download that page
		if(m_config.getXPathSinglePageURL() != null && m_nexPageURL == null)
		{
			Logger.debug("Grabber: grab single page view");
			string url = grabberUtils.getURL(doc, m_config.getXPathSinglePageURL());
			if(url != "" && url != null)
			{
				if(!url.has_prefix("http"))
		        {
		            url = grabberUtils.completeURL(url, m_articleURL);
		        }
				Logger.debug("Grabber: single page url " + url);
				m_singlePage = true;
				m_articleURL = url;
				download();
				delete doc;
				doc = html_cntx.read_doc(m_rawHtml, "");
			}
		}

		// get the title from the html (useful if feed doesn't provide one)
		unowned Gee.ArrayList<string> title = m_config.getXPathTitle();
		if(title.size != 0 && m_firstPage)
		{
			Logger.debug("Grabber: get title");
			foreach(string xpath in title)
			{
				string tmptitle = grabberUtils.getValue(doc, xpath, m_firstPage);
				if(tmptitle != null && tmptitle != "")
					m_title = tmptitle.chomp().chug();
			}
		}

		if(cancellable != null && cancellable.is_cancelled())
		{
			delete doc;
			return false;
		}

		// get the author from the html (useful if feed doesn't provide one)
		unowned Gee.ArrayList<string> author = m_config.getXPathAuthor();
		if(author.size != 0)
		{
			Logger.debug("Grabber: get author");
			foreach(string xpath in author)
			{
				string tmpAuthor = grabberUtils.getValue(doc, xpath);
				if(tmpAuthor != null)
					m_author = tmpAuthor.chomp().chug();
			}
		}

		if(cancellable != null && cancellable.is_cancelled())
		{
			delete doc;
			return false;
		}

		// get the date from the html (useful if feed doesn't provide one)
		unowned Gee.ArrayList<string> date = m_config.getXPathDate();
		if(date.size != 0)
		{
			Logger.debug("Grabber: get date");
			foreach(string xpath in date)
			{
				string tmpDate = grabberUtils.getValue(doc, xpath);
				if(tmpDate != null)
					m_date = tmpDate.chomp().chug();
			}
		}

		if(cancellable != null && cancellable.is_cancelled())
		{
			delete doc;
			return false;
		}

		// strip junk
		unowned Gee.ArrayList<string> strip = m_config.getXPathStrip();
		if(strip.size != 0)
		{
			Logger.debug("Grabber: strip junk");
			foreach(string xpath in strip)
			{
				Logger.debug("Grabber: strip %s".printf(xpath));
				grabberUtils.stripNode(doc, xpath);
			}
		}

		if(cancellable != null && cancellable.is_cancelled())
		{
			delete doc;
			return false;
		}

		// strip any element whose @id or @class contains this substring
		unowned Gee.ArrayList<string> _stripIDorClass = m_config.getXPathStripIDorClass();
		if(_stripIDorClass.size != 0)
		{
			Logger.debug("Grabber: strip id's and class");
			foreach(string IDorClass in _stripIDorClass)
			{
				grabberUtils.stripIDorClass(doc, IDorClass);
			}
		}

		if(cancellable != null && cancellable.is_cancelled())
		{
			delete doc;
			return false;
		}

		//strip any <img> element where @src attribute contains this substring
		unowned Gee.ArrayList<string> stripImgSrc = m_config.getXPathStripImgSrc();
		if(stripImgSrc.size != 0)
		{
			Logger.debug("Grabber: strip img-tags");
			foreach(string ImgSrc in stripImgSrc)
			{
				grabberUtils.stripNode(doc, "//img[contains(@src,'%s')]".printf(ImgSrc));
			}
		}

		if(cancellable != null && cancellable.is_cancelled())
		{
			delete doc;
			return false;
		}

		grabberUtils.fixLazyImg(doc, "lazyload", "data-src");
		grabberUtils.fixIframeSize(doc, "youtube.com");
		grabberUtils.removeAttributes(doc, null, "style");
		grabberUtils.removeAttributes(doc, "a", "onclick");
		grabberUtils.removeAttributes(doc, "img", "srcset");
		grabberUtils.removeAttributes(doc, "img", "sizes");
		grabberUtils.addAttributes(doc, "a", "target", "_blank");

		if(cancellable != null && cancellable.is_cancelled())
		{
			delete doc;
			return false;
		}

		// complete relative source urls of images
		Logger.debug("Grabber: complete urls");
		grabberUtils.repairURL("//img", "src", doc, m_articleURL);
		grabberUtils.repairURL("//a", "src", doc, m_articleURL);
		grabberUtils.repairURL("//a", "href", doc, m_articleURL);
		grabberUtils.repairURL("//object", "data", doc, m_articleURL);
		grabberUtils.repairURL("//iframe", "src", doc, m_articleURL);

		// strip elements using Readability.com and Instapaper.com ignore class names
		// .entry-unrelated and .instapaper_ignore
		// See https://www.readability.com/publishers/guidelines/#view-plainGuidelines
		// and http://blog.instapaper.com/post/730281947
		Logger.debug("Grabber: strip instapaper and readability");
		grabberUtils.stripNode(doc,
				"//*[contains(concat(' ',normalize-space(@class),' '),' entry-unrelated ') or contains(concat(' ',normalize-space(@class),' '),' instapaper_ignore ')]");

		if(cancellable != null && cancellable.is_cancelled())
		{
			delete doc;
			return false;
		}

		// strip elements that contain style="display: none;"
		Logger.debug("Grabber: strip invisible elements");
		grabberUtils.stripNode(doc, "//*[contains(@style,'display:none')]");

		// strip all scripts
		Logger.debug("Grabber: strip all scripts");
		grabberUtils.stripNode(doc, "//script");

		// strip <noscript>
		Logger.debug("Grabber: strip all <noscript>");
		grabberUtils.onlyRemoveNode(doc, "//noscript");

		// strip all comments
		Logger.debug("Grabber: strip all comments");
		grabberUtils.stripNode(doc, "//comment()");

		// strip all empty url-tags <a/>
		Logger.debug("Grabber: strip all empty url-tags");
		grabberUtils.stripNode(doc, "//a[not(node())]");

		// strip all external css and fonts
		Logger.debug("Grabber: strip all external css and fonts");
		grabberUtils.stripNode(doc, "//*[@type='text/css']");

		if(cancellable != null && cancellable.is_cancelled())
		{
			delete doc;
			return false;
		}

		// get the content of the article
		unowned Gee.ArrayList<string> bodyList = m_config.getXPathBody();
		if(bodyList.size != 0)
		{
			Logger.debug("Grabber: get body");
			foreach(string bodyXPath in bodyList)
			{
				if(grabberUtils.extractBody(doc, bodyXPath, m_root))
					m_foundSomething = true;
				else
					Logger.error(bodyXPath);
			}

			if(m_foundSomething)
			{
				Logger.debug("Grabber: body found");
			}
			else
			{
				Logger.debug("Grabber: no body found");
				return false;
			}
		}
		else
		{
			Logger.error("Grabber: config file has no rule for 'body'");
		}

		delete doc;

		if(cancellable != null && cancellable.is_cancelled())
			return false;

		m_firstPage = false;

		if(m_nexPageURL != null && !m_singlePage)
		{
			Logger.debug("Grabber: load next page");
			if(!m_nexPageURL.has_prefix("http"))
			{
				m_nexPageURL = grabberUtils.completeURL(m_nexPageURL, m_articleURL);
			}
			m_articleURL = m_nexPageURL;
			Logger.debug("Grabber: next page url: %s".printf(m_nexPageURL));
			download();
			parse(cancellable);
			return true;
		}

		if(Settings.general().get_boolean("download-images"))
		{
			if(m_articleID != null && m_feedID != null)
				grabberUtils.saveImages(m_session, m_doc, m_articleID, m_feedID, cancellable);
			else
				grabberUtils.saveImages(m_session, m_doc, "", "", cancellable);
		}

		if(cancellable != null && cancellable.is_cancelled())
			return false;

		m_doc->dump_memory_enc(out m_html);
		m_html = grabberUtils.postProcessing(ref m_html);
		return true;
	}

	private void prepArticle()
	{
		m_doc = new Html.Doc("1.0");
		m_ns = new Xml.Ns(null, "", "article");
		m_ns->type = Xml.ElementType.ELEMENT_NODE;
		m_root = new Xml.Node(m_ns, "body");
		m_doc->set_root_element(m_root);
	}

	public string getArticle()
	{
		return m_html;
	}

	public void print()
	{
		if(m_title != null)
			Logger.debug("Grabber: title: %s".printf(m_title));

		if(m_author != null)
			Logger.debug("Grabber: author: %s".printf(m_author));

		if(m_date != null)
			Logger.debug("Grabber: date: %s".printf(m_date));
	}

	public string? getAuthor()
	{
		return m_author;
	}

	public string? getTitle()
	{
		return m_title;
	}
}
