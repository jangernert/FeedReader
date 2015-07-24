public class FeedReader.TagPopoverRow : Gtk.ListBoxRow {

    private Gtk.Box m_box;
    private string m_tagID;
    private Gtk.Image m_clear;
    private Gtk.EventBox m_eventbox;

    public TagPopoverRow(tag Tag)
    {
        m_tagID = Tag.getTagID();
        m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var circle = new ColorCircle(Tag.getColor(), false);
        circle.margin_start = 2;
        var label = new Gtk.Label(Tag.getTitle());
        label.set_alignment(0, 0.5f);
        m_clear = new Gtk.Image.from_icon_name("edit-clear-symbolic", Gtk.IconSize.MENU);
        m_clear.margin_end = 5;
        m_clear.opacity = 0.7;

        m_eventbox = new Gtk.EventBox();
		m_eventbox.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
		m_eventbox.set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
        m_eventbox.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
		m_eventbox.enter_notify_event.connect(onEnter);
		m_eventbox.leave_notify_event.connect(onLeave);
        m_eventbox.button_press_event.connect(onClick);
		m_eventbox.add(m_clear);

        m_box.pack_start(circle, false, false, 0);
        m_box.pack_start(label, true, true, 0);
        m_box.pack_end(m_eventbox, false, false, 0);

        this.add(m_box);
        this.margin_top = 1;
        this.margin_bottom = 1;
    }

    private bool onEnter()
    {
        m_clear.opacity = 1.0;
        return false;
    }

    private bool onLeave()
    {
        m_clear.opacity = 0.7;
        return false;
    }

    private bool onClick()
    {
        return true;
    }
}
