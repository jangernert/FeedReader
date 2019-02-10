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

public class FeedReader.OPMLparser : GLib.Object {

private string m_opmlString;
private uint m_level = 0;
private Gee.List<Feed> m_feeds = new Gee.ArrayList<Feed>();

public OPMLparser(string opml)
{
	m_opmlString = opml;
}

public Gee.List<Feed> parse()
{
	if(!m_feeds.is_empty)
	{
		Logger.error("OPMLParser is not meant to be re-used!");
		m_feeds = new Gee.ArrayList<Feed>();
	}

	Xml.Doc* doc = Xml.Parser.read_doc(m_opmlString, null, null, 0);
	if(doc == null)
	{
		Logger.error("OPML: parsing xml failed");
		return m_feeds;
	}

	Xml.Node* root = doc->get_root_element();
	if(root->name != "opml")
		return m_feeds;

	Logger.debug("OPML version: " + root->get_prop("version"));

	for(var node = root->children; node != null; node = node->next)
	{
		if(node->type == Xml.ElementType.ELEMENT_NODE)
		{
			switch(node->name)
			{
			case "head":
				parseHead(node);
				break;

			case "body":
				parseTree(node);
				break;
			}
		}
	}

	return m_feeds;
}

private void parseHead(Xml.Node* root)
{
	Logger.debug("Parse OPML head");
	for(var node = root->children; node != null; node = node->next)
	{
		if(node->type == Xml.ElementType.ELEMENT_NODE)
		{
			switch(node->name)
			{
			case "title":
				Logger.debug("Title: " + node->get_content());
				break;

			case "dateCreated":
				Logger.debug("dateCreated: " + node->get_content());
				break;

			case "dateModified":
				Logger.debug("dateModified: " + node->get_content());
				break;
			}
		}
	}
}

private void parseTree(Xml.Node* root, string? catID = null)
{
	m_level++;
	Logger.debug(@"Parse OPML tree level $m_level");
	for(var node = root->children; node != null; node = node->next)
	{
		if(node->type == Xml.ElementType.ELEMENT_NODE)
		{
			if(!hasProp(node, "xmlUrl"))
			{
				if(hasProp(node, "title") || !hasProp(node, "schema-version"))
					parseCat(node, catID);
			}
			else
			{
				parseFeed(node, catID);
			}
		}
	}
	m_level--;
}

private void parseCat(Xml.Node* node, string? parentCatID = null)
{
	string title = "No Title";
	if(hasProp(node, "text"))
		title = node->get_prop("text");
	else if(hasProp(node, "title"))
		title = node->get_prop("title");

	Logger.debug(space() + "Category: " + title);
	string catID = FeedReaderBackend.get_default().addCategory(title, parentCatID, true);
	parseTree(node, catID);
}

private void parseFeed(Xml.Node* node, string? catID = null)
{
	if(node->get_prop("type") == "rss" || node->get_prop("type") == "atom")
	{
		string title = "No Title";
		if(hasProp(node, "text"))
			title = node->get_prop("text");
		else if(hasProp(node, "title"))
			title = node->get_prop("title");
		string feedURL = node->get_prop("xmlUrl");

		string website = "";

		if(hasProp(node, "htmlUrl"))
		{
			website = node->get_prop("htmlUrl");
			Logger.debug(space() + "Feed: " + title + " website: " + website + " feedURL: " + feedURL);
		}
		else
		{
			Logger.debug(space() + "Feed: " + title + " feedURL: " + feedURL);
		}

		var categories = new Gee.ArrayList<string>();
		if(catID == null)
			categories.add(FeedServer.get_default().uncategorizedID());
		else
			categories.add(catID);

		m_feeds.add(new Feed("", title, website, 0, categories, null, feedURL));
	}
}

private bool hasProp(Xml.Node* node, string prop)
{
	if(node->get_prop(prop) != null)
		return true;

	return false;
}

private string space()
{
	string tmp = "";
	for(int i = 1; i < m_level; i++)
	{
		tmp += "	";
	}

	return tmp;
}
}
