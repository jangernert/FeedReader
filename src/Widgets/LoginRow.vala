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

	private LoginInterface m_ext;
	private Gtk.Button m_infoButton;

	public LoginRow(LoginInterface ext)
	{
		m_ext = ext;
		string iconName = (ext as LoginInterface).iconName();
		string serviceName = (ext as LoginInterface).serviceName();

		var icon = new Gtk.Image.from_icon_name(iconName, Gtk.IconSize.MENU);
		icon.margin_start = 10;
		var label = new Gtk.Label(serviceName);
		label.set_alignment(0.0f, 0.5f);
		label.get_style_context().add_class("h3");

		m_infoButton = new Gtk.Button.from_icon_name("fr-backend-info", Gtk.IconSize.LARGE_TOOLBAR);
		m_infoButton.set_relief(Gtk.ReliefStyle.NONE);
		m_infoButton.valign = Gtk.Align.CENTER;
		m_infoButton.no_show_all = true;

		var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 15);
		box.margin_top = 2;
		box.margin_bottom = 2;
		box.pack_start(icon, false, false, 10);
		box.pack_start(label, true, true, 0);
		box.pack_end(m_infoButton, false, false, 10);
		var box2 = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		box2.pack_start(box);
		box2.pack_start(new Gtk.Separator(Gtk.Orientation.HORIZONTAL));

		var eventbox = new Gtk.EventBox();
		eventbox.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
		eventbox.set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
		//eventbox.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		eventbox.enter_notify_event.connect(rowEnter);
		eventbox.leave_notify_event.connect(rowLeave);
		//eventbox.button_press_event.connect(rowClick);
		eventbox.add(box2);

		this.add(eventbox);
	}

	public string getServiceName()
	{
		return m_ext.serviceName();
	}

	public LoginInterface getExtension()
	{
		return m_ext;
	}

	private bool rowEnter(Gdk.EventCrossing event)
	{
		if(event.detail == Gdk.NotifyType.INFERIOR)
			return true;

		m_infoButton.show();
		return true;
	}

	private bool rowLeave(Gdk.EventCrossing event)
	{
		if(event.detail == Gdk.NotifyType.INFERIOR)
			return true;

		m_infoButton.hide();
		return true;
	}

}
