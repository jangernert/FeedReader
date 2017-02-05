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

public class FeedReader.FullscreenHeader : Gtk.EventBox {

	private Gtk.Revealer m_revealer;
	private ArticleViewHeader m_header;
	private bool m_hover = false;
	private bool m_popover = false;
	private uint m_timeout_source_id = 0;

	public FullscreenHeader()
	{
		m_header = new ArticleViewHeader("view-restore-symbolic", _("Leave fullscreen mode"));
		m_header.get_style_context().add_class("titlebar");
		m_header.get_style_context().add_class("imageOverlay");
		m_header.valign = Gtk.Align.START;
		m_header.toggledMarked.connect(() => {
			ColumnView.get_default().toggleMarkedSelectedArticle();
		});
		m_header.toggledRead.connect(() => {
			ColumnView.get_default().toggleReadSelectedArticle();
		});
		m_header.fsClick.connect(() => {
			ColumnView.get_default().showPane();
			ColumnView.get_default().leaveFullscreenArticle();
			MainWindow.get_default().unfullscreen();
		});
		m_header.popOpened.connect(() => {
			m_popover = true;
		});
		m_header.popClosed.connect(() => {
			m_popover = false;
			if(!m_hover)
				m_revealer.set_reveal_child(false);
		});
		m_header.showArticleButtons(true);
		m_revealer = new Gtk.Revealer();
		m_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
		m_revealer.set_transition_duration(300);
		m_revealer.valign = Gtk.Align.START;
		m_revealer.add(m_header);

		this.set_size_request(0, 80);
		this.no_show_all = true;
		this.enter_notify_event.connect((event) => {
			m_revealer.set_transition_duration(300);
			m_revealer.show_all();
			m_revealer.set_reveal_child(true);
			m_hover = true;
			removeTimeout();
			return true;
		});
		this.leave_notify_event.connect((event) => {
			if(event.detail == Gdk.NotifyType.INFERIOR)
				return false;

			if(event.detail == Gdk.NotifyType.NONLINEAR_VIRTUAL)
		        return false;

			m_hover = false;

			if(m_popover)
				return false;


			removeTimeout();
			m_timeout_source_id = GLib.Timeout.add(500, () => {
				m_revealer.set_transition_duration(800);
				m_revealer.set_reveal_child(false);
				m_timeout_source_id = 0;
				return false;
			});

			return true;
		});
		this.add(m_revealer);
		this.valign = Gtk.Align.START;
	}

	public void setTitle(string title)
	{
		m_header.set_title(title);
	}

	public void setMarked(bool marked)
	{
		m_header.setMarked(marked);
	}

	public void setUnread(bool unread)
	{
		m_header.setRead(unread);
	}

	private void removeTimeout()
	{
		if(m_timeout_source_id > 0)
		{
			GLib.Source.remove(m_timeout_source_id);
			m_timeout_source_id = 0;
		}
	}

	public void showMediaButton(bool show)
	{
		m_header.showMediaButton(show);
	}
}
