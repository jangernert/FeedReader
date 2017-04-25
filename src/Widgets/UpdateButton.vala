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

public class FeedReader.UpdateButton : Gtk.Button {

	private Gtk.Image m_icon;
	private Gtk.Spinner m_spinner;
	private bool m_status;
	private Gtk.Stack m_stack;
	private Gtk.Label m_ProgressText;
	private bool m_hasPopup;
	private Gtk.Popover m_Popover;

	public UpdateButton.from_icon_name(string iconname, string tooltip, bool progressPopup = false)
	{
		m_hasPopup = progressPopup;
		m_icon = new Gtk.Image.from_icon_name(iconname, Gtk.IconSize.SMALL_TOOLBAR);
		setup(tooltip);

		if(m_hasPopup)
		{
			m_ProgressText = new Gtk.Label(Settings.state().get_string("sync-status"));
			m_ProgressText.margin = 20;
			m_Popover = new Gtk.Popover(this);
			m_Popover.add(m_ProgressText);
			this.enter_notify_event.connect(onEnter);
		}
	}

	public UpdateButton.from_resource(string iconname, string tooltip)
	{
		m_icon = new Gtk.Image.from_resource(iconname);
		setup(tooltip);
	}

	private void setup(string tooltip)
	{
		m_spinner = new Gtk.Spinner();
		m_spinner.set_size_request(16,16);

		m_stack = new Gtk.Stack();
		m_stack.set_transition_duration(100);
		m_stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE);
		m_stack.add_named(m_spinner, "spinner");
		m_stack.add_named(m_icon, "icon");

		this.add(m_stack);
		this.set_relief(Gtk.ReliefStyle.NONE);
		this.set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
		this.set_focus_on_click(false);
		this.set_tooltip_text(tooltip);
		this.show_all();
	}

	public void updating(bool status, bool insensitive = true)
	{
		Logger.debug("UpdateButton: update status");
		m_status = status;
		this.set_has_tooltip(!status);
		if(insensitive)
			this.setSensitive(!status);
		if(status)
		{
			m_stack.set_visible_child_name("spinner");
			m_spinner.start();
		}
		else
		{
			m_stack.set_visible_child_name("icon");
			m_spinner.stop();
		}
	}

	public bool getStatus()
	{
		return m_status;
	}

	public void setSensitive(bool sensitive)
	{
		// FIXME: dont set sensitive if canceling
		Logger.debug("UpdateButton: setSensitive %s".printf(sensitive ? "true" : "false"));
		this.sensitive = sensitive;
	}

	public void setProgress(string text)
	{
		if(m_hasPopup)
			m_ProgressText.set_text(text);
	}

	private bool onEnter(Gdk.EventCrossing event)
    {
		if(m_status && !m_Popover.get_visible())
			m_Popover.show_all();

        return false;
    }

}
