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

        if(res == null)
        {
            return false;
        }
        else if(res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null)
        {
            delete res;
            return false;
        }

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

    public static string? getURL(Html.Doc* doc, string xpath)
    {
        Xml.XPath.Context cntx = new Xml.XPath.Context(doc);
    	Xml.XPath.Object* res = cntx.eval_expression(xpath);

        if(res == null)
        {
            return null;
        }
        else if(res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null)
        {
            delete res;
            return null;
        }

    	Xml.Node* node = res->nodesetval->item(0);
        string URL = node->get_prop("href");

        node->unlink();
        node->free_list();
        delete res;
        return URL;
    }

    public static string? getValue(Html.Doc* doc, string xpath, bool remove = false)
    {
        Xml.XPath.Context cntx = new Xml.XPath.Context(doc);
    	Xml.XPath.Object* res = cntx.eval_expression(xpath);

        if(res == null)
        {
            return null;
        }
        else if(res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null)
        {
            delete res;
            return null;
        }

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

    public static bool repairURL(string xpath, string attr, Html.Doc* doc, string articleURL)
    {
        logger.print(LogMessage.DEBUG, "GrabberUtils: repairURL xpath:\"%s\" attr:\"%s\"".printf(xpath, attr));
        Xml.XPath.Context cntx = new Xml.XPath.Context(doc);
    	Xml.XPath.Object* res = cntx.eval_expression(xpath);

        if(res == null)
        {
            return false;
        }
        else if(res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null)
        {
            delete res;
            return false;
        }

        for(int i = 0; i < res->nodesetval->length(); i++)
        {
        	Xml.Node* node = res->nodesetval->item(i);
            if(node->get_prop(attr) != null)
                node->set_prop(attr, completeURL(node->get_prop(attr), articleURL));
        }

        delete res;
        return true;
    }

    public static bool fixLazyImg(Html.Doc* doc, string className, string correctURL)
    {
        logger.print(LogMessage.DEBUG, "grabberUtils: fixLazyImg");
        Xml.XPath.Context cntx = new Xml.XPath.Context(doc);
    	Xml.XPath.Object* res = cntx.eval_expression("//img[contains(@class, '%s')]".printf(className));

        if(res == null)
        {
            return false;
        }
        else if(res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null)
        {
            delete res;
            return false;
        }

        for(int i = 0; i < res->nodesetval->length(); i++)
        {
        	Xml.Node* node = res->nodesetval->item(i);
            node->set_prop("src", node->get_prop(correctURL));
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

        if(res == null)
        {
            return false;
        }
        else if(res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null)
        {
            delete res;
            return false;
        }

        for(int i = 0; i < res->nodesetval->length(); i++)
        {
        	Xml.Node* node = res->nodesetval->item(i);
            node->set_prop(attribute, newValue);
        }

        delete res;
        return true;
    }

    public static bool removeAttributes(Html.Doc* doc, string? tag, string attribute)
    {
        Xml.XPath.Context cntx = new Xml.XPath.Context(doc);
        Xml.XPath.Object* res;
        if(tag == null)
            res = cntx.eval_expression("//*[@%s]".printf(attribute));
        else
            res = cntx.eval_expression("//%s[@%s]".printf(tag, attribute));

        if(res == null)
        {
            return false;
        }
        else if(res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null)
        {
            delete res;
            return false;
        }

        for(int i = 0; i < res->nodesetval->length(); i++)
        {
        	Xml.Node* node = res->nodesetval->item(i);
            node->unset_prop(attribute);
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
        int index = 0;
        if(articleURL.has_prefix("http"))
        {
            index = 8;
        }
        else
            index = articleURL.index_of_char('.', 0);

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
        else if(incompleteURL.has_prefix("//"))
        {
            return "http:" + incompleteURL;
        }

        return incompleteURL;
    }

    public static string buildHostName(string URL, bool cutSubdomain = true)
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
        hostname = hostname.substring(0, index);

        if(cutSubdomain)
        {
            index = hostname.index_of_char('.');
            if(index != -1 && hostname.index_of_char('.', index+1) != -1)
            {
                hostname = hostname.substring(index);
            }
        }

        return hostname;
    }


    public static bool saveImages(Html.Doc* doc, string articleID, string feedID)
    {
        logger.print(LogMessage.DEBUG, "GrabberUtils: save Images: %s, %s".printf(articleID, feedID));
        Xml.XPath.Context cntx = new Xml.XPath.Context(doc);
    	Xml.XPath.Object* res = cntx.eval_expression("//img");

        if(res == null)
        {
            return false;
        }
        else if(res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null)
        {
            delete res;
            return false;
        }

        for(int i = 0; i < res->nodesetval->length(); i++)
        {
        	Xml.Node* node = res->nodesetval->item(i);
            if(node->get_prop("src") != null)
            {
                if(
                    ((node->get_prop("width") != null && int.parse(node->get_prop("width")) > 1)
                    || (node->get_prop("width") == null))
                &&
                    ((node->get_prop("height") != null && int.parse(node->get_prop("height")) > 1)
                    || (node->get_prop("height") == null))
                )
                {
                    node->set_prop("src", downloadImage(node->get_prop("src"), articleID, feedID, i+1));
                }
            }
        }

        delete res;
        return true;
    }


    public static string downloadImage(string url, string articleID, string feedID, int nr)
    {
        logger.print(LogMessage.DEBUG, "GrabberUtils: download Image %s".printf(url));
        string fixedURL = url;
        string imgPath = "";

        if(fixedURL.has_prefix("//"))
        {
            fixedURL = "http:" + fixedURL;
        }

        if(articleID == "" && feedID == "")
            imgPath = GLib.Environment.get_home_dir() + "/debug-article/ArticleImages/";
        else
            imgPath = GLib.Environment.get_home_dir() + "/.local/share/feedreader/data/images/%s/%s/".printf(feedID.replace("/", "_"), articleID);

        var path = GLib.File.new_for_path(imgPath);
		try{
			path.make_directory_with_parents();
		}
		catch(GLib.Error e){
			//logger.print(LogMessage.DEBUG, e.message);
		}

        int start = fixedURL.last_index_of("/") + 1;
        string localFilename = imgPath + nr.to_string();

        if(!FileUtils.test(localFilename, GLib.FileTest.EXISTS))
		{
			Soup.Message message_dlImg = new Soup.Message("GET", fixedURL);

			if(settings_tweaks.get_boolean("do-not-track"))
				message_dlImg.request_headers.append("DNT", "1");

			var session = new Soup.Session();
            session.timeout = 8;
			session.ssl_strict = false;
			var status = session.send_message(message_dlImg);
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
                    return url;
				}
			}
            else
            {
                logger.print(LogMessage.ERROR, "Error downloading image: %s".printf(fixedURL));
                return url;
            }
		}

        return localFilename.replace("?", "%3F");
    }

    public static string postProcessing(ref string html)
    {
        logger.print(LogMessage.DEBUG, "GrabberUtils: postProcessing");
        html = html.replace("<h3/>", "<h3></h3>");

    	int pos1 = html.index_of("<iframe", 0);
    	int pos2 = -1;
    	while(pos1 != -1)
    	{
    		pos2 = html.index_of("/>", pos1);
    		string broken_iframe = html.substring(pos1, pos2+2-pos1);
            logger.print(LogMessage.DEBUG, "GrabberUtils: broken = %s".printf(broken_iframe));
    		string fixed_iframe = broken_iframe.substring(0, broken_iframe.length-2) + "></iframe>";
            logger.print(LogMessage.DEBUG, "GrabberUtils: fixed = %s".printf(fixed_iframe));
    		html = html.replace(broken_iframe, fixed_iframe);
    		int pos3 = html.index_of("<iframe", pos1+7);
    		if(pos3 == pos1 || pos3 > html.length)
    			break;
    		else
    			pos1 = pos3;
    	}
        logger.print(LogMessage.DEBUG, "GrabberUtils: postProcessing done");
        return html;
    }
}
