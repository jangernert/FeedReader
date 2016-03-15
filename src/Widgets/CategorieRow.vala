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

public class FeedReader.categorieRow : Gtk.ListBoxRow {

	private Gtk.Box m_box;
	private string m_name;
	private Gtk.Label m_label;
	private Gtk.EventBox m_eventBox;
	private Gtk.EventBox m_expandBox;
	private Gtk.EventBox m_unreadBox;
	private Gtk.Revealer m_revealer;
	private Gtk.Label m_unread;
	private uint m_unread_count;
	private string m_categorieID;
	private string m_parentID;
	private int m_orderID;
	private int m_level;
	private Gtk.Image m_icon;
	private Gtk.Image m_icon_expanded;
	private Gtk.Image m_icon_collapsed;
	private Gtk.Stack m_stack;
	private double m_opacity = 0.8;
	private bool m_collapsed;
	private bool m_exists = true;
	private bool m_hovered = false;
	private bool m_unreadHovered = false;
	private Gtk.Stack m_unreadStack;
	public signal void collapse(bool collapse, string catID);
	public signal void setAsRead(FeedListType type, string id);
	public signal void selectDefaultRow();

	public categorieRow (string name, string categorieID, int orderID, uint unread_count, string parentID, int level, bool expanded) {

		this.get_style_context().add_class("feed-list-row");
		m_level = level;
		m_parentID = parentID;
		m_orderID = orderID;
		m_collapsed = !expanded;
		m_name = name;
		m_categorieID = categorieID;
		m_unread_count = unread_count;
		var rowhight = 30;
		m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);


		m_icon_collapsed = new Gtk.Image.from_icon_name("feed-sidebar-arrow-side", Gtk.IconSize.SMALL_TOOLBAR);
		m_icon_collapsed.opacity = m_opacity;

		m_icon_expanded = new Gtk.Image.from_icon_name("feed-sidebar-arrow-down", Gtk.IconSize.SMALL_TOOLBAR);
		m_icon_expanded.opacity = m_opacity;



		m_stack = new Gtk.Stack();
		m_stack.set_transition_type(Gtk.StackTransitionType.NONE);
		m_stack.set_transition_duration(0);
		m_stack.add_named(m_icon_expanded, "expanded");
		m_stack.add_named(m_icon_collapsed, "collapsed");

		m_expandBox = new Gtk.EventBox();
		m_expandBox.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		m_expandBox.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
		m_expandBox.set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
		m_expandBox.margin_start = (level-1) * 24;
		m_expandBox.add(m_stack);
		m_expandBox.button_press_event.connect(onExpandClick);
		m_expandBox.enter_notify_event.connect(onExpandEnter);
		m_expandBox.leave_notify_event.connect(onExpandLeave);

		m_label = new Gtk.Label(m_name);
		m_label.set_size_request (0, rowhight);
		m_label.set_ellipsize (Pango.EllipsizeMode.END);
		m_label.set_alignment(0, 0.5f);


		m_unread = new Gtk.Label("");
		m_unread.set_size_request (0, rowhight);
		m_unread.set_alignment(0.8f, 0.5f);
		m_unread.get_style_context().add_class("unread-count");

		m_unreadStack = new Gtk.Stack();
		m_unreadStack.set_transition_type(Gtk.StackTransitionType.NONE);
		m_unreadStack.set_transition_duration(0);
		m_unreadStack.add_named(m_unread, "unreadCount");
		m_unreadStack.add_named(new Gtk.Label(""), "nothing");
		m_unreadStack.add_named(new Gtk.Image.from_icon_name("feed-mark-read", Gtk.IconSize.LARGE_TOOLBAR), "mark");

		m_unreadBox = new Gtk.EventBox();
		m_unreadBox.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		m_unreadBox.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
		m_unreadBox.set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
		m_unreadBox.add(m_unreadStack);
		m_unreadBox.button_press_event.connect(onUnreadClick);
		m_unreadBox.enter_notify_event.connect(onUnreadEnter);
		m_unreadBox.leave_notify_event.connect(onUnreadLeave);

		m_box.pack_start(m_expandBox, false, false, 8);
		m_box.pack_start(m_label, true, true, 0);
		m_box.pack_end(m_unreadBox, false, false, 8);

		m_eventBox = new Gtk.EventBox();
		if(m_categorieID != CategoryID.MASTER && m_categorieID != CategoryID.TAGS)
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
		this.show_all();

		set_unread_count(m_unread_count);

		if(m_collapsed)
			m_stack.set_visible_child_name("collapsed");
		else
			m_stack.set_visible_child_name("expanded");
	}

	private bool onClick(Gdk.EventButton event)
	{
		// only right click allowed
		if(event.button != 3)
			return false;

		switch(event.type)
		{
			case Gdk.EventType.BUTTON_RELEASE:
			case Gdk.EventType.@2BUTTON_PRESS:
			case Gdk.EventType.@3BUTTON_PRESS:
				return false;
		}

		var remove_action = new GLib.SimpleAction("deleteCat", null);
		remove_action.activate.connect(() => {
			if(!m_collapsed)
				expand_collapse();

			if(this.is_selected())
				selectDefaultRow();

			uint time = 300;
			this.reveal(false, time);
			GLib.Timeout.add(time, () => {
			    feedDaemon_interface.removeCategory(m_categorieID);
				return false;
			});
		});
		var markAsRead_action = new GLib.SimpleAction("markCatAsRead", null);
		markAsRead_action.activate.connect(() => {
			setAsRead(FeedListType.CATEGORY, m_categorieID);
		});
		if(m_unread_count != 0)
		{
			markAsRead_action.set_enabled(true);
		}
		else
		{
			markAsRead_action.set_enabled(false);
		}
		var rename_action = new GLib.SimpleAction("renameCat", null);
		rename_action.activate.connect(() => {
			var popRename = new Gtk.Popover(this);
			popRename.set_position(Gtk.PositionType.BOTTOM);
			popRename.closed.connect(closePopoverStyle);

			var renameEntry = new Gtk.Entry();
			renameEntry.set_text(m_name);

			var renameButton = new Gtk.Button.with_label(_("rename"));
			renameButton.get_style_context().add_class("suggested-action");
			renameButton.clicked.connect(() => {
				popRename.hide();
				feedDaemon_interface.renameCategory(m_categorieID, renameEntry.get_text());
			});

			var renameBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
			renameBox.margin = 5;
			renameBox.pack_start(renameEntry, true, true, 0);
			renameBox.pack_start(renameButton, false, false, 0);

			popRename.add(renameBox);
			popRename.show_all();
			showPopoverStyle();
		});
		var app = (rssReaderApp)GLib.Application.get_default();
		app.add_action(markAsRead_action);
		app.add_action(rename_action);
		app.add_action(remove_action);

		var menu = new GLib.Menu();
		menu.append(_("Mark as read"), "markCatAsRead");
		menu.append(_("Rename"), "renameCat");
		menu.append(_("Delete"), "deleteCat");

		var pop = new Gtk.Popover(this);
		pop.set_position(Gtk.PositionType.BOTTOM);
		pop.bind_model(menu, "app");
		pop.closed.connect(closePopoverStyle);
		pop.show();
		showPopoverStyle();


		return true;
	}

	private void showPopoverStyle()
	{
		this.get_style_context().remove_class("feed-list-row");

		if(this.is_selected())
			this.get_style_context().add_class("feed-list-row-selected-popover");
		else
			this.get_style_context().add_class("feed-list-row-popover");
	}

	private void closePopoverStyle()
	{
		if(this.is_selected())
			this.get_style_context().remove_class("feed-list-row-selected-popover");
		else
			this.get_style_context().remove_class("feed-list-row-popover");

		this.get_style_context().add_class("feed-list-row");
	}

	private bool onUnreadClick(Gdk.EventButton event)
	{
		if(m_unreadHovered && m_unread_count > 0)
		{
			setAsRead(FeedListType.CATEGORY, m_categorieID);
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

	private bool onExpandClick(Gdk.EventButton event)
	{
		// only accept left mouse button
		if(event.button != 1)
			return false;

		switch(event.type)
		{
			case Gdk.EventType.BUTTON_RELEASE:
			case Gdk.EventType.@2BUTTON_PRESS:
			case Gdk.EventType.@3BUTTON_PRESS:
				return false;
		}
		expand_collapse();
		return true;
	}

	public bool expand_collapse()
	{
		if(m_collapsed)
		{
			m_collapsed = false;
			m_stack.set_visible_child_name("expanded");
		}
		else
		{
			m_collapsed = true;
			m_stack.set_visible_child_name("collapsed");
		}

		collapse(m_collapsed, m_categorieID);
		return true;
	}

	private bool onExpandEnter(Gdk.EventCrossing event)
	{
		m_hovered = true;
		m_icon_expanded.opacity = 1.0;
		m_icon_collapsed.opacity = 1.0;
		return true;
	}

	private bool onExpandLeave(Gdk.EventCrossing event)
	{
		if(event.detail != Gdk.NotifyType.VIRTUAL && event.mode != Gdk.CrossingMode.NORMAL)
			return false;

		m_hovered = false;

		m_icon_expanded.opacity = m_opacity;
		m_icon_collapsed.opacity = m_opacity;
		return true;
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

	public void upUnread()
	{
		set_unread_count(m_unread_count+1);
	}

	public void downUnread()
	{
		if(m_unread_count > 0)
			set_unread_count(m_unread_count-1);
	}

	public string getID()
	{
		return m_categorieID;
	}

	public string getName()
	{
		return m_name;
	}

	public string getParent()
	{
		return m_parentID;
	}

	public int getOrder()
	{
		return m_orderID;
	}

	public int getLevel()
	{
		return m_level;
	}

	public void setExist(bool exists)
	{
		m_exists = exists;
	}

	public bool doesExist()
	{
		return m_exists;
	}

	public bool isExpanded()
	{
		return !m_collapsed;
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
		if(settings_state.get_boolean("no-animations"))
		{
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
		}
	}

}
