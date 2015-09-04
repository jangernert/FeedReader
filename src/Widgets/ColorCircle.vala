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

public class FeedReader.ColorCircle : Gtk.EventBox {

	private Gtk.Image m_icon;
	private Gtk.Image m_icon_light;
	private int m_color;
	public signal void clicked(int color);

	public ColorCircle(int color, bool clickable = true)
	{
		m_color = color;

		try{
			m_icon = new Gtk.Image.from_pixbuf(drawIcon());
			m_icon_light = new Gtk.Image.from_pixbuf(drawIcon(true));
		}
		catch(GLib.Error e)
		{
			logger.print(LogMessage.DEBUG, e.message);
		}

		this.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		this.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
		this.set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
		this.set_size_request(16, 16);

		if(clickable)
		{
			this.enter_notify_event.connect(() => {IconEnter(); return true;});
			this.leave_notify_event.connect(() => {IconLeave(); return true;});
			this.button_press_event.connect(() => {IconClicked(); return true;});
		}

		this.add(m_icon);
		this.show_all();
	}

	public void newColor(int color)
	{
		m_color = color;

		try{
			m_icon.set_from_pixbuf(drawIcon());
			m_icon_light.set_from_pixbuf(drawIcon(true));
		}
		catch(GLib.Error e)
		{
			logger.print(LogMessage.DEBUG, e.message);
		}
	}


	private void IconEnter()
	{
		this.remove(m_icon);
		this.add(m_icon_light);
		this.show_all();
	}

	private void IconLeave()
	{
		this.remove(m_icon_light);
		this.add(m_icon);
		this.show_all();
	}

	private void IconClicked()
	{
		logger.print(LogMessage.DEBUG, "ColorCircle: click");
		clicked(m_color);
	}


	private Gdk.Pixbuf drawIcon(bool light = false)
	{
		int size = 16;
		var color = Gdk.RGBA();
		color.parse(COLORS[m_color]);
		double lighten = 1.0;
		if(light)
			lighten = 0.7;

		var surface = this.get_window().create_similar_image_surface(0, size, size, 0);
		//var surface = this.get_window().create_similar_surface(Cairo.Content.COLOR_ALPHA, size, size);
		//Cairo.ImageSurface surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, size, size);
		Cairo.Context context = new Cairo.Context(surface);

		context.set_line_width(2);
		context.set_fill_rule(Cairo.FillRule.EVEN_ODD);

		context.set_source_rgba(color.red, color.green, color.blue, 0.6*lighten);
		context.arc(size/2, size/2, (size/2), 0, 2*Math.PI);
		context.fill_preserve();

		context.arc(size/2, size/2, (size/2)-(size/8), 0, 2*Math.PI);
		context.set_source_rgba(color.red, color.green, color.blue, 0.6*lighten);
		context.fill_preserve();

		return Gdk.pixbuf_get_from_surface(surface, 0, 0, size, size);
	}
}
