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

	public RemovePopover(Gtk.Widget parent, string name)
	{
		this.relative_to = parent;
		this.position = Gtk.PositionType.TOP;

		var removeButton = new Gtk.Button.with_label("Remove " + name);
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
