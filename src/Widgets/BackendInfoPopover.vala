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

public class FeedReader.BackendInfoPopover : Gtk.Popover {

	private BackendInfo m_info;

	public BackendInfoPopover(Gtk.Widget widget, BackendInfo info)
	{
		m_info = info;

		int space = 25;

		var typeLabel = new Gtk.Label("Type:");
		typeLabel.hexpand = true;
		typeLabel.get_style_context().add_class("h3");
		typeLabel.set_alignment(0.0f, 0.5f);


		var licenseLabel = new Gtk.Label("License:");
		licenseLabel.hexpand = true;
		licenseLabel.get_style_context().add_class("h3");
		licenseLabel.set_alignment(0.0f, 0.5f);


		var priceLabel = new Gtk.Label("Price:");
		priceLabel.hexpand = true;
		priceLabel.get_style_context().add_class("h3");
		priceLabel.set_alignment(0.0f, 0.5f);


		var grid = new Gtk.Grid();
		grid.set_column_spacing(20);
		grid.set_row_spacing(5);
		grid.margin = 10;
		grid.attach(typeLabel, 0, 0, 1, 1);
		grid.attach(licenseLabel, 0, 1, 1, 1);
		grid.attach(priceLabel, 0, 2, 1, 1);



		if(BackendFlags.LOCAL in m_info.flags)
		{
			var icon = getIcon("feed-local-symbolic", "Local Files only");
			grid.attach(icon, 1, 0, 1, 1);
		}
		else
		{
			if(BackendFlags.HOSTED in m_info.flags)
			{
				var icon = getIcon("feed-cloud-symbolic", "Synced with Service");
				grid.attach(icon, 1, 0, 1, 1);
			}
			else if(BackendFlags.SELF_HOSTED in m_info.flags)
			{
				var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
				box.pack_start(getIcon("feed-cloud-symbolic", "Synced with Service"), true, false, 0);
				box.pack_start(getIcon("feed-server-symbolic", "Self-hosted Service"), true, false, 0);
				grid.attach(box, 1, 0, 1, 1);
				space = 50;
			}
		}


		if(BackendFlags.FREE_SOFTWARE in m_info.flags)
		{
			var icon = getIcon("feed-gpl-symbolic", "Free Software");
			grid.attach(icon, 1, 1, 1, 1);
		}
		else if(BackendFlags.PROPRIETARY in m_info.flags)
		{
			var icon = getIcon("feed-copyright-symbolic", "Proprietary Software");
			grid.attach(icon, 1, 1, 1, 1);
		}

		if(BackendFlags.FREE in m_info.flags)
		{
			var icon = getIcon("feed-free-symbolic", "Free Service");
			grid.attach(icon, 1, 2, 1, 1);
		}
		else if(BackendFlags.PAID in m_info.flags)
		{
			var icon = getIcon("feed-nonfree-symbolic", "Paid Service");
			grid.attach(icon, 1, 2, 1, 1);
		}
		else if(BackendFlags.PAID_PREMIUM in m_info.flags)
		{
			var icon = getIcon("feed-nonfree-symbolic", "Free basic usage with paid Premium");
			grid.attach(icon, 1, 2, 1, 1);
		}


		var nameLabel = new Gtk.Label(m_info.name);
		nameLabel.get_style_context().add_class("h2");
		nameLabel.set_alignment(0.0f, 0.5f);

		var eventbox = new Gtk.EventBox();
		eventbox.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);

		eventbox.button_press_event.connect(websiteClicked);
		eventbox.add(getIcon("feed-website-symbolic", m_info.website));
		var nameBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, space);
		nameBox.pack_start(nameLabel, true, false, 0);
		nameBox.pack_end(eventbox, false, false, 0);
		nameBox.margin = 10;
		nameBox.margin_bottom = 5;

		var separator = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);

		var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		box.pack_start(nameBox, false, false, 0);
		box.pack_start(separator, false, false, 0);
		box.pack_start(grid, true, true, 0);


		this.add(box);
		this.set_relative_to(widget);
		this.set_position(Gtk.PositionType.BOTTOM);
		this.show_all();

		var cursor = new Gdk.Cursor.for_display(Gdk.Display.get_default(), Gdk.CursorType.HAND1);
		eventbox.get_window().set_cursor(cursor);
	}

	private bool websiteClicked(Gdk.EventButton event)
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

		try
		{
			Gtk.show_uri_on_window(MainWindow.get_default(), m_info.website, Gdk.CURRENT_TIME);
		}
		catch(GLib.Error e)
		{
			Logger.debug("could not open the link in an external browser: %s".printf(e.message));
		}
		return true;
	}

	private Gtk.Image getIcon(string name, string tooltip)
	{
		var icon = new Gtk.Image.from_icon_name(name, Gtk.IconSize.MENU);
		icon.halign = Gtk.Align.END;
		icon.set_tooltip_text(tooltip);
		return icon;
	}


}
