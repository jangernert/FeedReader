public class FeedReader.HoverButton : Gtk.EventBox {

    private Gtk.Button m_button;
    private Gtk.Image m_inactive;
    private Gtk.Image m_active;
    private bool m_isActive;
    private bool m_just_clicked;
    public signal void clicked(bool active);

	public HoverButton(Gtk.Image inactive, Gtk.Image active, bool isActive)
    {
        m_inactive = inactive;
        m_active = active;
        m_isActive = isActive;
        m_button = new Gtk.Button();
		m_button.set_relief(Gtk.ReliefStyle.NONE);
		m_button.set_focus_on_click(false);
        m_button.clicked.connect(() => {
            m_just_clicked = true;
            toggle();
            clicked(m_isActive);
        });

        if(isActive)
            m_button.add(m_active);
        else
            m_button.add(m_inactive);



		this.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
		this.set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
		this.set_size_request(16, 16);
		this.add(m_button);

        this.enter_notify_event.connect(onEnter);
		this.leave_notify_event.connect(onLeave);
    }

    private void setActiveIcon()
    {
        m_button.remove(m_inactive);
        m_button.add(m_active);
        m_active.show();
    }

    private void setInactiveIcon()
    {
        m_button.remove(m_active);
        m_button.add(m_inactive);
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


    private bool onEnter()
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

    private bool onLeave()
    {
        if(m_just_clicked)
        {
            m_just_clicked = false;
        }
        else
        {
            if(m_isActive)
            {
                setActiveIcon();
            }
            else
            {
                setInactiveIcon();
            }
        }

        return true;
    }


}
