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

public class FeedReader.ArticleListEmptyLabel : Gtk.Label {

	public ArticleListEmptyLabel()
	{
		this.set_text(_("No Articles"));
		this.get_style_context().add_class("h2");
		this.set_ellipsize(Pango.EllipsizeMode.END);
		this.set_line_wrap_mode(Pango.WrapMode.WORD);
		this.set_line_wrap(true);
		this.set_lines(3);
		this.set_margin_left(30);
		this.set_margin_right(30);
		this.set_justify(Gtk.Justification.CENTER);
		this.show_all();
	}

	public void build(string selectedFeed, FeedListType type, bool onlyUnread, bool onlyMarked, string searchTerm)
	{
		string message = "";
		if(selectedFeed != FeedID.ALL.to_string() && selectedFeed != FeedID.CATEGORIES.to_string())
		{
			switch(type)
			{
				case FeedListType.FEED:
					name = dbUI.get_default().getFeedName(selectedFeed);
					if(onlyUnread && !onlyMarked)
					{
						if(searchTerm != "")
							message = _("No unread articles that fit \"%s\" in the feed \"%s\" could be found").printf(Utils.parseSearchTerm(searchTerm), name);
						else
							message = _("No unread articles in the feed \"%s\" could be found").printf(name);
					}
					else if(onlyUnread && onlyMarked)
					{
						if(searchTerm != "")
							message = _("No unread and marked articles that fit \"%s\" in the feed \"%s\" could be found").printf(Utils.parseSearchTerm(searchTerm), name);
						else
							message = _("No unread and marked articles in the feed \"%s\" could be found").printf(name);
					}
					else if(!onlyUnread && onlyMarked)
					{
						if(searchTerm != "")
							message = _("No marked articles that fit \"%s\" in the feed \"%s\" could be found").printf(Utils.parseSearchTerm(searchTerm), name);
						else
							message = _("No marked articles in the feed \"%s\" could be found").printf(name);
					}
					else if(!onlyUnread && !onlyMarked)
					{
						if(searchTerm != "")
							message = _("No articles that fit \"%s\" in the feed \"%s\" could be found").printf(Utils.parseSearchTerm(searchTerm), name);
						else
							message = _("No articles in the feed \"%s\" could be found").printf(name);
					}
					break;
				case FeedListType.TAG:
					name = dbUI.get_default().getTagName(selectedFeed);
					if(onlyUnread && !onlyMarked)
					{
						if(searchTerm != "")
							message = _("No unread articles that fit \"%s\" in the tag \"%s\" could be found").printf(Utils.parseSearchTerm(searchTerm), name);
						else
							message = _("No unread articles in the tag \"%s\" could be found").printf(name);
					}
					else if(onlyUnread && onlyMarked)
					{
						if(searchTerm != "")
							message = _("No unread and marked articles that fit \"%s\" in the tag \"%s\" could be found").printf(Utils.parseSearchTerm(searchTerm), name);
						else
							message = _("No unread and marked articles in the tag \"%s\" could be found").printf(name);
					}
					else if(!onlyUnread && onlyMarked)
					{
						if(searchTerm != "")
							message = _("No marked articles that fit \"%s\" in the tag \"%s\" could be found").printf(Utils.parseSearchTerm(searchTerm), name);
						else
							message = _("No marked articles in the tag \"%s\" could be found").printf(name);
					}
					else if(!onlyUnread && !onlyMarked)
					{
						if(searchTerm != "")
							message = _("No articles that fit \"%s\" in the tag \"%s\" could be found").printf(Utils.parseSearchTerm(searchTerm), name);
						else
							message = _("No articles in the tag \"%s\" could be found").printf(name);
					}
					break;
				case FeedListType.CATEGORY:
					name = dbUI.get_default().getCategoryName(selectedFeed);
					if(onlyUnread && !onlyMarked)
					{
						if(searchTerm != "")
							message = _("No unread articles that fit \"%s\" in the category \"%s\" could be found").printf(Utils.parseSearchTerm(searchTerm), name);
						else
							message = _("No unread articles in the category \"%s\" could be found").printf(name);
					}
					else if(onlyUnread && onlyMarked)
					{
						if(searchTerm != "")
							message = _("No unread and marked articles that fit \"%s\" in the category \"%s\" could be found").printf(Utils.parseSearchTerm(searchTerm), name);
						else
							message = _("No unread and marked articles in the category \"%s\" could be found").printf(name);
					}
					else if(!onlyUnread && onlyMarked)
					{
						if(searchTerm != "")
							message = _("No marked articles that fit \"%s\" in the category \"%s\" could be found").printf(Utils.parseSearchTerm(searchTerm), name);
						else
							message = _("No marked articles in the category \"%s\" could be found").printf(name);
					}
					else if(!onlyUnread && !onlyMarked)
					{
						if(searchTerm != "")
							message = _("No articles that fit \"%s\" in the category \"%s\" could be found").printf(Utils.parseSearchTerm(searchTerm), name);
						else
							message = _("No articles in the category \"%s\" could be found").printf(name);
					}
					break;
			}
		}
		else
		{
			if(onlyUnread && !onlyMarked)
			{
				if(searchTerm != "")
					message = _("No unread articles that fit \"%s\" could be found").printf(Utils.parseSearchTerm(searchTerm));
				else
					message = _("No unread articles could be found");
			}
			else if(onlyUnread && onlyMarked)
			{
				if(searchTerm != "")
					message = _("No unread and marked articles that fit \"%s\" could be found").printf(Utils.parseSearchTerm(searchTerm));
				else
					message = _("No unread and marked articles could be found");
			}
			else if(!onlyUnread && onlyMarked)
			{
				if(searchTerm != "")
					message = _("No marked articles that fit \"%s\" could be found").printf(Utils.parseSearchTerm(searchTerm));
				else
					message = _("No marked articles could be found");
			}
			else if(!onlyUnread && !onlyMarked)
			{
				if(searchTerm != "")
					message = _("No articles that fit \"%s\" could be found").printf(Utils.parseSearchTerm(searchTerm));
				else
					message = _("No articles could be found");
			}

		}
		this.set_text(message);
	}

}
