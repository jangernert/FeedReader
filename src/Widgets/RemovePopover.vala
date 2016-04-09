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

	private string m_id;
	private FeedListType m_type;

	public RemovePopover(Gtk.Widget parent, FeedListType type, string id)
	{
		this.relative_to = parent;
		this.position = Gtk.PositionType.TOP;
		m_type = type;
		m_id = id;

		string name = "ERROR!!!111eleven";

		switch(m_type)
		{
			case FeedListType.TAG:
				var tag = dataBase.read_tag(m_id);
				name = tag.getTitle();
				break;

			case FeedListType.FEED:
				var feed = dataBase.read_feed(m_id);
				name = feed.getTitle();
				break;

			case FeedListType.CATEGORY:
				var cat = dataBase.read_category(m_id);
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
		var window = ((rssReaderApp)GLib.Application.get_default()).getWindow();
		var feedList = window.getContent().getFeedList();

		if(m_type == FeedListType.CATEGORY)
		{
			feedList.collapseSelectedCat();
			feedList.selectDefaultRow();
		}

		uint time = 300;
		feedList.revealRow(m_id, m_type, false, time);

		GLib.Timeout.add(time, () => {
			switch(m_type)
			{
				case FeedListType.TAG:
					feedDaemon_interface.deleteTag(m_id);
					break;

				case FeedListType.FEED:
					feedDaemon_interface.removeFeed(m_id);
					break;

				case FeedListType.CATEGORY:
					feedDaemon_interface.removeCategory(m_id);
					break;
			}

			return false;
		});

		this.hide();
	}
}
