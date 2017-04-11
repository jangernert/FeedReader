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

public class FeedReader.HoverButton : Gtk.EventBox {

    private Gtk.Button m_button;
    private Gtk.Stack m_stack;
    private Gtk.Image m_inactive;
    private Gtk.Image m_active;
    private bool m_isActive;
    public signal void clicked(bool active);

	public HoverButton(Gtk.Image inactive, Gtk.Image active, bool isActive)
    {
        m_inactive = inactive;
        m_active = active;
        m_isActive = isActive;
        m_stack = new Gtk.Stack();
        m_button = new Gtk.Button();
		m_button.set_relief(Gtk.ReliefStyle.NONE);
		m_button.set_focus_on_click(false);
        m_button.clicked.connect(() => {
            toggle();
            clicked(m_isActive);
        });

        m_stack.add_named(inactive, "inactive");
        m_stack.add_named(active, "active");
        m_button.add(m_stack);

        if(isActive)
            m_stack.set_visible_child_name("active");
        else
            m_stack.set_visible_child_name("inactive");



		this.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
		this.set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
		this.set_size_request(16, 16);
		this.add(m_button);

        this.enter_notify_event.connect(onEnter);
		this.leave_notify_event.connect(onLeave);
    }

    private void setActiveIcon()
    {
        m_stack.set_visible_child_name("active");
        m_active.show();
    }

    private void setInactiveIcon()
    {
        m_stack.set_visible_child_name("inactive");
        m_inactive.show();
    }

    public void toggle()
    {
        setActive(!m_isActive);
    }

    public void setActive(bool active)
    {
        m_isActive = active;

        if(m_isActive)
        {
            setActiveIcon();
        }
        else
        {
            setInactiveIcon();
        }
    }


    private bool onEnter(Gdk.EventCrossing event)
    {
        if(m_isActive)
        {
            setInactiveIcon();
        }
        else
        {
            setActiveIcon();
        }
        return true;
    }

    private bool onLeave(Gdk.EventCrossing event)
    {
        if(event.detail == Gdk.NotifyType.INFERIOR)
            return false;

        if(m_isActive)
        {
            setActiveIcon();
        }
        else
        {
            setInactiveIcon();
        }

        return true;
    }

    public void set_tooltip_text(string tooltip_text)
    {
        m_button.set_tooltip_text(tooltip_text);
    }


}
