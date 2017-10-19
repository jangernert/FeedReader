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

public class FeedReader.FeedRow : Gtk.ListBoxRow {

	private Feed m_feed;
	private string m_parentCatID;
	private Gtk.Box m_box;
	private Gtk.Label m_label;
	private bool m_subscribed;
	private Gtk.Revealer m_revealer;
	private Gtk.Image m_icon;
	private Gtk.Label m_unread;
	private Gtk.EventBox m_eventBox;
	private Gtk.EventBox m_unreadBox;
	private bool m_unreadHovered;
	private Gtk.Stack m_unreadStack;
	private uint m_timeout_source_id;
	public signal void setAsRead(FeedListType type, string id);
	public signal void copyFeedURL(string id);
	public signal void moveUP();
	public signal void deselectRow();

	public FeedRow(Feed feed, string parentCat, int level)
	{
		m_subscribed = true;
		m_parentCatID = parentCat;
		m_feed = feed;

		if(m_feed.getFeedID() != FeedID.SEPARATOR.to_string())
		{
			var rowhight = 30;
			m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			m_icon = createFavIcon();

			m_icon.margin_start = level * 24;

			m_label = new Gtk.Label(m_feed.getTitle());
			m_label.set_size_request (0, rowhight);
			m_label.set_ellipsize (Pango.EllipsizeMode.END);
			m_label.set_alignment(0, 0.5f);

			m_unread = new Gtk.Label(null);
			m_unread.set_size_request (0, rowhight);
			m_unread.set_alignment(0.8f, 0.5f);

			m_unreadStack = new Gtk.Stack();
			m_unreadStack.set_transition_type(Gtk.StackTransitionType.NONE);
			m_unreadStack.set_transition_duration(0);
			m_unreadStack.add_named(m_unread, "unreadCount");
			m_unreadStack.add_named(new Gtk.Label(""), "nothing");
			var markIcon = new Gtk.Image.from_icon_name("feed-mark-read-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
			markIcon.get_style_context().add_class("fr-sidebar-symbolic");
			m_unreadStack.add_named(markIcon, "mark");

			m_unreadBox = new Gtk.EventBox();
			m_unreadBox.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
			m_unreadBox.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
			m_unreadBox.set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
			m_unreadBox.add(m_unreadStack);
			activateUnreadEventbox(true);


			if(!Utils.onlyShowFeeds() && m_feed.getFeedID() != FeedID.ALL.to_string())
				this.get_style_context().add_class("fr-sidebar-feed");
			else
				this.get_style_context().add_class("fr-sidebar-row");

			m_box.pack_start(m_icon, false, false, 8);
			m_box.pack_start(m_label, true, true, 0);
			m_box.pack_end (m_unreadBox, false, false, 8);

			m_eventBox = new Gtk.EventBox();
			if(m_feed.getFeedID() != FeedID.ALL.to_string())
			{
				m_eventBox.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
				m_eventBox.button_press_event.connect(onClick);
			}
			m_eventBox.add(m_box);

			m_revealer = new Gtk.Revealer();
			m_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
			m_revealer.add(m_eventBox);
			m_revealer.set_reveal_child(false);
			this.add(m_revealer);
			this.no_show_all = true;;
			m_revealer.show_all();

			set_unread_count(m_feed.getUnread());

			if(m_feed.getFeedID() != FeedID.ALL.to_string()
			&& !Settings.general().get_boolean("only-feeds")
			&& Utils.canManipulateContent()
			&& FeedReaderBackend.get_default().supportCategories())
			{
				const Gtk.TargetEntry[] provided_targets = {
					{ "text/plain",     0, DragTarget.FEED }
				};

				Gtk.drag_source_set (
						this,
						Gdk.ModifierType.BUTTON1_MASK,
						provided_targets,
						Gdk.DragAction.MOVE
				);

				this.drag_begin.connect(onDragBegin);
				this.drag_data_get.connect(onDragDataGet);
			}
		}
	}

	~FeedRow()
	{
		activateUnreadEventbox(false);
		m_eventBox.button_press_event.disconnect(onClick);
		this.drag_begin.disconnect(onDragBegin);
		this.drag_data_get.disconnect(onDragDataGet);
	}

	private void onDragBegin(Gtk.Widget widget, Gdk.DragContext context)
	{
		Logger.debug("FeedRow: onDragBegin");
		Gtk.drag_set_icon_widget(context, getFeedIconWindow(), 0, 0);

	}

	public void onDragDataGet(Gtk.Widget widget, Gdk.DragContext context, Gtk.SelectionData selection_data, uint target_type, uint time)
	{
		Logger.debug("FeedRow: onDragDataGet");

		if(target_type == DragTarget.FEED)
		{
			selection_data.set_text(m_feed.getFeedID() + "," + m_parentCatID, -1);
		}
	}

	public Gtk.Image createFavIcon()
	{
		var icon = new Gtk.Image.from_icon_name("feed-rss-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
		icon.get_style_context().add_class("fr-sidebar-symbolic");

		var manager = FavIconManager.get_default();
		manager.getIcon.begin(m_feed, (obj, res) => {
			var pixbuf = manager.getIcon.end(res);
			if(pixbuf != null)
			{
				icon.pixbuf = pixbuf;
				icon.get_style_context().remove_class("fr-sidebar-symbolic");
			}
		});
		return icon;
	}

	private Gtk.Window getFeedIconWindow()
	{
		var icon = createFavIcon();
		var window = new Gtk.Window(Gtk.WindowType.POPUP);
		var visual = window.get_screen().get_rgba_visual();
		window.set_visual(visual);
		window.get_style_context().add_class("transparentBG");
		window.add(icon);
		window.show_all();
		return window;
	}

	private bool onClick(Gdk.EventButton event)
	{
		// only right click allowed
		if(event.button != 3)
			return false;

		if(!Utils.canManipulateContent())
			return false;

		switch(event.type)
		{
			case Gdk.EventType.BUTTON_RELEASE:
			case Gdk.EventType.@2BUTTON_PRESS:
			case Gdk.EventType.@3BUTTON_PRESS:
				return false;
		}

		var remove_action = new GLib.SimpleAction("deleteFeed", null);
		remove_action.activate.connect(RemoveThisFeed);

		var markAsRead_action = new GLib.SimpleAction("markFeedAsRead", null);
		markAsRead_action.activate.connect(() => {
			setAsRead(FeedListType.FEED, m_feed.getFeedID());
		});

		var copyFeedURL_action = new GLib.SimpleAction("copyFeedURL", null);
		copyFeedURL_action.activate.connect(() => {
			copyFeedURL(m_feed.getFeedID());
		});

		if(m_feed.getUnread() != 0)
			markAsRead_action.set_enabled(true);
		else
			markAsRead_action.set_enabled(false);

		var rename_action = new GLib.SimpleAction("renameFeed", null);
		rename_action.activate.connect(showRenamePopover);

		FeedReaderApp.get_default().add_action(markAsRead_action);
		FeedReaderApp.get_default().add_action(copyFeedURL_action);
		FeedReaderApp.get_default().add_action(rename_action);
		FeedReaderApp.get_default().add_action(remove_action);



		var menu = new GLib.Menu();
		menu.append(_("Mark as read"), "markFeedAsRead");
		menu.append(_("Copy URL"), "copyFeedURL");
		menu.append(_("Rename"), "renameFeed");
		if(m_feed.getCatIDs().size > 1)
		{
			var cat = DataBase.readOnly().read_category(m_parentCatID);
			menu.append(_("Remove only from %s").printf(cat.getTitle()), "deleteFeed");
		}
		menu.append(_("Remove"), "deleteFeed");

		var pop = new Gtk.Popover(this);
		pop.set_position(Gtk.PositionType.BOTTOM);
		pop.bind_model(menu, "app");
		pop.closed.connect(() => {
			this.unset_state_flags(Gtk.StateFlags.PRELIGHT);
		});

		pop.show();
		this.set_state_flags(Gtk.StateFlags.PRELIGHT, false);
		return true;
	}

	private void showRenamePopover()
	{
		var popRename = new Gtk.Popover(this);
		popRename.set_position(Gtk.PositionType.BOTTOM);
		popRename.closed.connect(() => {
			this.unset_state_flags(Gtk.StateFlags.PRELIGHT);
		});

		var renameEntry = new Gtk.Entry();
		renameEntry.set_text(m_feed.getTitle());
		renameEntry.activate.connect(() => {
			popRename.hide();
			FeedReaderBackend.get_default().renameFeed(m_feed.getFeedID(), renameEntry.get_text());
		});

		var renameButton = new Gtk.Button.with_label(_("rename"));
		renameButton.get_style_context().add_class("suggested-action");
		renameButton.clicked.connect(() => {
			renameEntry.activate();
		});

		var renameBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
		renameBox.margin = 5;
		renameBox.pack_start(renameEntry, true, true, 0);
		renameBox.pack_start(renameButton, false, false, 0);

		popRename.add(renameBox);
		popRename.show_all();
		this.set_state_flags(Gtk.StateFlags.PRELIGHT, false);
	}

	public void set_unread_count(uint unread_count)
	{
		m_feed.setUnread(unread_count);

		if(m_feed.getUnread() > 0 && !m_unreadHovered)
		{
			m_unreadStack.set_visible_child_name("unreadCount");
			m_unread.set_text(m_feed.getUnread().to_string());
		}
		else if(!m_unreadHovered)
		{
			m_unreadStack.set_visible_child_name("nothing");
		}
		else
		{
			m_unreadStack.set_visible_child_name("mark");
		}
	}

	private bool onUnreadClick(Gdk.EventButton event)
	{
		if(m_unreadHovered && m_feed.getUnread() > 0)
		{
			setAsRead(FeedListType.FEED, m_feed.getFeedID());
		}
		return true;
	}

	private bool onUnreadEnter(Gdk.EventCrossing event)
	{
		m_unreadHovered = true;
		if(m_feed.getUnread() > 0)
		{
			m_unreadStack.set_visible_child_name("mark");
		}
		return true;
	}

	private bool onUnreadLeave(Gdk.EventCrossing event)
	{
		m_unreadHovered = false;
		if(m_feed.getUnread() > 0)
		{
			m_unreadStack.set_visible_child_name("unreadCount");
		}
		else
		{
			m_unreadStack.set_visible_child_name("nothing");
		}
		return true;
	}

	public void upUnread()
	{
		set_unread_count(m_feed.getUnread() + 1);
	}

	public void downUnread()
	{
		if(m_feed.getUnread() > 0)
			set_unread_count(m_feed.getUnread() - 1);
	}

	public void update(string text, uint unread_count)
	{
		m_label.set_text(text.replace("&","&amp;"));
		set_unread_count(unread_count);
	}

	public void setSubscribed(bool subscribed)
	{
		m_subscribed = subscribed;
	}

	public string getCatID()
	{
		return m_parentCatID;
	}

	public string getID()
	{
		return m_feed.getFeedID();
	}

	public string getName()
	{
		return m_feed.getTitle();
	}

	public bool isSubscribed()
	{
		return m_subscribed;
	}

	public uint getUnreadCount()
	{
		return m_feed.getUnread();
	}

	public bool isRevealed()
	{
		return m_revealer.get_reveal_child();
	}

	public void reveal(bool reveal, uint duration = 500)
	{
		if(m_timeout_source_id > 0)
		{
			GLib.Source.remove(m_timeout_source_id);
			m_timeout_source_id = 0;
		}

		if(reveal)
		{
			this.show();
		}

		m_revealer.set_transition_duration(duration);
		m_revealer.set_reveal_child(reveal);
		if(!reveal)
		{
			if(this.is_selected())
				deselectRow();

			m_timeout_source_id = GLib.Timeout.add(duration, () => {
				this.hide();
				m_timeout_source_id = 0;
				return false;
			});
		}
	}

	public void activateUnreadEventbox(bool activate)
	{
		if(activate)
		{
			m_unreadBox.button_press_event.connect(onUnreadClick);
			m_unreadBox.enter_notify_event.connect(onUnreadEnter);
			m_unreadBox.leave_notify_event.connect(onUnreadLeave);
		}
		else
		{
			m_unreadBox.button_press_event.disconnect(onUnreadClick);
			m_unreadBox.enter_notify_event.disconnect(onUnreadEnter);
			m_unreadBox.leave_notify_event.disconnect(onUnreadLeave);
		}
	}

	private void RemoveThisFeed(Variant? parameter)
	{
		if(this.is_selected())
			moveUP();

		uint time = 300;
		this.reveal(false, time);

		var notification = MainWindow.get_default().showNotification(_("Feed removed: %s").printf(m_feed.getTitle()));
		ulong eventID = notification.dismissed.connect(() => {
			FeedReaderBackend.get_default().removeFeed(m_feed.getFeedID());
		});
		notification.action.connect(() => {
			notification.disconnect(eventID);
			this.reveal(true, time);
			notification.dismiss();
		});
	}
}
