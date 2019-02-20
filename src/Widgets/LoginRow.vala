//	This file is part of FeedReader.
//
//	FeedReader is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	FeedReader is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General public License for more details.
//
//	You should have received a copy of the GNU General public License
//	along with FeedReader.  If not, see <http://www.gnu.org/licenses/>.

public class FeedReader.LoginRow : Gtk.ListBoxRow {
	
	private BackendInfo m_info;
	private Gtk.Stack m_infoStack;
	private bool m_hovered = false;
	
	public LoginRow(BackendInfo info)
	{
		m_info = info;
		
		var icon = new Gtk.Image.from_icon_name(info.iconName, Gtk.IconSize.MENU);
		icon.margin_start = 10;
		var label = new Gtk.Label(info.name);
		label.set_alignment(0.0f, 0.5f);
		label.get_style_context().add_class("h3");
		
		var infoIcon = new Gtk.Image.from_icon_name("feed-backend-info", Gtk.IconSize.LARGE_TOOLBAR);
		var infoButton = new Gtk.Button();
		infoButton.set_image(infoIcon);
		infoButton.set_relief(Gtk.ReliefStyle.NONE);
		infoButton.set_focus_on_click(false);
		infoButton.valign = Gtk.Align.CENTER;
		infoButton.clicked.connect(infoClicked);
		
		m_infoStack = new Gtk.Stack();
		m_infoStack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		m_infoStack.set_transition_duration(50);
		m_infoStack.valign = Gtk.Align.CENTER;
		m_infoStack.add_named(new Gtk.Label(""), "empty");
		m_infoStack.add_named(infoButton, "button");
		m_infoStack.set_visible_child_name("empty");
		
		var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 15);
		box.margin_top = 2;
		box.margin_bottom = 2;
		box.pack_start(icon, false, false, 10);
		box.pack_start(label, true, true, 0);
		box.pack_end(m_infoStack, false, false, 10);
		var box2 = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		box2.pack_start(box);
		box2.pack_start(new Gtk.Separator(Gtk.Orientation.HORIZONTAL));
		
		var eventbox = new Gtk.EventBox();
		eventbox.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
		eventbox.set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
		eventbox.enter_notify_event.connect(rowEnter);
		eventbox.leave_notify_event.connect(rowLeave);
		eventbox.add(box2);
		
		this.add(eventbox);
	}
	
	public BackendInfo getInfo()
	{
		return m_info;
	}
	
	private bool rowEnter(Gdk.EventCrossing event)
	{
		if(event.detail == Gdk.NotifyType.INFERIOR)
		{
			return true;
		}
		
		m_hovered = true;
		m_infoStack.set_visible_child_name("button");
		return true;
	}
	
	private bool rowLeave(Gdk.EventCrossing event)
	{
		if(event.detail == Gdk.NotifyType.INFERIOR
		|| event.detail == Gdk.NotifyType.VIRTUAL)
		{
			if(event.detail == Gdk.NotifyType.VIRTUAL)
			{
				m_hovered = false;
			}
			return true;
		}
		
		
		m_hovered = false;
		m_infoStack.set_visible_child_name("empty");
		return true;
	}
	
	private void infoClicked()
	{
		var pop = new BackendInfoPopover(m_infoStack, m_info);
		pop.show_all();
		pop.closed.connect_after(() => {
			GLib.Timeout.add(50, () => {
				if(!m_hovered)
				{
					m_infoStack.set_visible_child_name("empty");
				}
				return false;
			});
		});
	}
}
