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

public class FeedReader.TagPopoverRow : Gtk.ListBoxRow {

    private Gtk.Revealer m_revealer;
    private Gtk.Box m_box;
    private tag m_tag;
    private Gtk.Image m_clear;
    private Gtk.EventBox m_eventbox;
    public signal void remove_tag(TagPopoverRow row);

    public TagPopoverRow(tag Tag)
    {
        m_tag = Tag;
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

        m_revealer = new Gtk.Revealer();
		m_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
        m_revealer.set_transition_duration(150);
		m_revealer.add(m_box);
		m_revealer.set_reveal_child(true);

        this.add(m_revealer);
        this.margin_top = 1;
        this.margin_bottom = 1;
        this.show_all();
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
        m_revealer.set_reveal_child(false);
        remove_tag(this);
        return false;
    }

    public string getTagID()
    {
        return m_tag.getTagID();
    }

    public tag getTag()
    {
        return m_tag;
    }
}
