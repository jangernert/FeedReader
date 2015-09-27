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

public class FeedReader.ArticleListOverlay : Gtk.Revealer {

	private Gtk.Label m_label;
	private Gtk.Button m_button;
	private Gtk.Box m_box;
	private Gtk.EventBox m_eventbox;
	private uint m_timeout_source_id = 0;
	public signal void action();

	public ArticleListOverlay(string text, string tooltip, string iconName)
	{
		m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		m_box.get_style_context().add_class("offline");

        m_label = new Gtk.Label(text);
        m_label.margin_left = 30;
        m_label.get_style_context().add_class("overlay-label");


        m_button = new Gtk.Button();
        m_button.set_halign(Gtk.Align.CENTER);
        m_button.set_valign(Gtk.Align.CENTER);
        m_button.margin_left = 10;
        m_button.margin_right = 30;
		m_button.add(new Gtk.Image.from_icon_name(iconName, Gtk.IconSize.SMALL_TOOLBAR));
		m_button.set_relief(Gtk.ReliefStyle.NONE);
		m_button.set_focus_on_click(false);
		m_button.set_tooltip_text(tooltip);
		m_button.get_style_context().add_class("overlay-button");
		m_button.clicked.connect(() => {
			action();
		});

        m_box.pack_start(m_label, true, false);
        m_box.pack_start(m_button, false , false);

        m_eventbox = new Gtk.EventBox();
		m_eventbox.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
		m_eventbox.set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);
		m_eventbox.enter_notify_event.connect(onEnter);
		m_eventbox.leave_notify_event.connect(onLeave);
		m_eventbox.add(m_box);

        this.set_transition_type(Gtk.RevealerTransitionType.CROSSFADE);
        this.set_reveal_child(true);
        this.margin_left = 40;
        this.margin_right = 40;
        this.margin_top = 10;
        this.set_size_request(-1, 50);
        this.set_vexpand(false);
        this.set_valign(Gtk.Align.START);
        this.no_show_all = true;
        this.add(m_eventbox);
	}

	public void reveal(int animation = 1000, int stay = 5000)
	{
		this.set_visible(true);
		m_eventbox.show_all();

		if (m_timeout_source_id > 0)
		{
			GLib.Source.remove(m_timeout_source_id);
			m_timeout_source_id = 0;
		}

		m_timeout_source_id = Timeout.add(stay, () => {
		    hide(animation);
		    m_timeout_source_id = 0;
			return false;
		});

        this.set_transition_duration(animation);
        this.set_reveal_child(true);
	}

	private void hide(int animation = 1000)
	{
		this.set_transition_duration(animation);
        this.set_reveal_child(false);

        if (m_timeout_source_id > 0)
		{
			GLib.Source.remove(m_timeout_source_id);
			m_timeout_source_id = 0;
		}

		m_timeout_source_id = Timeout.add(animation, () => {
		    this.set_visible(false);
		    m_timeout_source_id = 0;
			return false;
		});
	}

	private bool onEnter(Gdk.EventCrossing event)
	{
		if(event.detail == Gdk.NotifyType.INFERIOR)
			return true;

		if (m_timeout_source_id > 0)
		{
			GLib.Source.remove(m_timeout_source_id);
			m_timeout_source_id = 0;
		}

		this.set_transition_duration(0);
        this.set_reveal_child(true);

		return true;
	}

	private bool onLeave(Gdk.EventCrossing event)
	{
		if(event.detail == Gdk.NotifyType.INFERIOR)
			return true;

		reveal(1000, 2000);
		return true;
	}

}



