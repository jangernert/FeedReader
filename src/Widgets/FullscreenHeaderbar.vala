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
	private HoverButton m_mark_button;
	private HoverButton m_read_button;
	private Gtk.Button m_share_button;
	private Gtk.Button m_tag_button;
	private bool m_popover = false;
	private bool m_hover = false;
	private uint m_timeout_source_id = 0;
	public signal void close();

	public fullscreenHeaderbar()
	{
		var marked_icon = new Gtk.Image.from_icon_name("feed-marked-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		var unmarked_icon = new Gtk.Image.from_icon_name("feed-unmarked-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		var read_icon = new Gtk.Image.from_icon_name("feed-read-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		var unread_icon = new Gtk.Image.from_icon_name("feed-unread-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		var share_icon = new Gtk.Image.from_icon_name("feed-share-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		var tag_icon = new Gtk.Image.from_icon_name("feed-tag-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		var close_icon = new Gtk.Image.from_icon_name("view-restore-symbolic", Gtk.IconSize.SMALL_TOOLBAR);

		m_mark_button = new HoverButton(unmarked_icon, marked_icon, false);
		m_mark_button.set_tooltip_text(_("Mark article (un)starred"));
		m_mark_button.clicked.connect(() => {
			var window = this.get_toplevel() as readerUI;
			if(window != null && window.is_toplevel())
				window.getContent().toggleMarkedSelectedArticle();
		});
		m_read_button = new HoverButton(read_icon, unread_icon, false);
		m_read_button.set_tooltip_text(_("Mark article (un)read"));
		m_read_button.clicked.connect(() => {
			var window = this.get_toplevel() as readerUI;
			if(window != null && window.is_toplevel())
				window.getContent().toggleReadSelectedArticle();
		});

		m_tag_button = new Gtk.Button();
		m_tag_button.add(tag_icon);
		m_tag_button.set_relief(Gtk.ReliefStyle.NONE);
		m_tag_button.set_focus_on_click(false);
		m_tag_button.set_tooltip_text(_("Tag Article"));
		m_tag_button.clicked.connect(() => {
			m_popover = true;
			var pop = new TagPopover(m_tag_button);
			pop.closed.connect(() => {
				m_popover = false;
				if(!m_hover)
					m_revealer.set_reveal_child(false);
			});
		});

		m_share_button = new Gtk.Button();
		m_share_button.add(share_icon);
		m_share_button.set_relief(Gtk.ReliefStyle.NONE);
		m_share_button.set_focus_on_click(false);
		m_share_button.set_tooltip_text(_("Share Article"));
		m_share_button.clicked.connect(() => {
			m_popover = true;
			var pop = new SharePopover(m_share_button);
			pop.closed.connect(() => {
				m_popover = false;
				if(!m_hover)
					m_revealer.set_reveal_child(false);
			});
		});

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
		m_header.pack_start(m_mark_button);
		m_header.pack_start(m_read_button);
		m_header.pack_end(closeButton);
		m_header.pack_end(m_share_button);
		m_header.pack_end(m_tag_button);
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
		m_mark_button.setActive(marked);
	}

	public void setUnread(bool unread)
	{
		m_read_button.setActive(unread);
	}

	private void removeTimeout()
	{
		if(m_timeout_source_id > 0)
		{
			GLib.Source.remove(m_timeout_source_id);
			m_timeout_source_id = 0;
		}
	}
}
