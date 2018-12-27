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
	m_icon = new Gtk.Image.from_surface(drawIcon());
	m_icon_light = new Gtk.Image.from_surface(drawIcon(true));

	this.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
	this.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
	this.set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
	this.set_size_request(16, 16);

	if(clickable)
	{
		this.enter_notify_event.connect(IconEnter);
		this.leave_notify_event.connect(IconLeave);
		this.button_press_event.connect(IconClicked);
	}

	this.add(m_icon);
	this.show_all();
}

public void newColor(int color)
{
	m_color = color;
	m_icon.set_from_surface(drawIcon());
	m_icon_light.set_from_surface(drawIcon(true));
}


private bool IconEnter()
{
	this.remove(m_icon);
	this.add(m_icon_light);
	this.show_all();
	return true;
}

private bool IconLeave()
{
	this.remove(m_icon_light);
	this.add(m_icon);
	this.show_all();
	return true;
}

private bool IconClicked(Gdk.EventButton event)
{
	if(event.button != 1)
		return false;

	switch(event.type)
	{
	case Gdk.EventType.BUTTON_RELEASE:
	case Gdk.EventType.@2BUTTON_PRESS:
	case Gdk.EventType.@3BUTTON_PRESS:
		return false;
	}

	Logger.debug("ColorCircle: click");
	clicked(m_color);
	return true;
}


private Cairo.Surface drawIcon(bool light = false)
{
	int scaleFactor = this.get_scale_factor();
	int size = 16 * scaleFactor;
	var color = Gdk.RGBA();
	color.parse(Constants.COLORS[m_color]);
	double lighten = 1.0;
	if(light)
		lighten = 0.7;

	var surface = this.get_window().create_similar_image_surface(0, size, size, 0);
	Cairo.Context context = new Cairo.Context(surface);

	context.set_line_width(2);
	context.set_fill_rule(Cairo.FillRule.EVEN_ODD);

	double half = size/(2*scaleFactor);
	context.set_source_rgba(color.red, color.green, color.blue, 0.6*lighten);
	context.arc(half, half, half, 0, 2*Math.PI);
	context.fill_preserve();

	context.arc(half, half, half-(half/4), 0, 2*Math.PI);
	context.set_source_rgba(color.red, color.green, color.blue, 0.6*lighten);
	context.fill_preserve();

	return surface;
}
}
