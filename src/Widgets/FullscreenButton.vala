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

public class FeedReader.fullscreenButton : Gtk.EventBox {

	private Gtk.Image m_icon;
	private double m_opacity = 0.4;
	private bool m_hover = false;
	private uint m_timeout_source_id = 0;
	public signal void click();

	public fullscreenButton(string iconName, Gtk.Align align)
	{
		this.valign = Gtk.Align.CENTER;
		this.halign = align;
		this.get_style_context().add_class("overlay");
		this.margin = 40;
		this.no_show_all = true;

		this.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
		this.set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
		this.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);

		this.enter_notify_event.connect(onEnter);
		this.leave_notify_event.connect(onLeave);
		this.button_press_event.connect(onClick);

		m_icon = new Gtk.Image.from_icon_name(iconName, Gtk.IconSize.DIALOG);
		m_icon.margin = 20;
		this.opacity = 0.0;
		this.add(m_icon);
	}

	private bool onEnter(Gdk.EventCrossing event)
    {
		this.opacity = 1.0;
		m_hover = true;
        return true;
    }

    private bool onLeave(Gdk.EventCrossing event)
    {
		this.opacity = m_opacity;
		m_hover = false;
        return true;
    }

	private bool onClick(Gdk.EventButton event)
    {
		switch(event.type)
		{
			case Gdk.EventType.BUTTON_RELEASE:
			case Gdk.EventType.@2BUTTON_PRESS:
			case Gdk.EventType.@3BUTTON_PRESS:
				return false;
		}

		click();
        return true;
    }

	public void reveal(bool show)
	{
		if (m_timeout_source_id > 0)
		{
            GLib.Source.remove(m_timeout_source_id);
            m_timeout_source_id = 0;
        }

		if(show)
		{
			this.visible = true;
			m_icon.show();
		}

		m_timeout_source_id = Timeout.add(20, () => {

			if(show)
			{
				if(!m_hover && this.opacity-m_opacity <= 0.02)
				{
					this.opacity = m_opacity;
					m_timeout_source_id = 0;
					return false;
				}

				if(m_hover && this.opacity == 1.0)
				{
					m_timeout_source_id = 0;
					return false;
				}

				this.opacity += 0.02;
			}
			else
			{
				if(this.opacity == 0.0)
				{
					this.hide();
					m_timeout_source_id = 0;
					return false;
				}

				this.opacity -= 0.02;
			}

            return true;
        });
	}

}
