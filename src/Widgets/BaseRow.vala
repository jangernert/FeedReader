public class FeedReader.baseRow : Gtk.ListBoxRow {

	protected Gtk.Label m_spacer;
	protected Gtk.Label m_label;
	protected Gtk.Box m_box;
	protected Gtk.Image m_icon;
	protected uint m_unread_count;
	protected Gtk.Label m_unread;
	protected Gtk.Revealer m_revealer;

	
	public baseRow () {
		m_revealer = new Gtk.Revealer();
		m_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
		//m_revealer.set_transition_duration(500);
	}

	protected void scale_pixbuf(ref Gdk.Pixbuf icon, int size)
	{
		var width = icon.get_width();
		var height = icon.get_height();

		double aspect_ratio = (double)width/(double)height;
		if(width > height)
		{
			width = size;
			height = (int)((float)size /aspect_ratio);
		}
		else if(height > width)
		{
			height = size;
			width = (int)((float)size /aspect_ratio);
		}
		else
		{
			height = size;
			width = size;
		}

		icon = icon.scale_simple(width, height, Gdk.InterpType.BILINEAR);
	}
	
	public void upUnread()
	{
		set_unread_count(m_unread_count+1);
	}
	
	public void downUnread()
	{
		if(m_unread_count > 0)
			set_unread_count(m_unread_count-1);
	}

	public void set_unread_count(uint unread_count)
	{
		m_unread_count = unread_count;

		if(m_unread_count > 0)
		{
			m_unread.set_text ("<span font_weight=\"ultrabold\" >%u</span>".printf(m_unread_count));
			m_unread.set_use_markup (true);
		}
		else
		{
			m_unread.set_text ("");
		}
	}
	
	public uint getUnreadCount()
	{
		return m_unread_count;
	}

	public void reveal(bool reveal, uint duration = 500)
	{
		if(settings_state.get_boolean("no-animations"))
		{
			m_revealer.set_transition_type(Gtk.RevealerTransitionType.NONE);
			m_revealer.set_transition_duration(0);
			m_revealer.set_reveal_child(reveal);
			m_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
			m_revealer.set_transition_duration(500);
		}
		else
		{
			m_revealer.set_transition_duration(duration);
			m_revealer.set_reveal_child(reveal);
		}
	}

	public bool isRevealed()
	{
		return m_revealer.get_reveal_child();
	}
	
	public bool AnimationFinished()
	{
		return m_revealer.get_child_revealed();
	}
	
	public uint transitionDuration()
	{
		return m_revealer.get_transition_duration();
	}

}

