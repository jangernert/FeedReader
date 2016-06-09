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

public class FeedReader.fullscreenHeaderbar : Gtk.EventBox {

	private Gtk.Revealer m_revealer;
	private Gtk.HeaderBar m_header;
	public signal void close();

	public fullscreenHeaderbar()
	{
		var close_icon = new Gtk.Image.from_icon_name("view-restore-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		var closeButton = new Gtk.Button();
		closeButton.add(close_icon);
		closeButton.set_relief(Gtk.ReliefStyle.NONE);
		closeButton.set_focus_on_click(false);
		closeButton.set_tooltip_text(_("Leave fullscreen mode"));
		closeButton.clicked.connect(() => {
			close();
		});
		m_header = new Gtk.HeaderBar();
		m_header.get_style_context().add_class("titlebar");
		m_header.get_style_context().add_class("imageOverlay");
		m_header.valign = Gtk.Align.START;
		m_header.pack_end(closeButton);
		m_revealer = new Gtk.Revealer();
		m_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
		m_revealer.set_transition_duration(300);
		m_revealer.valign = Gtk.Align.START;
		m_revealer.add(m_header);

		this.set_size_request(0, 50);
		this.no_show_all = true;
		this.enter_notify_event.connect((event) => {
			m_revealer.show_all();
			m_revealer.set_reveal_child(true);
			return true;
		});
		this.leave_notify_event.connect((event) => {
			if(event.detail == Gdk.NotifyType.INFERIOR)
				return false;

			m_revealer.set_reveal_child(false);
			return true;
		});
		this.add(m_revealer);
		this.valign = Gtk.Align.START;
	}

	public void setTitle(string title)
	{
		m_header.set_title(title);
	}


}
