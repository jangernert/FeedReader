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
	var cntx = new Xml.XPath.Context(doc);
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
	var cntx = new Xml.XPath.Context(doc);
	var res = cntx.eval_expression(xpath);

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
	Logger.debug("GrabberUtils: repairURL xpath:\"%s\" attr:\"%s\"".printf(xpath, attr));
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
	Logger.debug("grabberUtils: fixLazyImg");
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

public static bool fixIframeSize(Html.Doc* doc, string siteName)
{
	Logger.debug("grabberUtils: fixIframeSize");
	Xml.XPath.Context cntx = new Xml.XPath.Context(doc);
	Xml.XPath.Object* res = cntx.eval_expression(@"//iframe[contains(@src, '$siteName')]");

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
		Xml.Node* videoWrapper = new Xml.Node(null, "div");
		Xml.Node* parent = node->parent;

		videoWrapper->set_prop("class", "videoWrapper");
		node->set_prop("width", "100%");
		node->unset_prop("height");

		node->unlink();
		videoWrapper->add_child(node);
		parent->add_child(videoWrapper);
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
			if(node == null)
				continue;

			node->unlink();
			node->free_list();
		}
	}

	delete res;
}

public static void onlyRemoveNode(Html.Doc* doc, string xpath)
{
	Xml.XPath.Context cntx = new Xml.XPath.Context(doc);
	bool changed = false;
	do
	{
		changed = false;
		Xml.XPath.Object* res = cntx.eval_expression(xpath);

		if(res != null
		   && res->type == Xml.XPath.ObjectType.NODESET
		   && res->nodesetval != null)
		{
			for(int i = 0; i < res->nodesetval->length(); i++)
			{
				Xml.Node* node = res->nodesetval->item(i);
				if(node == null)
					continue;

				Xml.Node* parent = node->parent;
				Xml.Node* children = node->children;

				children->unlink();
				parent->add_child(children);

				node->unlink();
				node->free_list();
				changed = true;
				break;
			}
		}

		delete res;
	} while(changed);
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

public static bool addAttributes(Html.Doc* doc, string? tag, string attribute, string val)
{
	Xml.XPath.Context cntx = new Xml.XPath.Context(doc);
	Xml.XPath.Object* res;
	if(tag == null)
	{
		Logger.debug(@"addAttributes: //* $attribute $val");
		res = cntx.eval_expression(@"//*");
	}
	else
	{
		Logger.debug(@"addAttributes: //$tag  $attribute $val");
		res = cntx.eval_expression(@"//$tag");
	}

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
		node->set_prop(attribute, val);
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

public static string cleanString(string? text)
{
	if(text == null)
		return "";

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


public static bool saveImages(Soup.Session session, Html.Doc* doc, Article article, GLib.Cancellable? cancellable = null)
{
	Logger.debug("GrabberUtils: save Images: %s, %s".printf(article.getArticleID(), article.getFeedID()));
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
		if(cancellable != null && cancellable.is_cancelled())
			break;

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
				string? original = downloadImage(session, node->get_prop("src"), article, i+1);

				if(original == null)
					continue;

				string? parentURL = checkParent(session, node);
				if(parentURL != null)
				{
					string parent = downloadImage(session, parentURL, article, i+1, true);

					if(compareImageSize(parent, original) > 0)
					{
						// parent is bigger than orignal image
						node->set_prop("src", original);
						node->set_prop("FR_parent", parent);
					}
					else
					{
						// parent is no improvement over orignal image
						// just delete parent again and only set orignal
						GLib.FileUtils.remove(parent);
						node->set_prop("src", original);
					}
				}
				else
				{
					string? resized = resizeImg(original);
					if(resized != null)
					{
						node->set_prop("src", resized);
						node->set_prop("FR_huge", original);
					}
					else
						node->set_prop("src", original);
				}
			}
		}
	}

	delete res;
	return true;
}


public static string? downloadImage(Soup.Session session, string? url, Article article, int nr, bool parent = false)
{
	if(url == null || url.down().has_prefix("data:image"))
		return null;

	string fixedURL = url;
	string imgPath = GLib.Environment.get_user_data_dir();

	if(fixedURL.has_prefix("//"))
	{
		fixedURL = "http:" + fixedURL;
	}

	if(article.getArticleID() == "" && article.getFeedID() == "")
		imgPath += "/debug-article/ArticleImages/";
	else
		imgPath += "/feedreader/data/images/%s/%s/".printf(article.getFeedFileName(), article.getArticleFileName());

	var path = GLib.File.new_for_path(imgPath);
	try
	{
		path.make_directory_with_parents();
	}
	catch(GLib.Error e)
	{
		//Logger.debug(e.message);
	}

	string localFilename = imgPath + nr.to_string();

	if(parent)
		localFilename += "_parent";

	if(!FileUtils.test(localFilename, GLib.FileTest.EXISTS))
	{
		var message_dlImg = new Soup.Message("GET", fixedURL);

		if(message_dlImg == null)
		{
			Logger.warning(@"grabberUtils.downloadImage: could not create soup message $fixedURL");
			return url;
		}

		if(Settings.tweaks().get_boolean("do-not-track"))
			message_dlImg.request_headers.append("DNT", "1");

		var status = session.send_message(message_dlImg);
		if(status == 200)
		{
			var params = new GLib.HashTable<string, string>(null, null);
			string? contentType = message_dlImg.response_headers.get_content_type(out params);
			if(contentType != null)
			{
				Logger.debug(@"Grabber: type $contentType");
				if(contentType.has_prefix("image/svg"))
				{
					localFilename += ".svg";
				}
			}

			try{
				FileUtils.set_contents( localFilename,
				                        (string)message_dlImg.response_body.flatten().data,
				                        (long)message_dlImg.response_body.length);
			}
			catch(GLib.FileError e)
			{
				Logger.error("Error writing image: %s".printf(e.message));
				return url;
			}
		}
		else
		{
			Logger.error("Error downloading image: %s".printf(fixedURL));
			return url;
		}
	}

	return localFilename.replace("?", "%3F");
}


// if image is >2000px then resize it to 1000px and add FR_huge attribute
// with url to original image
private static string? resizeImg(string path)
{
	try
	{
		int? height = 0;
		int? width = 0;
		Gdk.PixbufFormat? format = Gdk.Pixbuf.get_file_info(path, out width, out height);

		if(format == null || height == null || width == null)
			return null;

		if(width > 2000 || height > 2000)
		{
			int nHeight = 1000;
			int nWidth = 1000;
			if(width > height)
				nHeight = -1;
			else if(height > width)
				nWidth = -1;

			var img = new Gdk.Pixbuf.from_file_at_scale(path, nWidth, nHeight, true);
			img.save(path + "_resized", "png");
			return path + "_resized";
		}
	}
	catch(GLib.Error e)
	{
		Logger.error("Error resizing image: %s".printf(e.message));
		return null;
	}
	return null;
}

// receives 2 paths to images stored on the hdd and compares the size
// 1: file1 > file2
// 0: file1 = file2
// -1: file1 < file2
private static int compareImageSize(string file1, string file2)
{
	int? height1 = 0;
	int? width1 = 0;
	Gdk.Pixbuf.get_file_info(file1, out width1, out height1);

	int? height2 = 0;
	int? width2 = 0;
	Gdk.Pixbuf.get_file_info(file2, out width2, out height2);

	if(height1 == null
	   || width1 == null
	   || height2 == null
	   || width2 == null)
	{
		Logger.warning("Utils.compareImageSize: couldn't read image sizes");
		return 0;
	}

	if(height1 == height2
	   && width1 == width2)
		return 0;
	else if(height1*width1 > height2*width2)
		return 1;
	else
		return -1;
}

// check if the parent node is a link that points to a picture
// (most likely a bigger version of said picture)
private static string? checkParent(Soup.Session session, Xml.Node* node)
{
	Logger.debug("Grabber: checkParent");
	string smallImgURL = node->get_prop("src");
	int64 origSize = 0;
	int64 size = 0;
	Xml.Node* parent = node->parent;
	string name = parent->name;
	Logger.debug(@"Grabber: parent $name");
	if(name == "a")
	{
		string url = parent->get_prop("href");

		if(url != "" && url != null)
		{
			if(url.has_prefix("//"))
				url = "http:" + url;

			var message = new Soup.Message("HEAD", url);
			if(message == null)
				return null;
			session.send_message(message);
			var params = new GLib.HashTable<string, string>(null, null);
			string? contentType = message.response_headers.get_content_type(out params);
			size = message.response_headers.get_content_length();
			var message2 = new Soup.Message("HEAD", smallImgURL);
			if(message2 == null)
				return null;
			session.send_message(message2);
			origSize = message2.response_headers.get_content_length();
			if(contentType != null)
			{
				Logger.debug(@"Grabber: type $contentType");
				if(contentType.has_prefix("image/"))
				{
					if(size != 0 && origSize != 0)
					{
						if(size > origSize)
							return url;
						else
							return null;
					}
					else
						return url;
				}
			}
		}
	}

	return null;
}

public static string postProcessing(ref string html)
{
	Logger.debug("GrabberUtils: postProcessing");
	html = html.replace("<h3/>", "<h3></h3>");

	int pos1 = html.index_of("<iframe", 0);
	int pos2 = -1;
	int pos3 = -1;
	while(pos1 != -1)
	{
		pos2 = html.index_of("/>", pos1);
		pos3 = html.index_of("</iframe>", pos1);

		if(pos3 == -1 && pos2 == -1)
		{
			Logger.error("GrabberUtils.postProcessing: could not find closing for iframe tag");
			pos1 = html.index_of("<iframe", pos1+7);
			continue;
		}

		if((pos2 != -1 && pos3 != -1 && pos3 < pos2) || pos2 == -1)
		{
			Logger.debug("GrabberUtils.postProcessing: iframe not broken");
			pos1 = html.index_of("<iframe", pos1+7);
			continue;
		}



		string broken_iframe = html.substring(pos1, pos2+2-pos1);
		Logger.debug("GrabberUtils: broken = %s".printf(broken_iframe));
		string fixed_iframe = broken_iframe.substring(0, broken_iframe.length-2) + "></iframe>";
		Logger.debug("GrabberUtils: fixed = %s".printf(fixed_iframe));
		html = html.replace(broken_iframe, fixed_iframe);
		pos3 = html.index_of("<iframe", pos1+7);
		if(pos3 == pos1 || pos3 > html.length)
			break;
		else
			pos1 = pos3;
	}
	Logger.debug("GrabberUtils: postProcessing done");
	return html;
}
}
