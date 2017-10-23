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

public class FeedReader.AttachedMediaButton : Gtk.Button {

	private Gtk.ListBox m_list;
	private Gtk.Image m_playIcon;
	private Gtk.Image m_filesIcon;
	private Gtk.Spinner m_spinner;
	private Gtk.Stack m_stack;
	private Gee.List<string> m_media;
	private Gtk.Popover m_pop;
	private ulong m_signalID = 0;
	public signal void play(string url);
	public signal void popClosed();
	public signal void popOpened();

	public AttachedMediaButton()
	{
		m_filesIcon = new Gtk.Image.from_icon_name("mail-attachment-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		m_playIcon = new Gtk.Image.from_icon_name("media-playback-start-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		m_spinner = new Gtk.Spinner();
		m_spinner.set_size_request(16,16);

		m_stack = new Gtk.Stack();
		m_stack.set_transition_duration(100);
		m_stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		m_stack.add_named(m_spinner, "spinner");
		m_stack.add_named(m_playIcon, "play");
		m_stack.add_named(m_filesIcon, "files");
		this.add(m_stack);
		this.set_relief(Gtk.ReliefStyle.NONE);
		this.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
		this.set_focus_on_click(false);

		m_list = new Gtk.ListBox();
		m_list.margin = 10;
		m_list.set_selection_mode(Gtk.SelectionMode.NONE);
		m_list.row_activated.connect((row) => {
			m_spinner.start();
			m_pop.hide();
			mediaRow? mRow = row as mediaRow;
			if(mRow != null)
				playMedia(mRow.getURL());
			else
				Logger.error("MediaPopover: invalid row clicked");
		});

		m_pop = new Gtk.Popover(this);
		m_pop.add(m_list);
		m_pop.set_modal(true);
		m_pop.set_position(Gtk.PositionType.BOTTOM);
		m_pop.closed.connect(() => {
			popClosed();
		});
	}

	public void update()
	{
		m_media = new Gee.ArrayList<string>();
		Article? selectedArticle = ColumnView.get_default().getSelectedArticle();
		if(selectedArticle != null)
		{
			m_media = selectedArticle.getMedia();
		}

		if(m_signalID != 0)
		{
			this.disconnect(m_signalID);
			m_signalID = 0;
		}

		if(m_media.size == 1)
		{
			m_stack.set_visible_child_name("play");
			int lastSlash = m_media.get(0).last_index_of_char('/');
			string fileName = m_media.get(0).substring(lastSlash + 1);
			this.set_tooltip_text(fileName);
			m_signalID = this.clicked.connect(() => {
				playMedia(m_media.get(0));
				m_spinner.start();
			});
		}
		else if(m_media.size > 1)
		{
			m_stack.set_visible_child_name("files");
			this.set_tooltip_text(_("Attachments"));
			var children = m_list.get_children();
			foreach(Gtk.Widget row in children)
			{
				m_list.remove(row);
			}
			foreach(string media in m_media)
			{
				m_list.add(new mediaRow(media));
			}
			m_signalID = this.clicked.connect(() => {
				popOpened();
				m_pop.show_all();
			});
		}
		else
		{
			// no media
		}
	}

	private void playMedia(string url)
	{
		Logger.debug(@"MediaButton.playMedia: $url");
		if(Settings.general().get_boolean("mediaplayer"))
		{
			m_stack.set_visible_child_name("spinner");
			var media = new MediaPlayer(url);
			media.loaded.connect(() => {
				m_spinner.stop();
				if(m_media.size > 1)
					m_stack.set_visible_child_name("files");
				else
					m_stack.set_visible_child_name("play");
			});
			ColumnView.get_default().ArticleViewAddMedia(media);
		}
		else
		{
			try
			{
				Gtk.show_uri_on_window(MainWindow.get_default(), url, Gdk.CURRENT_TIME);
			}
			catch(GLib.Error e)
			{
				Logger.debug("could not open the link in an external browser: %s".printf(e.message));
			}
		}
	}
}
