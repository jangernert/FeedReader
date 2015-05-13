public class FeedReader.grabberUtils : GLib.Object {

    public grabberUtils()
    {

    }

    public static void extractBody(Html.Doc* doc, string xpath, Xml.Node* destination)
    {
        Xml.XPath.Context cntx = new Xml.XPath.Context(doc);
        var res = cntx.eval_expression(xpath);
        //stdout.printf("xpath: %s\n", xpath);

        if(res == null || res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null)
            return;

        for(int i = 0; i < res->nodesetval->length(); i++)
        {
        	Xml.Node* node = res->nodesetval->item(i);

            // remove property "style" of all tags
            node->has_prop("style")->remove();

            node->unlink();
            destination->add_child(node);
        }

    	delete res;
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
        //stdout.printf("xpath: %s\n", xpath);

        if(res == null || res->type != Xml.XPath.ObjectType.NODESET || res->nodesetval == null)
            return null;

    	Xml.Node* node = res->nodesetval->item(0);
        string result = cleanString(node->get_content());

        if(remove)
        {
            node->unlink();
            node->free_list();
        }

        return result;
    }

    public static void stripNode(Html.Doc* doc, string xpath)
    {
        Xml.XPath.Context cntx = new Xml.XPath.Context(doc);
    	Xml.XPath.Object* res = cntx.eval_expression(xpath);

        if(res != null
        && res->type == Xml.XPath.ObjectType.NODESET
        && res->nodesetval != null)
        {
            for(int i = 0; i < res->nodesetval->length(); i++)
            {
                Xml.Node* node = res->nodesetval->item(i);
                node->unlink();
                node->free_list();
            }
        }
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

        if(incompleteURL.has_prefix("/"))
        {
            index = articleURL.index_of_char('/', index);
            baseURL = articleURL.substring(0, index);
            return baseURL + incompleteURL;
        }
        else if(incompleteURL.has_prefix("?"))
        {
            index = articleURL.index_of_char('?', index);
            baseURL = articleURL.substring(0, index);
            return baseURL + incompleteURL;
        }

        return "error";
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


}
