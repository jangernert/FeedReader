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

public class FeedReader.grabberUtils : GLib.Object {

    public grabberUtils()
    {

    }

    public static bool extractBody(Html.Doc* doc, string xpath, Xml.Node* destination)
    {
        bool foundSomething = false;
        Xml.XPath.Context cntx = new Xml.XPath.Context(doc);
        var res = cntx.eval_expression(xpath);
        //stdout.printf("xpath: %s\n", xpath);

        if(res == null || res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null)
            return false;

        for(int i = 0; i < res->nodesetval->length(); i++)
        {
        	Xml.Node* node = res->nodesetval->item(i);

            // remove property "style" of all tags
            node->has_prop("style")->remove();

            node->unlink();
            destination->add_child(node);

            if(!foundSomething)
                foundSomething = true;
        }

    	delete res;
        return foundSomething;
    }

    public static string getURL(Html.Doc* doc, string xpath)
    {
        Xml.XPath.Context cntx = new Xml.XPath.Context(doc);
    	Xml.XPath.Object* res = cntx.eval_expression(xpath);
        //stdout.printf("xpath: %s\n", xpath);

        if(res == null || res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null)
            return null;

    	Xml.Node* node = res->nodesetval->item(0);
    	//stdout.printf("%s\n", node->get_content());
        //stdout.printf("%s\n", node->get_prop("href"));
        string URL = node->get_prop("href");

        node->unlink();
        node->free_list();
        delete res;
        return URL;
    }

    public static string getValue(Html.Doc* doc, string xpath, bool remove = false)
    {
        Xml.XPath.Context cntx = new Xml.XPath.Context(doc);
    	Xml.XPath.Object* res = cntx.eval_expression(xpath);

        if(res == null || res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null)
            return null;

    	Xml.Node* node = res->nodesetval->item(0);
        string result = cleanString(node->get_content());

        if(remove)
        {
            node->unlink();
            node->free_list();
        }

        delete res;
        return result;
    }

    public static bool repairImg(Html.Doc* doc, string articleURL)
    {
        Xml.XPath.Context cntx = new Xml.XPath.Context(doc);
    	Xml.XPath.Object* res = cntx.eval_expression("//img");

        if(res == null || res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null)
            return false;

        for(int i = 0; i < res->nodesetval->length(); i++)
        {
        	Xml.Node* node = res->nodesetval->item(i);
            node->set_prop("src", completeURL(node->get_prop("src"), articleURL));
        }

        delete res;
        return true;
    }

    public static bool fixLazyImg(Html.Doc* doc, string lazyload, string correctURL)
    {
        Xml.XPath.Context cntx = new Xml.XPath.Context(doc);
    	Xml.XPath.Object* res = cntx.eval_expression("//img[@%s]".printf(lazyload));

        if(res == null || res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null)
            return false;

        for(int i = 0; i < res->nodesetval->length(); i++)
        {
        	Xml.Node* node = res->nodesetval->item(i);
            node->set_prop("src", node->get_prop(correctURL));
        }

        delete res;
        return true;
    }

    public static bool repairURL(Html.Doc* doc, string articleURL)
    {
        Xml.XPath.Context cntx = new Xml.XPath.Context(doc);
    	Xml.XPath.Object* res = cntx.eval_expression("//a");

        if(res == null || res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null)
            return false;

        for(int i = 0; i < res->nodesetval->length(); i++)
        {
        	Xml.Node* node = res->nodesetval->item(i);
            node->set_prop("href", completeURL(node->get_prop("href"), articleURL));
        }

        delete res;
        return true;
    }

    public static void stripNode(Html.Doc* doc, string xpath)
    {
        string ancestor = xpath;
        if(ancestor.has_prefix("//"))
        {
            ancestor = ancestor.substring(2);
        }
        string query = "%s[not(ancestor::%s)]".printf(xpath, ancestor);
        //logger.print(LogMessage.DEBUG, query);

        Xml.XPath.Context cntx = new Xml.XPath.Context(doc);
    	Xml.XPath.Object* res = cntx.eval_expression(query);

        if(res != null
        && res->type == Xml.XPath.ObjectType.NODESET
        && res->nodesetval != null)
        {
            for(int i = 0; i < res->nodesetval->length(); ++i)
            {
                Xml.Node* node = res->nodesetval->item(i);
                if(node != null)
                {
                    node->unlink();
                    node->free_list();
                }
            }
        }

        delete res;
    }

    public static bool setAttributes(Html.Doc* doc, string attribute, string newValue)
    {
        Xml.XPath.Context cntx = new Xml.XPath.Context(doc);
    	Xml.XPath.Object* res = cntx.eval_expression("//*[@%s]".printf(attribute));

        if(res == null || res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null)
            return false;

        for(int i = 0; i < res->nodesetval->length(); i++)
        {
        	Xml.Node* node = res->nodesetval->item(i);
            node->set_prop(attribute, newValue);
        }

        delete res;
        return true;
    }

    public static void stripIDorClass(Html.Doc* doc, string IDorClass)
    {
        Xml.XPath.Context cntx = new Xml.XPath.Context(doc);
        string xpath = "//*[contains(@class, '%s') or contains(@id, '%s')]".printf(IDorClass, IDorClass);
    	Xml.XPath.Object* res = cntx.eval_expression(xpath);

        if(res != null
        && res->type == Xml.XPath.ObjectType.NODESET
        && res->nodesetval != null)
        {
            for(int i = 0; i < res->nodesetval->length(); i++)
            {
                Xml.Node* node = res->nodesetval->item(i);
                if(node->get_prop("class") != null
                || node->get_prop("id") != null
                || node->get_prop("src") != null)
                {
                    node->unlink();
                    node->free_list();
                }
            }
        }

        delete res;
    }

    public static string cleanString(string text)
    {
        var tmpText =  text.replace("\n", "");
        var array = tmpText.split(" ");
        tmpText = "";

        foreach(string word in array)
        {
            if(word.chug() != "")
            {
                tmpText += word + " ";
            }
        }

        return tmpText.chomp();
    }

    public static string completeURL(string incompleteURL, string articleURL)
    {
        // lets assume all urls will start with http://www. or https://www.
        // so only start searching for the second dot after pos 12
        int index = articleURL.index_of_char('.', 12);
        string baseURL = "";

        if(incompleteURL.has_prefix("/") && !incompleteURL.has_prefix("//"))
        {
            index = articleURL.index_of_char('/', index);
            baseURL = articleURL.substring(0, index);
            if(baseURL.has_suffix("/"))
            {
                baseURL = baseURL.substring(0, baseURL.char_count()-1);
            }
            return baseURL + incompleteURL;
        }
        else if(incompleteURL.has_prefix("?"))
        {
            index = articleURL.index_of_char('?', index);
            baseURL = articleURL.substring(0, index);
            return baseURL + incompleteURL;
        }
        else if(!incompleteURL.has_prefix("http")
        && !incompleteURL.has_prefix("www")
        && !incompleteURL.has_prefix("//"))
        {
            index = articleURL.index_of_char('/', index);
            baseURL = articleURL.substring(0, index);
            if(!baseURL.has_suffix("/"))
            {
                baseURL = baseURL + "/";
            }
            return baseURL + incompleteURL;
        }

        return incompleteURL;
    }

    public static string buildHostName(string URL)
    {
        string hostname = URL;
        if(hostname.has_prefix("http://"))
        {
            hostname = hostname.substring(7);
        }
        else if(hostname.has_prefix("https://"))
        {
            hostname = hostname.substring(8);
        }

        if(hostname.has_prefix("www."))
        {
            hostname = hostname.substring(4);
        }

        int index = hostname.index_of_char('/');
        return hostname.substring(0, index);
    }


    public static bool saveImages(Html.Doc* doc, string articleID, string feedID)
    {
        Xml.XPath.Context cntx = new Xml.XPath.Context(doc);
    	Xml.XPath.Object* res = cntx.eval_expression("//img");

        if(res == null || res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null)
            return false;

        for(int i = 0; i < res->nodesetval->length(); i++)
        {
        	Xml.Node* node = res->nodesetval->item(i);
            node->set_prop("src", downloadImage(node->get_prop("src"), articleID, feedID, i+1));
        }

        delete res;
        return true;
    }


    public static string downloadImage(string url, string articleID, string feedID, int nr)
    {
        string fixedURL = url;
        if(fixedURL.has_prefix("//"))
        {
            fixedURL = "http:" + fixedURL;
        }

        logger.print(LogMessage.DEBUG, "downloadImage: %s".printf(fixedURL));
        string imgPath = GLib.Environment.get_home_dir() + "/.local/share/feedreader/data/images/%s/%s/".printf(feedID, articleID);
		var path = GLib.File.new_for_path(imgPath);
		try{
			path.make_directory_with_parents();
		}
		catch(GLib.Error e){
			//logger.print(LogMessage.DEBUG, e.message);
		}

        int start = fixedURL.last_index_of("/") + 1;
        string localFilename = imgPath + GLib.Uri.unescape_string("%i_%s".printf(nr, fixedURL.substring(start)));

        if(!FileUtils.test(localFilename, GLib.FileTest.EXISTS))
		{
			Soup.Message message_dlImg;
			message_dlImg = new Soup.Message("GET", fixedURL);
			var session = new Soup.Session();
			session.ssl_strict = false;
			var status = session.send_message(message_dlImg);
            logger.print(LogMessage.DEBUG, "downloadImage status %u".printf(status));
			if(status == 200)
			{
				try{
					FileUtils.set_contents(	localFilename,
											(string)message_dlImg.response_body.flatten().data,
											(long)message_dlImg.response_body.length);
				}
				catch(GLib.FileError e)
				{
					logger.print(LogMessage.ERROR, "Error writing image: %s".printf(e.message));
                    return fixedURL;
				}
			}
            else
            {
                logger.print(LogMessage.ERROR, "Error downloading image: %s".printf(fixedURL));
                return fixedURL;
            }
		}

        return localFilename;
    }


}
