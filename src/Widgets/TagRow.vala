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

public class FeedReader.TagRow : Gtk.ListBoxRow {

	private Gtk.Box m_box;
	private Gtk.Label m_label;
	private bool m_exits;
	private string m_catID;
	private int m_color;
	private ColorCircle m_circle;
	private ColorPopover m_pop;
	private Gtk.Revealer m_revealer;
	private Gtk.Label m_unread;
	private uint m_unread_count;
	private Gtk.EventBox m_eventBox;
	public string m_name { get; private set; }
	public string m_tagID { get; private set; }
	public signal void selectDefaultRow();


	public TagRow (string name, string tagID, int color)
	{
		this.get_style_context().add_class("feed-list-row");
		m_exits = true;
		m_color = color;
		m_name = name.replace("&","&amp;");
		m_tagID = tagID;
		m_catID = CategoryID.TAGS;

		var rowhight = 30;
		m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

		m_circle = new ColorCircle(m_color);
		m_circle.margin_start = 24;
		m_pop = new ColorPopover(m_circle);

		m_circle.clicked.connect((color) => {
			m_pop.show_all();
		});

		m_pop.newColorSelected.connect((color) => {
			m_circle.newColor(color);
			feedDaemon_interface.updateTagColor(m_tagID, color);
		});

		m_label = new Gtk.Label(m_name);
		m_label.set_use_markup (true);
		m_label.set_size_request (0, rowhight);
		m_label.set_ellipsize (Pango.EllipsizeMode.END);
		m_label.set_alignment(0, 0.5f);

		m_box.pack_start(m_circle, false, false, 8);
		m_box.pack_start(m_label, true, true, 0);

		m_revealer = new Gtk.Revealer();
		m_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
		m_revealer.add(m_box);
		m_revealer.set_reveal_child(false);

		m_eventBox = new Gtk.EventBox();
		m_eventBox.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		m_eventBox.button_press_event.connect(onClick);
		m_eventBox.add(m_revealer);

		this.add(m_eventBox);
		this.show_all();
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

		var remove_action = new GLib.SimpleAction("deleteTag", null);
		remove_action.activate.connect(() => {
			if(this.is_selected())
				selectDefaultRow();

			uint time = 300;
			this.reveal(false, time);
			GLib.Timeout.add(time, () => {
			    feedDaemon_interface.deleteTag(m_tagID);
				return false;
			});
		});
		var rename_action = new GLib.SimpleAction("renameTag", null);
		rename_action.activate.connect(showRenamePopover);
		var app = (rssReaderApp)GLib.Application.get_default();
		app.add_action(rename_action);
		app.add_action(remove_action);

		var menu = new GLib.Menu();
		menu.append(_("Rename"), "renameTag");
		menu.append(_("Remove"), "deleteTag");

		var pop = new Gtk.Popover(this);
		pop.set_position(Gtk.PositionType.BOTTOM);
		pop.bind_model(menu, "app");
		pop.closed.connect(closePopoverStyle);
		pop.show();
		showPopoverStyle();

		return true;
	}

	private void closePopoverStyle()
	{
		if(this.is_selected())
			this.get_style_context().remove_class("feed-list-row-selected-popover");
		else
			this.get_style_context().remove_class("feed-list-row-popover");
	}

	private void showPopoverStyle()
	{
		if(this.is_selected())
			this.get_style_context().add_class("feed-list-row-selected-popover");
		else
			this.get_style_context().add_class("feed-list-row-popover");
	}

	public void update(string name)
	{
		m_label.set_text(name.replace("&","&amp;"));
		m_label.set_use_markup (true);
	}

	public string getID()
	{
		return m_tagID;
	}

	public void setExits(bool subscribed)
	{
		m_exits = subscribed;
	}

	public bool stillExits()
	{
		return m_exits;
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

	private void showRenamePopover()
	{
		var popRename = new Gtk.Popover(this);
		popRename.set_position(Gtk.PositionType.BOTTOM);
		popRename.closed.connect(closePopoverStyle);

		var renameEntry = new Gtk.Entry();
		renameEntry.set_text(m_name);
		renameEntry.activate.connect(() => {
			popRename.hide();
			feedDaemon_interface.renameTag(m_tagID, renameEntry.get_text());
		});

		var renameButton = new Gtk.Button.with_label(_("rename"));
		renameButton.get_style_context().add_class("suggested-action");
		renameButton.clicked.connect(() => {
			popRename.hide();
			feedDaemon_interface.renameTag(m_tagID, renameEntry.get_text());
		});

		var renameBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
		renameBox.margin = 5;
		renameBox.pack_start(renameEntry, true, true, 0);
		renameBox.pack_start(renameButton, false, false, 0);

		popRename.add(renameBox);
		popRename.show_all();
		showPopoverStyle();
	}

}
