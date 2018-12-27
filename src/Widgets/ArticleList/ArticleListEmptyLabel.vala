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

public void build(string selectedID, FeedListType type, ArticleListState state, string searchTerm)
{
	string message = "";
	string name = "";
	string search = Utils.parseSearchTerm(searchTerm);
	if(selectedID != FeedID.ALL.to_string() && selectedID != FeedID.CATEGORIES.to_string())
	{
		switch(type)
		{
		case FeedListType.FEED:
			var feed = DataBase.readOnly().read_feed(selectedID);
			name = feed != null ? feed.getTitle() : "";
			if(state == ArticleListState.UNREAD)
			{
				if(searchTerm != "")
					message = _(@"No unread articles that fit \"$search\" in feed \"$name\"");
				else
					message = _(@"No unread articles in feed \"$name\"");
			}
			else if(state == ArticleListState.MARKED)
			{
				if(searchTerm != "")
					message = _(@"No starred articles that fit \"$search\" in feed \"$name\"");
				else
					message = _(@"No starred articles in feed \"$name\"");
			}
			else if(state == ArticleListState.ALL)
			{
				if(searchTerm != "")
					message = _(@"No articles that fit \"$search\" in feed \"$name\"");
				else
					message = _(@"No articles in feed \"$name\"");
			}
			break;
		case FeedListType.TAG:
			name = DataBase.readOnly().getTagName(selectedID);
			if(state == ArticleListState.UNREAD)
			{
				if(searchTerm != "")
					message = _(@"No unread articles that fit \"$search\" in tag \"$name\"");
				else
					message = _(@"No unread articles in tag \"$name\"");
			}
			else if(state == ArticleListState.MARKED)
			{
				if(searchTerm != "")
					message = _(@"No starred articles that fit \"$search\" in tag \"$name\"");
				else
					message = _(@"No starred articles in tag \"$name\"");
			}
			else if(state == ArticleListState.ALL)
			{
				if(searchTerm != "")
					message = _(@"No articles that fit \"$search\" in tag \"$name\"");
				else
					message = _(@"No articles in tag \"$name\"");
			}
			break;
		case FeedListType.CATEGORY:
			name = DataBase.readOnly().getCategoryName(selectedID);
			if(state == ArticleListState.UNREAD)
			{
				if(searchTerm != "")
					message = _(@"No unread articles that fit \"$search\" in category \"$name\"");
				else
					message = _(@"No unread articles in category \"$name\"");
			}
			else if(state == ArticleListState.MARKED)
			{
				if(searchTerm != "")
					message = _(@"No starred articles that fit \"$search\" in category \"$name\"");
				else
					message = _(@"No starred articles in category \"$name\"");
			}
			else if(state == ArticleListState.ALL)
			{
				if(searchTerm != "")
					message = _(@"No articles that fit \"$search\" in category \"$name\"");
				else
					message = _(@"No articles in category \"$name\"");
			}
			break;
		}
	}
	else
	{
		if(state == ArticleListState.UNREAD)
		{
			if(searchTerm != "")
				message = _(@"No unread articles that fit \"$search\"");
			else
				message = _("No unread articles");
		}
		else if(state == ArticleListState.MARKED)
		{
			if(searchTerm != "")
				message = _(@"No starred articles that fit \"$search\"");
			else
				message = _("No starred articles");
		}
		else if(state == ArticleListState.ALL)
		{
			if(searchTerm != "")
				message = _(@"No articles that fit \"$search\"");
			else
				message = _("No articles");
		}

	}
	this.get_style_context().add_class("dim-label");
	this.set_text(message);
}

}
