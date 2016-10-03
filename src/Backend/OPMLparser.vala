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

	public OPMLparser(string opml)
	{
		m_opmlString = opml;

	}

	public bool parse()
	{
		Xml.Doc* doc = Xml.Parser.read_doc(m_opmlString, null, null, Xml.ParserOption.NOERROR + Xml.ParserOption.NOWARNING);
		if(doc == null)
			return false;

		Xml.Node* root = doc->get_root_element();
		if(root->name != "opml")
			return false;

		Logger.get().debug("OPML version: " + root->get_prop("version"));

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

		return true;
	}

	private void parseHead(Xml.Node* root)
	{
		for(var node = root->children; node != null; node = node->next)
		{
			if(node->type == Xml.ElementType.ELEMENT_NODE)
			{
				switch(node->name)
				{
					case "title":
						Logger.get().debug("Title: " + node->get_content());
						break;

					case "dateCreated":
						Logger.get().debug("dateCreated: " + node->get_content());
						break;

					case "dateModified":
						Logger.get().debug("dateModified: " + node->get_content());
						break;
				}
			}
		}
	}

	private void parseTree(Xml.Node* root, string? catID = null)
	{
		m_level++;
		for(var node = root->children; node != null; node = node->next)
		{
			if(node->type == Xml.ElementType.ELEMENT_NODE)
			{
				if(hasProp(node, "text") && !hasProp(node, "xmlUrl"))
				{
					if(hasProp(node, "title") || !hasProp(node, "schema-version"))
						parseCat(node, catID);
				}
				else if(hasProp(node, "xmlUrl") && hasProp(node, "htmlUrl"))
				{
					parseFeed(node, catID);
				}
			}
		}
		m_level--;
	}

	private void parseCat(Xml.Node* node, string? parentCatID = null)
	{
		string title = node->get_prop("text");
		Logger.get().debug(space() + "Category: " + title);
		string catID = daemon.addCategory("title", parentCatID);
		parseTree(node, catID);
	}

	private void parseFeed(Xml.Node* node, string? catID = null)
	{
		if(node->get_prop("type") == "rss")
		{
			string title = node->get_prop("text");
			string feedURL = node->get_prop("xmlUrl");
			string website = node->get_prop("htmlUrl");
			Logger.get().debug(space() + "Feed: " + title + " website: " + website + " feedURL: " + feedURL);
			daemon.addFeed(feedURL, catID, true);
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
