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

public class FeedReader.RemovePopover : Gtk.Popover {

	public RemovePopover(Gtk.Widget parent, FeedListType type, string id)
	{
		this.relative_to = parent;
		this.position = Gtk.PositionType.TOP;

		string name = "ERROR!!!111eleven";

		switch(type)
		{
			case FeedListType.TAG:
				var tag = dataBase.read_tag(id);
				name = tag.getTitle();
				break;

			case FeedListType.FEED:
				var feed = dataBase.read_feed(id);
				name = feed.getTitle();
				break;

			case FeedListType.CATEGORY:
				var cat = dataBase.read_category(id);
				name = cat.getTitle();
				break;
		}

		var removeButton = new Gtk.Button.with_label(_("Remove \"%s\"").printf(name));
		removeButton.get_style_context().add_class(Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
		removeButton.clicked.connect(removeFeed);
		removeButton.margin = 10;
		this.add(removeButton);
		this.show_all();
	}

	public void removeFeed()
	{

	}
}
