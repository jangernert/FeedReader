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

public class FeedReader.MediaPopover : Gtk.Popover {

	private Gtk.ListBox m_list;
	private Gee.ArrayList<string> m_media;
	public signal void play(string url);

	public MediaPopover(Gtk.Widget widget)
	{
        m_list = new Gtk.ListBox();
        m_list.margin = 10;
        m_list.set_selection_mode(Gtk.SelectionMode.NONE);
        m_list.row_activated.connect(playMedia);
        populateList();
		this.add(m_list);
		this.set_modal(true);
		this.set_relative_to(widget);
		this.set_position(Gtk.PositionType.BOTTOM);
        this.show_all();
	}

    private void populateList()
    {
		var window = ((FeedApp)GLib.Application.get_default()).getWindow();
		if(window != null)
		{
			m_media = window.getContent().getSelectedArticleMedia();
		}

        foreach(string media in m_media)
        {
        	m_list.add(new mediaRow(media));
        }
    }

	private void playMedia(Gtk.ListBoxRow row)
    {
        this.hide();
        mediaRow? mRow = row as mediaRow;

		if(mRow != null)
		{
			if(settings_general.get_boolean("mediaplayer"))
			{
				play(mRow.getURL());
			}
			else
			{
				try
				{
					string[] spawn_args = {"xdg-open", mRow.getURL()};
					GLib.Process.spawn_async("/", spawn_args, null , GLib.SpawnFlags.SEARCH_PATH, null, null);
				}
				catch(GLib.SpawnError e)
				{
					Logger.get().error("spawning command line: %s".printf(e.message));
				}
			}
		}
    }
}
