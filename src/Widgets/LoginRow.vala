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

	public LoginRow(LoginInterface ext)
	{
		m_ext = ext;
		string iconName = (ext as LoginInterface).iconName();
		string serviceName = (ext as LoginInterface).serviceName();

		var icon = new Gtk.Image.from_icon_name(iconName, Gtk.IconSize.MENU);
		var label = new Gtk.Label(serviceName);
		label.set_alignment(0.0f, 0.5f);
		label.get_style_context().add_class("h3");

		var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 15);
		box.margin_top = 2;
		box.margin_bottom = 2;
		box.pack_start(icon, false, false, 10);
		box.pack_start(label);
		var box2 = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		box2.pack_start(box);
		box2.pack_start(new Gtk.Separator(Gtk.Orientation.HORIZONTAL));
		this.add(box2);
	}

	public string getServiceName()
	{
		return m_ext.serviceName();
	}

	public LoginInterface getExtension()
	{
		return m_ext;
	}

}
