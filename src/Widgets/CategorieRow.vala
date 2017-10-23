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

public class FeedReader.CategoryRow : Gtk.ListBoxRow {

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
	private Gtk.Image m_icon_expanded;
	private Gtk.Image m_icon_collapsed;
	private Gtk.Stack m_stack;
	private double m_opacity = 0.8;
	private bool m_collapsed;
	private bool m_exists = true;
	private bool m_hovered = false;
	private bool m_unreadHovered = false;
	private Gtk.Stack m_unreadStack;
	public signal void collapse(bool collapse, string catID, bool selectParent);
	public signal void setAsRead(FeedListType type, string id);
	public signal void moveUP();
	public signal void deselectRow();
	public signal void removeRow();

	public CategoryRow(string name, string categorieID, int orderID, uint unread_count, string parentID, int level, bool expanded)
	{
		this.get_style_context().add_class("fr-sidebar-row");
		m_level = level;
		m_parentID = parentID;
		m_orderID = orderID;
		m_collapsed = !expanded;
		m_name = name;
		m_categorieID = categorieID;
		m_unread_count = unread_count;
		var rowhight = 30;
		m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);


		m_icon_collapsed = new Gtk.Image.from_icon_name("feed-sidebar-arrow-side-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		m_icon_collapsed.get_style_context().add_class("fr-sidebar-symbolic");
		m_icon_collapsed.opacity = m_opacity;

		m_icon_expanded = new Gtk.Image.from_icon_name("feed-sidebar-arrow-down-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		m_icon_expanded.get_style_context().add_class("fr-sidebar-symbolic");
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
		m_expandBox.set_size_request(32, 0);
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

		m_box.pack_start(m_expandBox, false, false, 0);
		m_box.pack_start(m_label, true, true, 0);
		m_box.pack_end(m_unreadBox, false, false, 8);

		m_eventBox = new Gtk.EventBox();
		if(m_categorieID != CategoryID.MASTER.to_string()
		&& m_categorieID != CategoryID.TAGS.to_string())
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

		if(Utils.canManipulateContent())
		{
			if(m_categorieID != CategoryID.MASTER.to_string()
			&& m_categorieID != CategoryID.TAGS.to_string())
			{
				const Gtk.TargetEntry[] accepted_targets = {
					{ "text/plain",	0, DragTarget.FEED },
					{ "STRING",		0, DragTarget.CAT }
				};

				Gtk.drag_dest_set (
						this,
						Gtk.DestDefaults.MOTION,
						accepted_targets,
						Gdk.DragAction.MOVE
				);

				this.drag_motion.connect(onDragMotion);
				this.drag_leave.connect(onDragLeave);
				this.drag_drop.connect(onDragDrop);
				this.drag_data_received.connect(onDragDataReceived);

				if(FeedReaderBackend.get_default().supportMultiLevelCategories())
				{
					const Gtk.TargetEntry[] provided_targets = {
						{ "STRING",     0, DragTarget.CAT }
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
			else if(m_categorieID == CategoryID.MASTER.to_string())
			{
				const Gtk.TargetEntry[] accepted_targets = {
					{ "STRING",     0, DragTarget.CAT }
				};

				Gtk.drag_dest_set (
						this,
						Gtk.DestDefaults.MOTION,
						accepted_targets,
						Gdk.DragAction.MOVE
				);

				this.drag_motion.connect(onDragMotion);
				this.drag_leave.connect(onDragLeave);
				this.drag_drop.connect(onDragDrop);
				this.drag_data_received.connect(onDragDataReceived);
			}
		}
	}

	~CategoryRow()
	{
		activateUnreadEventbox(false);

		m_expandBox.button_press_event.disconnect(onExpandClick);
		m_expandBox.enter_notify_event.disconnect(onExpandEnter);
		m_expandBox.leave_notify_event.disconnect(onExpandLeave);

		m_eventBox.button_press_event.disconnect(onClick);

		this.drag_begin.disconnect(onDragBegin);
		this.drag_data_get.disconnect(onDragDataGet);

		this.drag_motion.disconnect(onDragMotion);
		this.drag_leave.disconnect(onDragLeave);
		this.drag_drop.disconnect(onDragDrop);
		this.drag_data_received.disconnect(onDragDataReceived);

		this.drag_motion.disconnect(onDragMotion);
		this.drag_leave.disconnect(onDragLeave);
		this.drag_drop.disconnect(onDragDrop);
		this.drag_data_received.disconnect(onDragDataReceived);
	}

//------------- Drag Source Functions ----------------------------------------------

	private void onDragBegin(Gtk.Widget widget, Gdk.DragContext context)
	{
		Logger.debug("categoryRow: onDragBegin");
		Gtk.drag_set_icon_widget(context, getDragWindow(), 0, 0);

	}

	public void onDragDataGet(Gtk.Widget widget, Gdk.DragContext context, Gtk.SelectionData selection_data, uint target_type, uint time)
	{
		Logger.debug("categoryRow: onDragDataGet");

		if(target_type == DragTarget.CAT)
		{
			selection_data.set_text(m_categorieID, -1);
		}
	}


//------------- Drag Target Functions ----------------------------------------------

	private bool onDragMotion(Gtk.Widget widget, Gdk.DragContext context, int x, int y, uint time)
	{
		this.set_state_flags(Gtk.StateFlags.PRELIGHT, false);
		return true;
	}

	private void onDragLeave(Gtk.Widget widget, Gdk.DragContext context, uint time)
	{
		this.unset_state_flags(Gtk.StateFlags.PRELIGHT);
	}


	private bool onDragDrop(Gtk.Widget widget, Gdk.DragContext context, int x, int y, uint time)
	{
		Logger.debug("categoryRow: onDragDrop");

		// If the source offers a target
		if(context.list_targets() != null)
		{
			var target_type = (Gdk.Atom)context.list_targets().nth_data(0);

			// Request the data from the source.
			Gtk.drag_get_data(widget, context, target_type, time);
			return true;
		}

		return false;
	}

	private void onDragDataReceived(Gtk.Widget widget, Gdk.DragContext context, int x, int y,
									Gtk.SelectionData selection_data, uint target_type, uint time)
	{
		Logger.debug("categoryRow: onDragDataReceived");

		var dataString = selection_data.get_text();

		if(dataString != null
		&& selection_data.get_length() >= 0)
		{
			if(m_categorieID == CategoryID.NEW.to_string())
			{
				if(target_type == DragTarget.FEED)
				{
					string[] data = dataString.split(",");
					string feedID = data[0];
					string currentCat = data[1];

					showRenamePopover(context, time, feedID, currentCat);
				}
				else if(target_type == DragTarget.CAT)
				{
					showRenamePopover(context, time, dataString);
				}
			}
			else
			{
				if(target_type == DragTarget.FEED)
				{
					string[] data = dataString.split(",");
					string feedID = data[0];
					string currentCat = data[1];
					Logger.debug("drag feedID: " + feedID + " currentCat: " + currentCat);

					if(currentCat == m_categorieID)
					{
						Logger.debug("categoryRow: drag current parent -> drag_failed");
						this.drag_failed(context, Gtk.DragResult.NO_TARGET);
						return;
					}
					else
					{
						FeedReaderBackend.get_default().moveFeed(feedID, currentCat, m_categorieID);
					}

					Gtk.drag_finish(context, true, false, time);
				}
				else if(target_type == DragTarget.CAT)
				{
					Logger.debug("drag catID: " + dataString);

					if(dataString == m_categorieID)
					{
						Logger.debug("categoryRow: drag on self -> drag_failed");
						this.drag_failed(context, Gtk.DragResult.NO_TARGET);
						return;
					}
					else
					{
						FeedReaderBackend.get_default().moveCategory(dataString, m_categorieID);
					}

					Gtk.drag_finish(context, true, false, time);
				}
			}
		}

	}

	private Gtk.Window getDragWindow()
	{
		var window = new Gtk.Window(Gtk.WindowType.POPUP);
		var visual = window.get_screen().get_rgba_visual();
		window.set_visual(visual);
		window.get_style_context().add_class("fr-sidebar");
		window.get_style_context().add_class("fr-sidebar-row-popover");
		var row = new CategoryRow(m_name, m_categorieID, m_orderID, m_unread_count, m_parentID, m_level, !m_collapsed);
		row.set_size_request(this.get_allocated_width(), 0);
		row.reveal(true);
		window.add(row);
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

		var remove_action = new GLib.SimpleAction("deleteCat", null);
		remove_action.activate.connect(() => {
			bool wasExpanded = false;

			if(!m_collapsed)
			{
				wasExpanded = true;
				expand_collapse();
			}

			if(this.is_selected())
				moveUP();

			uint time = 300;
			this.reveal(false, time);

			string text = _("Category \"%s\" removed").printf(m_name);
			var notification = MainWindow.get_default().showNotification(text);
			ulong eventID = notification.dismissed.connect(() => {
				FeedReaderBackend.get_default().removeCategory(m_categorieID);
			});
			notification.action.connect(() => {
				notification.disconnect(eventID);
				this.reveal(true, time);
				if(wasExpanded)
					expand_collapse();
				notification.dismiss();
			});
		});
		var removeWithChildren_action = new GLib.SimpleAction("deleteAllCat", null);
		removeWithChildren_action.activate.connect(() => {
			if(!m_collapsed)
				expand_collapse();

			if(this.is_selected())
				moveUP();

			uint time = 300;
			this.reveal(false, time);
			GLib.Timeout.add(time, () => {
				FeedReaderBackend.get_default().removeCategoryWithChildren(m_categorieID);
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
			showRenamePopover();
		});

		var app = FeedReaderApp.get_default();
		app.add_action(markAsRead_action);
		app.add_action(rename_action);
		app.add_action(remove_action);
		app.add_action(removeWithChildren_action);

		var menu = new GLib.Menu();
		menu.append(_("Mark as read"), "markCatAsRead");
		menu.append(_("Rename"), "renameCat");
		menu.append(_("Remove"), "deleteCat");
		menu.append(_("Remove (with Feeds)"), "deleteAllCat");

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

	private void showRenamePopover(Gdk.DragContext? context = null, uint time = 0, string? id1 = null, string? id2 = null)
	{
		var popRename = new Gtk.Popover(this);
		popRename.set_position(Gtk.PositionType.BOTTOM);
		popRename.closed.connect(() => {
			this.unset_state_flags(Gtk.StateFlags.PRELIGHT);
			if(m_categorieID == CategoryID.NEW.to_string() && context != null)
			{
				this.drag_failed(context, Gtk.DragResult.NO_TARGET);
			}
		});

		var renameEntry = new Gtk.Entry();
		renameEntry.set_text(m_name);
		renameEntry.activate.connect(() => {
			if(m_categorieID != CategoryID.NEW.to_string())
			{
				FeedReaderBackend.get_default().renameCategory(m_categorieID, renameEntry.get_text());
			}
			else if(context != null)
			{
				Logger.debug("categoryRow: create new Category " + renameEntry.get_text());
				m_categorieID = FeedReaderBackend.get_default().addCategory(renameEntry.get_text(), "", true);

				if(id2 == null) // move feed
				{
					FeedReaderBackend.get_default().moveCategory(id1, m_categorieID);
				}
				else // move category
				{
					FeedReaderBackend.get_default().moveFeed(id1, id2, m_categorieID);
				}

				Gtk.drag_finish(context, true, false, time);
			}

			popRename.hide();
		});

		string label = _("rename");
		if(m_categorieID == CategoryID.NEW.to_string() && context != null)
			label = _("add");

		var renameButton = new Gtk.Button.with_label(label);
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

	public bool expand_collapse(bool selectParent = true)
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

		collapse(m_collapsed, m_categorieID, selectParent);
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
		if(event.detail != Gdk.NotifyType.VIRTUAL
		&& event.mode != Gdk.CrossingMode.NORMAL)
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
		if(!reveal && this.is_selected())
			deselectRow();

		m_revealer.set_transition_duration(duration);
		m_revealer.set_reveal_child(reveal);
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

}
