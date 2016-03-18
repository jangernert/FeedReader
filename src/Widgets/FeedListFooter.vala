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

public class FeedReader.FeedListFooter : Gtk.Box {

	private Gtk.Box m_box;

	public FeedListFooter()
	{
		this.orientation = Gtk.Orientation.VERTICAL;
		this.spacing = 0;
		this.set_size_request(0, 40);
		this.valign = Gtk.Align.END;
		this.get_style_context().add_class("FeedListFooter");

		var addButton = new Gtk.Button.from_icon_name("feed-add", Gtk.IconSize.SMALL_TOOLBAR);
		addButton.get_style_context().remove_class("button");
		addButton.get_style_context().add_class("FeedListFooterButton");
		addButton.get_image().opacity = 0.8;
		addButton.clicked.connect(() => {
			addButton.get_style_context().add_class("FeedListFooterButtonPopover");
			var addPop = new AddPopover(addButton);
			addPop.closed.connect(() => {
				addButton.get_style_context().remove_class("FeedListFooterButtonPopover");
			});
			addPop.show();
		});

		var removeButton = new Gtk.Button.from_icon_name("feed-remove", Gtk.IconSize.SMALL_TOOLBAR);
		removeButton.get_style_context().remove_class("button");
		removeButton.get_style_context().add_class("FeedListFooterButton");
		removeButton.get_image().opacity = 0.8;

		m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		m_box.pack_start(addButton);
		m_box.pack_start(new Gtk.Separator(Gtk.Orientation.VERTICAL), false, false);
		m_box.pack_start(removeButton);

		this.pack_start(new Gtk.Separator(Gtk.Orientation.HORIZONTAL), false, false);
		this.pack_start(m_box);
	}
}
