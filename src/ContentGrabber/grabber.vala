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
    private bool m_firstPage;
    private string m_hostName;
    private Html.Doc* m_doc;
    private Xml.Node* m_root;
    private Xml.Ns* m_ns;
    private bool m_foundSomething;
    private bool m_singlePage;


    public string m_author;
    public string m_title;
    public string m_date;
    public string m_html;

    public Grabber(string articleURL, string? articleID, string? feedID)
    {
        m_articleURL = articleURL;
        m_articleID = articleID;
        m_feedID = feedID;
        m_firstPage = true;
        m_foundSomething = false;
        m_singlePage = false;
    }

    ~Grabber()
    {
        delete m_doc;
        delete m_root;
        delete m_ns;
    }

    private bool checkConfigFile()
    {
        string filepath = "/usr/share/FeedReader/GrabberConfig/";

        m_hostName = grabberUtils.buildHostName(m_articleURL, false);
        string filename = filepath + m_hostName + ".txt";
        if(FileUtils.test(filename, GLib.FileTest.EXISTS))
        {
            m_config = new GrabberConfig(filename);
            logger.print(LogMessage.DEBUG, "Grabber: using config %s.txt".printf(m_hostName));
            return true;
        }

        logger.print(LogMessage.DEBUG, "Grabber: no config (%s.txt) found for article: %s".printf(m_hostName, m_articleURL));

        m_hostName = grabberUtils.buildHostName(m_articleURL, true);
        filename = filepath + m_hostName + ".txt";
        if(FileUtils.test("%s%s.txt".printf(filename, m_hostName), GLib.FileTest.EXISTS))
        {
            m_config = new GrabberConfig(filename);
            logger.print(LogMessage.DEBUG, "Grabber: using config %s.txt".printf(m_hostName));
            return true;
        }

        logger.print(LogMessage.DEBUG, "Grabber: no config (%s.txt) found for article: %s".printf(m_hostName, m_articleURL));
        return false;
    }

    public bool process()
    {
        logger.print(LogMessage.DEBUG, "Grabber: process article: " + m_articleURL);
        bool downloaded = false;

        if(!checkConfigFile())
        {
            // download to check if website redirects
            downloaded = download();

            // check page for feedsportal
            if(!checkConfigFile())
                return false;
        }

        logger.print(LogMessage.DEBUG, "Grabber: config found");

        if(!downloaded && !download())
            return false;


        logger.print(LogMessage.DEBUG, "Grabber: download success");

        prepArticle();

        logger.print(LogMessage.DEBUG, "Grabber: empty article preped");

        if(!parse())
            return false;

        if(!m_foundSomething)
        {
            logger.print(LogMessage.ERROR, "Grabber: no body found");
            return false;
        }

        return true;
    }

    private bool download()
    {
        var session = new Soup.Session();
        session.timeout = 5;
        var msg = new Soup.Message("GET", m_articleURL);
        msg.restarted.connect(() => {
            if(msg.status_code == Soup.Status.MOVED_TEMPORARILY)
            {
                logger.print(LogMessage.DEBUG, "Grabber: download redirected - \"302 Moved Temporarily\"");
                m_articleURL = msg.uri.to_string(false);
                logger.print(LogMessage.DEBUG, "Grabber: new url is: " + m_articleURL);
            }
        });

        if(settings_tweaks.get_boolean("do-not-track"))
			msg.request_headers.append("DNT", "1");

        session.send_message(msg);

        if(msg.response_body == null)
            return false;

        m_rawHtml = (string)msg.response_body.flatten().data;
        return true;
    }

    private bool parse()
    {
        m_nexPageURL = null;
        logger.print(LogMessage.DEBUG, "Grabber: start parsing");

        // replace strings before parsing html
        unowned Gee.ArrayList<StringPair> replace = m_config.getReplace();
        if(replace.size != 0)
        {
            foreach(StringPair pair in replace)
            {
                m_rawHtml = m_rawHtml.replace(pair.getString1(), pair.getString2());
            }
        }

        logger.print(LogMessage.DEBUG, "Grabber: parse html");

        // parse html
        var html_cntx = new Html.ParserCtxt();
        html_cntx.use_options(Html.ParserOption.NOERROR + Html.ParserOption.NOWARNING);
        var doc = html_cntx.read_doc(m_rawHtml, "");
        if (doc == null)
        {
            logger.print(LogMessage.DEBUG, "Grabber: parsing failed");
    		return false;
    	}

        logger.print(LogMessage.DEBUG, "Grabber: html parsed");


        // get link to next page of article if there are more than one pages
        if(m_config.getXPathNextPageURL() != null)
        {
            logger.print(LogMessage.DEBUG, "Grabber: grab next page url");
            m_nexPageURL = grabberUtils.getURL(doc, m_config.getXPathNextPageURL());
        }

        // get link to single-page view if it exists and download that page
        if(m_config.getXPathSinglePageURL() != null && m_nexPageURL == null)
        {
            logger.print(LogMessage.DEBUG, "Grabber: grab single page view");
            string url = grabberUtils.getURL(doc, m_config.getXPathSinglePageURL());
            if(url != "" && url != null)
            {
            	if(!url.has_prefix("http"))
		        {
		            url = grabberUtils.completeURL(url, m_articleURL);
		        }
            	logger.print(LogMessage.DEBUG, "Grabber: single page url " + url);
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
            logger.print(LogMessage.DEBUG, "Grabber: get title");
            foreach(string xpath in title)
            {
                string tmptitle = grabberUtils.getValue(doc, xpath, m_firstPage);
                if(tmptitle != null && tmptitle != "")
                    m_title = tmptitle.chomp().chug();
            }
        }

        // get the author from the html (useful if feed doesn't provide one)
        unowned Gee.ArrayList<string> author = m_config.getXPathAuthor();
        if(author.size != 0)
        {
            logger.print(LogMessage.DEBUG, "Grabber: get author");
            foreach(string xpath in author)
            {
                string tmpAuthor = grabberUtils.getValue(doc, xpath);
                if(tmpAuthor != null)
                    m_author = tmpAuthor.chomp().chug();
            }
        }

        // get the date from the html (useful if feed doesn't provide one)
        unowned Gee.ArrayList<string> date = m_config.getXPathDate();
        if(date.size != 0)
        {
            logger.print(LogMessage.DEBUG, "Grabber: get date");
            foreach(string xpath in date)
            {
                string tmpDate = grabberUtils.getValue(doc, xpath);
                if(tmpDate != null)
                    m_date = tmpDate.chomp().chug();
            }
        }

        // strip junk
        unowned Gee.ArrayList<string> strip = m_config.getXPathStrip();
        if(strip.size != 0)
        {
            logger.print(LogMessage.DEBUG, "Grabber: strip junk");
            foreach(string xpath in strip)
            {
                logger.print(LogMessage.DEBUG, "Grabber: strip %s".printf(xpath));
                grabberUtils.stripNode(doc, xpath);
            }
        }

        // strip any element whose @id or @class contains this substring
        unowned Gee.ArrayList<string> _stripIDorClass = m_config.getXPathStripIDorClass();
        if(_stripIDorClass.size != 0)
        {
            logger.print(LogMessage.DEBUG, "Grabber: strip id's and class");
            foreach(string IDorClass in _stripIDorClass)
            {
                grabberUtils.stripIDorClass(doc, IDorClass);
            }
        }

        //strip any <img> element where @src attribute contains this substring
        unowned Gee.ArrayList<string> stripImgSrc = m_config.getXPathStripImgSrc();
        if(stripImgSrc.size != 0)
        {
            logger.print(LogMessage.DEBUG, "Grabber: strip img-tags");
            foreach(string ImgSrc in stripImgSrc)
            {
                grabberUtils.stripNode(doc, "//img[contains(@src,'%s')]".printf(ImgSrc));
            }
        }

        grabberUtils.fixLazyImg(doc, "class=\"lazyload\"", "data-src");
        grabberUtils.removeAttributes(doc, null, "style");
        grabberUtils.removeAttributes(doc, "a", "onclick");
        grabberUtils.removeAttributes(doc, "img", "srcset");
        grabberUtils.removeAttributes(doc, "img", "sizes");

        // complete relative source urls of images
        logger.print(LogMessage.DEBUG, "Grabber: complete urls");
        grabberUtils.repairURL("//img", "src", doc, m_articleURL);
        grabberUtils.repairURL("//a", "src", doc, m_articleURL);
        grabberUtils.repairURL("//a", "href", doc, m_articleURL);
        grabberUtils.repairURL("//object", "data", doc, m_articleURL);

        // strip elements using Readability.com and Instapaper.com ignore class names
		// .entry-unrelated and .instapaper_ignore
		// See https://www.readability.com/publishers/guidelines/#view-plainGuidelines
		// and http://blog.instapaper.com/post/730281947
        logger.print(LogMessage.DEBUG, "Grabber: strip instapaper and readability");
        grabberUtils.stripNode(doc,
                "//*[contains(concat(' ',normalize-space(@class),' '),' entry-unrelated ') or contains(concat(' ',normalize-space(@class),' '),' instapaper_ignore ')]");


        // strip elements that contain style="display: none;"
        logger.print(LogMessage.DEBUG, "Grabber: strip invisible elements");
        grabberUtils.stripNode(doc, "//*[contains(@style,'display:none')]");

        // strip all scripts
        logger.print(LogMessage.DEBUG, "Grabber: strip all scripts");
        grabberUtils.stripNode(doc, "//script");

        // strip <noscript>
        logger.print(LogMessage.DEBUG, "Grabber: strip all scripts");
        grabberUtils.stripNode(doc, "//noscript");

        // strip all comments
        logger.print(LogMessage.DEBUG, "Grabber: strip all comments");
        grabberUtils.stripNode(doc, "//comment()");

        // strip all empty url-tags <a/>
        logger.print(LogMessage.DEBUG, "Grabber: strip all empty url-tags");
        grabberUtils.stripNode(doc, "//a[not(node())]");

        // get the content of the article
        unowned Gee.ArrayList<string> bodyList = m_config.getXPathBody();
        if(bodyList.size != 0)
        {
            logger.print(LogMessage.DEBUG, "Grabber: get body");
            foreach(string bodyXPath in bodyList)
            {
                if(grabberUtils.extractBody(doc, bodyXPath, m_root))
                    m_foundSomething = true;
                else
                    logger.print(LogMessage.ERROR, bodyXPath);
            }

            if(m_foundSomething)
            {
            	logger.print(LogMessage.DEBUG, "Grabber: body found");
            }
            else
            {
            	logger.print(LogMessage.DEBUG, "Grabber: no body found");
                return false;
            }
        }
        else
        {
            logger.print(LogMessage.ERROR, "Grabber: config file has no rule for 'body'");
        }

        delete doc;

        m_firstPage = false;

        if(m_nexPageURL != null && !m_singlePage)
        {
            logger.print(LogMessage.DEBUG, "Grabber: load next page");
            if(!m_nexPageURL.has_prefix("http"))
            {
                m_nexPageURL = grabberUtils.completeURL(m_nexPageURL, m_articleURL);
            }
            m_articleURL = m_nexPageURL;
            logger.print(LogMessage.DEBUG, "Grabber: next page url: %s".printf(m_nexPageURL));
            download();
            parse();
            return true;
        }

        if(m_articleID != null && m_feedID != null)
            grabberUtils.saveImages(m_doc, m_articleID, m_feedID);
        else
            grabberUtils.saveImages(m_doc, "", "");

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
            logger.print(LogMessage.DEBUG, "Grabber: title: %s".printf(m_title));

        if(m_author != null)
            logger.print(LogMessage.DEBUG, "Grabber: author: %s".printf(m_author));

        if(m_date != null)
            logger.print(LogMessage.DEBUG, "Grabber: date: %s".printf(m_date));
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
