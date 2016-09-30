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
	private feedList m_feedlist;
	private uint m_time = 300;
	private string m_name;

	public RemovePopover(Gtk.Widget parent, FeedListType type, string id)
	{
		this.relative_to = parent;
		this.position = Gtk.PositionType.TOP;
		m_type = type;
		m_id = id;

		switch(m_type)
		{
			case FeedListType.TAG:
				m_name = dataBase.getTagName(m_id);
				break;

			case FeedListType.FEED:
				m_name = dataBase.getFeedName(m_id);
				break;

			case FeedListType.CATEGORY:
				m_name = dataBase.getCategoryName(m_id);
				break;
		}

		var removeButton = new Gtk.Button.with_label(_("Remove \"%s\"").printf(m_name));
		removeButton.get_style_context().add_class(Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
		removeButton.clicked.connect(removeX);
		removeButton.margin = 10;
		this.add(removeButton);
		this.show_all();
	}

	public void removeX()
	{
		var window = ((FeedApp)GLib.Application.get_default()).getWindow();
		m_feedlist = window.getContent().getFeedList();
		m_feedlist.moveUP();
		m_feedlist.revealRow(m_id, m_type, false, m_time);

		switch(m_type)
		{
			case FeedListType.TAG:
				removeTag();
				break;

			case FeedListType.FEED:
				removeFeed();
				break;

			case FeedListType.CATEGORY:
				removeCategory();
				break;
		}

		this.hide();
	}

	private void removeTag()
	{
		var content = ((FeedApp)GLib.Application.get_default()).getWindow().getContent();
		string text = _("Tag \"%s\" removed").printf(m_name);
		var notification = content.showNotification(text);

		ulong eventID = notification.dismissed.connect(() => {
			try
			{
				feedDaemon_interface.deleteTag(m_id);
			}
			catch(GLib.Error e)
			{
				logger.print(LogMessage.ERROR, "RemovePopover.removeTag: %s".printf(e.message));
			}
		});
		notification.action.connect(() => {
			notification.disconnect(eventID);
			m_feedlist.revealRow(m_id, m_type, true, m_time);
			notification.dismiss();
		});
	}

	private void removeFeed()
	{
		var content = ((FeedApp)GLib.Application.get_default()).getWindow().getContent();
		string text = _("Feed \"%s\" removed").printf(m_name);
		var notification = content.showNotification(text);

		ulong eventID = notification.dismissed.connect(() => {
			try
			{
				feedDaemon_interface.removeFeed(m_id);
			}
			catch(GLib.Error e)
			{
				logger.print(LogMessage.ERROR, "RemovePopover.removeFeed: %s".printf(e.message));
			}
		});
		notification.action.connect(() => {
			notification.disconnect(eventID);
			m_feedlist.revealRow(m_id, m_type, true, m_time);
			notification.dismiss();
		});
	}

	private void removeCategory()
	{
		m_feedlist.expand_collapse_category(m_id, false);
		var content = ((FeedApp)GLib.Application.get_default()).getWindow().getContent();
		string text = _("Category \"%s\" removed").printf(m_name);
		var notification = content.showNotification(text);

		ulong eventID = notification.dismissed.connect(() => {
			try
			{
				feedDaemon_interface.removeCategory(m_id);
			}
			catch(GLib.Error e)
			{
				logger.print(LogMessage.ERROR, "RemovePopover.removeCategory: %s".printf(e.message));
			}
		});
		notification.action.connect(() => {
			notification.disconnect(eventID);
			m_feedlist.revealRow(m_id, m_type, true, m_time);
			notification.dismiss();
		});
	}
}
