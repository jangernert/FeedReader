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

public class FeedReader.InAppNotification : Gd.Notification {

	private Gtk.Box m_box;
	private Gtk.Button m_Button;
	public signal void action();

	public InAppNotification(string message, string buttonText, string ? tooltip = null, int timeout = 5)
	{
		m_Button = new Gtk.Button.with_label(buttonText);
		setup(message, tooltip);
	}

	public InAppNotification.withIcon(string message, string icon, string ? tooltip = null, int timeout = 5)
	{
		m_Button = new Gtk.Button.from_icon_name(icon, Gtk.IconSize.BUTTON);
		setup(message, tooltip);
	}

	public InAppNotification.withIcon_from_resource(string message, string icon, string ? tooltip = null, int timeout = 5)
	{
		m_Button = new Gtk.Button();
		m_Button.set_image(new Gtk.Image.from_resource(icon));
		setup(message, tooltip);
	}

	private void setup(string message, string ? tooltip)
	{
		m_Button.set_tooltip_text(tooltip);
		m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
		m_box.pack_start(new Gtk.Label(message));
		m_box.pack_start(m_Button);
		this.set_timeout(5);
		this.set_show_close_button(false);
		this.add(m_box);

		this.unrealize.connect(() => {
			Logger.debug("InAppNotification: destroy");
			dismissed();
		});

		m_Button.clicked.connect(() => {
			action();
		});
	}

}
