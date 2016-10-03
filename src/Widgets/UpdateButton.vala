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

	public UpdateButton.from_icon_name(string iconname, string tooltip)
	{
		m_icon = new Gtk.Image.from_icon_name(iconname, Gtk.IconSize.SMALL_TOOLBAR);
		setup(tooltip);
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
		m_spinner.get_style_context().add_class("feedlist-spinner");

		m_stack = new Gtk.Stack();
		m_stack.add_named(m_spinner, "spinner");
		m_stack.add_named(m_icon, "icon");

		this.add(m_stack);
		this.set_relief(Gtk.ReliefStyle.NONE);
		this.set_focus_on_click(false);
		this.set_tooltip_text(tooltip);
		this.show_all();

		if(Settings.state().get_boolean("currently-updating"))
			updating(true);
		else
			updating(false);
	}

	public void updating(bool status)
	{

		Logger.get().debug("UpdateButton: update status");
		m_status = status;
		if(status)
		{
			m_stack.set_visible_child_name("spinner");
			this.setSensitive(false);
			m_spinner.start();
		}
		else
		{
			m_stack.set_visible_child_name("icon");
			this.setSensitive(true);
			m_spinner.stop();
		}
	}

	public bool getStatus()
	{
		return m_status;
	}

	public void setSensitive(bool sensitive)
	{
		Logger.get().debug("UpdateButton: setSensitive %s".printf(sensitive ? "true" : "false"));
		this.sensitive = sensitive;
	}

}
