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


public class FeedReader.ArticleViewHeader : Gtk.HeaderBar {

	private Gtk.Button m_share_button;
	private Gtk.Button m_tag_button;
	private Gtk.Button m_print_button;
	private AttachedMediaButton m_media_button;
	private HoverButton m_mark_button;
	private HoverButton m_read_button;
	private Gtk.Button m_fullscreen_button;
	private Gtk.Button m_close_button;
	private SharePopover? m_sharePopover = null;

	public signal void toggledMarked();
	public signal void toggledRead();
	public signal void fsClick();
	public signal void closeArticle();
	public signal void popClosed();
	public signal void popOpened();

	public ArticleViewHeader(bool fullscreen)
	{
		var share_icon = Utils.checkIcon("emblem-shared-symbolic", "feed-share-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		var tag_icon = new Gtk.Image.from_icon_name("feed-tag-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		var marked_icon = new Gtk.Image.from_icon_name("feed-marked-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		var unmarked_icon = new Gtk.Image.from_icon_name("feed-unmarked-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		var read_icon = new Gtk.Image.from_icon_name("feed-read-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		var unread_icon = new Gtk.Image.from_icon_name("feed-unread-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		var fs_icon = new Gtk.Image.from_icon_name(fullscreen ? "view-restore-symbolic" : "view-fullscreen-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		var close_icon = new Gtk.Image.from_icon_name("window-close-symbolic", Gtk.IconSize.SMALL_TOOLBAR);

		m_mark_button = new HoverButton(unmarked_icon, marked_icon, false);
		m_mark_button.sensitive = false;
		m_mark_button.clicked.connect(() => {
			toggledMarked();
		});
		m_read_button = new HoverButton(read_icon, unread_icon, false);
		m_read_button.sensitive = false;
		m_read_button.clicked.connect(() => {
			toggledRead();
		});

		m_fullscreen_button = new Gtk.Button();
		m_fullscreen_button.add(fs_icon);
		m_fullscreen_button.set_relief(Gtk.ReliefStyle.NONE);
		m_fullscreen_button.set_focus_on_click(false);
		m_fullscreen_button.set_tooltip_text(fullscreen ? _("Leave fullscreen mode") : _("Read article fullscreen"));
		m_fullscreen_button.sensitive = false;
		m_fullscreen_button.clicked.connect(() => {
			fsClick();
		});

		m_close_button = new Gtk.Button();
		m_close_button.add(close_icon);
		m_close_button.set_relief(Gtk.ReliefStyle.NONE);
		m_close_button.set_focus_on_click(false);
		m_close_button.set_tooltip_text(_("Close article"));
		m_close_button.sensitive = false;
		m_close_button.clicked.connect(() => {
			closeArticle();
		});

		m_tag_button = new Gtk.Button();
		m_tag_button.add(tag_icon);
		m_tag_button.set_relief(Gtk.ReliefStyle.NONE);
		m_tag_button.set_focus_on_click(false);
		m_tag_button.set_tooltip_text(_("Tag article"));
		m_tag_button.sensitive = false;
		m_tag_button.clicked.connect(() => {
			popOpened();
			var pop = new TagPopover(m_tag_button);
			pop.closed.connect(() => {
				popClosed();
			});
		});


		m_print_button = new Gtk.Button.from_icon_name("printer-symbolic");
		m_print_button.set_relief(Gtk.ReliefStyle.NONE);
		m_print_button.set_focus_on_click(false);
		m_print_button.set_tooltip_text(_("Print article"));
		m_print_button.sensitive = false;
		m_print_button.clicked.connect(() => {
			ColumnView.get_default().print();
		});


		m_share_button = new Gtk.Button();
		m_share_button.add(share_icon);
		m_share_button.set_relief(Gtk.ReliefStyle.NONE);
		m_share_button.set_focus_on_click(false);
		m_share_button.set_tooltip_text(_("Share article"));
		m_share_button.sensitive = false;

		var shareSpinner = new Gtk.Spinner();
		var shareStack = new Gtk.Stack();
		shareStack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		shareStack.set_transition_duration(100);
		shareStack.add_named(m_share_button, "button");
		shareStack.add_named(shareSpinner, "spinner");
		shareStack.set_visible_child_name("button");

		m_share_button.clicked.connect(() => {
			popOpened();
			m_sharePopover = new SharePopover(m_share_button);
			m_sharePopover.startShare.connect(() => {
				shareStack.set_visible_child_name("spinner");
				shareSpinner.start();
			});
			m_sharePopover.shareDone.connect(() => {
				shareStack.set_visible_child_name("button");
				shareSpinner.stop();
			});
			m_sharePopover.closed.connect(() => {
				m_sharePopover = null;
				popClosed();
			});
		});

		m_media_button = new AttachedMediaButton();
		m_media_button.popOpened.connect(() => {
			popOpened();
		});
		m_media_button.popClosed.connect(() => {
			popClosed();
		});

		if (!fullscreen)
		{
			this.pack_start(m_close_button);
		}
		this.pack_start(m_fullscreen_button);
		this.pack_start(m_mark_button);
		this.pack_start(m_read_button);
		this.pack_end(shareStack);
		this.pack_end(m_tag_button);
		this.pack_end(m_print_button);
		this.pack_end(m_media_button);
	}

	public void showArticleButtons(bool show)
	{
		Logger.debug("HeaderBar: showArticleButtons %s".printf(sensitive ? "true" : "false"));
		m_mark_button.sensitive = show;
		m_read_button.sensitive = show;
		m_fullscreen_button.sensitive = show;
		m_close_button.sensitive = show;
		m_share_button.sensitive = (show && FeedReaderApp.get_default().isOnline());
		m_print_button.sensitive = show;

		if(FeedReaderBackend.get_default().supportTags()
		&& Utils.canManipulateContent())
		{
			m_tag_button.sensitive = (show && FeedReaderApp.get_default().isOnline());
		}
	}

	public void setMarked(ArticleStatus marked)
	{
		switch(marked)
		{
			case ArticleStatus.MARKED:
			m_mark_button.setActive(true);
			break;
			case ArticleStatus.UNMARKED:
			default:
			m_read_button.setActive(false);
			break;
		}
	}

	public void toggleMarked()
	{
		m_mark_button.toggle();
	}

	public void setRead(ArticleStatus read)
	{
		switch(read)
		{
			case ArticleStatus.UNREAD:
			m_read_button.setActive(true);
			break;
			case ArticleStatus.READ:
			default:
			m_read_button.setActive(false);
			break;
		}
	}

	public void toggleRead()
	{
		m_read_button.toggle();
	}

	public void setOffline()
	{
		m_share_button.sensitive = false;
		if(Utils.canManipulateContent()
		&& FeedReaderBackend.get_default().supportTags())
		{
			m_tag_button.sensitive = false;
		}
	}

	public void setOnline()
	{
		if(m_mark_button.sensitive)
		{
			m_share_button.sensitive = true;
			if(Utils.canManipulateContent()
			&& FeedReaderBackend.get_default().supportTags())
			{
				m_tag_button.sensitive = true;
			}
		}
	}

	public void showMediaButton(bool show)
	{
		m_media_button.update();
		m_media_button.visible = show;
	}

	public void refreshSahrePopover()
	{
		if(m_sharePopover == null)
		{
			return;
		}

		m_sharePopover.refreshList();
	}

}
