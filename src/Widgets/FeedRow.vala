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

	private Gtk.Box m_box;
	private Gtk.Label m_label;
	private bool m_subscribed;
	private string m_catID;
	private int m_level;
	private Gtk.Revealer m_revealer;
	private Gtk.Image m_icon;
	private Gtk.Label m_unread;
	private uint m_unread_count;
	private Gtk.EventBox m_eventBox;
	private Gtk.EventBox m_unreadBox;
	private bool m_unreadHovered;
	private Gtk.Stack m_unreadStack;
	private uint m_timeout_source_id;
	private string m_name { get; private set; }
	private string m_feedID { get; private set; }
	public signal void setAsRead(FeedListType type, string id);
	public signal void moveUP();
	public signal void deselectRow();

	public FeedRow (string? text, uint unread_count, bool has_icon, string feedID, string catID, int level)
	{
		m_level = level;
		m_catID = catID;
		m_subscribed = true;
		m_name = text;
		m_feedID = feedID;

		if(text != null)
		{
			var rowhight = 30;
			m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
			m_icon = getFeedIcon();

			m_icon.margin_start = level * 24;

			m_unread_count = unread_count;
			m_label = new Gtk.Label(m_name);
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
			m_unreadBox.button_press_event.connect(onUnreadClick);
			m_unreadBox.enter_notify_event.connect(onUnreadEnter);
			m_unreadBox.leave_notify_event.connect(onUnreadLeave);


			if(!UtilsUI.onlyShowFeeds())
				this.get_style_context().add_class("fr-sidebar-feed");
			else
				this.get_style_context().add_class("fr-sidebar-row");

			m_box.pack_start(m_icon, false, false, 8);
			m_box.pack_start(m_label, true, true, 0);
			m_box.pack_end (m_unreadBox, false, false, 8);

			m_eventBox = new Gtk.EventBox();
			if(m_feedID != FeedID.ALL.to_string())
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

			set_unread_count(m_unread_count);

			try
			{
				if(m_feedID != FeedID.ALL.to_string()
				&& !settings_general.get_boolean("only-feeds")
				&& UtilsUI.canManipulateContent()
				&& feedDaemon_interface.supportCategories())
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
			catch(GLib.Error e)
			{
				logger.print(LogMessage.ERROR, "FeedRow.constructor: %s".printf(e.message));
			}
		}
	}

	private void onDragBegin(Gtk.Widget widget, Gdk.DragContext context)
	{
		logger.print(LogMessage.DEBUG, "FeedRow: onDragBegin");
		Gtk.drag_set_icon_widget(context, getFeedIconWindow(), 0, 0);

	}

	public void onDragDataGet(Gtk.Widget widget, Gdk.DragContext context, Gtk.SelectionData selection_data, uint target_type, uint time)
	{
		logger.print(LogMessage.DEBUG, "FeedRow: onDragDataGet");

		if(target_type == DragTarget.FEED)
		{
			selection_data.set_text(m_feedID + "," + m_catID, -1);
		}
	}

	private Gtk.Image getFeedIcon()
	{
		try{
			if(FileUtils.test(getIconPath(), GLib.FileTest.EXISTS))
			{
				var tmp_icon = new Gdk.Pixbuf.from_file_at_scale(getIconPath(), 24, 24, true);
				return new Gtk.Image.from_pixbuf(tmp_icon);
			}
		}
		catch(GLib.Error e){}

		var defaultIcon = new Gtk.Image.from_icon_name("feed-rss-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
		defaultIcon.get_style_context().add_class("fr-sidebar-symbolic");
		return defaultIcon;
	}

	private Gtk.Window getFeedIconWindow()
	{
		var window = new Gtk.Window(Gtk.WindowType.POPUP);
		var visual = window.get_screen().get_rgba_visual();
		window.set_visual(visual);
		window.get_style_context().add_class("transparentBG");
		window.add(getFeedIcon());
		window.show_all();
		return window;
	}

	private string getIconPath()
	{
		string icon_path = GLib.Environment.get_home_dir() + "/.local/share/feedreader/data/feed_icons/";
		return icon_path + m_feedID.replace("/", "_").replace(".", "_") + ".ico";
	}

	private bool onClick(Gdk.EventButton event)
	{
		// only right click allowed
		if(event.button != 3)
			return false;

		if(!UtilsUI.canManipulateContent())
			return false;

		switch(event.type)
		{
			case Gdk.EventType.BUTTON_RELEASE:
			case Gdk.EventType.@2BUTTON_PRESS:
			case Gdk.EventType.@3BUTTON_PRESS:
				return false;
		}

		var remove_action = new GLib.SimpleAction("deleteFeed", null);
		remove_action.activate.connect(() => {
			if(this.is_selected())
				moveUP();

			uint time = 300;
			this.reveal(false, time);

			var content = ((FeedApp)GLib.Application.get_default()).getWindow().getContent();
			var notification = content.showNotification(_("Feed \"%s\" removed").printf(m_name));
			ulong eventID = notification.dismissed.connect(() => {
				try
				{
					feedDaemon_interface.removeFeed(m_feedID);
				}
				catch(GLib.Error e)
				{
					logger.print(LogMessage.ERROR, "FeedRow.onClick: %s".printf(e.message));
				}
			});
			notification.action.connect(() => {
				notification.disconnect(eventID);
				this.reveal(true, time);
				notification.dismiss();
			});
		});

		var markAsRead_action = new GLib.SimpleAction("markFeedAsRead", null);
		markAsRead_action.activate.connect(() => {
			setAsRead(FeedListType.FEED, m_feedID);
		});

		if(m_unread_count != 0)
			markAsRead_action.set_enabled(true);
		else
			markAsRead_action.set_enabled(false);

		var rename_action = new GLib.SimpleAction("renameFeed", null);
		rename_action.activate.connect(showRenamePopover);

		var app = (FeedApp)GLib.Application.get_default();
		app.add_action(markAsRead_action);
		app.add_action(rename_action);
		app.add_action(remove_action);

		var feed = dataBase.read_feed(m_feedID);
		var catCount = feed.getCatIDs().length;
		var cat = dataBase.read_category(m_catID);

		var menu = new GLib.Menu();
		menu.append(_("Mark as read"), "markFeedAsRead");
		menu.append(_("Rename"), "renameFeed");
		if(catCount > 1)
			menu.append(_("Remove only from %s").printf(cat.getTitle()), "deleteFeed");
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
		renameEntry.set_text(m_name);
		renameEntry.activate.connect(() => {
			popRename.hide();
			try
			{
				feedDaemon_interface.renameFeed(m_feedID, renameEntry.get_text());
			}
			catch(GLib.Error e)
			{
				logger.print(LogMessage.ERROR, "FeedRow.showRenamePopover: %s".printf(e.message));
			}
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
		m_unread_count = unread_count;

		if(m_unread_count > 0 && !m_unreadHovered)
		{
			m_unreadStack.set_visible_child_name("unreadCount");
			m_unread.set_text(m_unread_count.to_string());
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
		if(m_unreadHovered && m_unread_count > 0)
		{
			setAsRead(FeedListType.FEED, m_feedID);
		}
		return true;
	}

	private bool onUnreadEnter(Gdk.EventCrossing event)
	{
		m_unreadHovered = true;
		if(m_unread_count > 0)
		{
			m_unreadStack.set_visible_child_name("mark");
		}
		return true;
	}

	private bool onUnreadLeave(Gdk.EventCrossing event)
	{
		m_unreadHovered = false;
		if(m_unread_count > 0)
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
		set_unread_count(m_unread_count+1);
	}

	public void downUnread()
	{
		if(m_unread_count > 0)
			set_unread_count(m_unread_count-1);
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
		return m_catID;
	}

	public string getID()
	{
		return m_feedID;
	}

	public string getName()
	{
		return m_name;
	}

	public bool isSubscribed()
	{
		return m_subscribed;
	}

	public uint getUnreadCount()
	{
		return m_unread_count;
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

		if(settings_state.get_boolean("no-animations"))
		{
			if(!reveal)
			{
				this.hide();
			}
			m_revealer.set_transition_type(Gtk.RevealerTransitionType.NONE);
			m_revealer.set_transition_duration(0);
			m_revealer.set_reveal_child(reveal);
			m_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
			m_revealer.set_transition_duration(500);
		}
		else
		{
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
	}

}
