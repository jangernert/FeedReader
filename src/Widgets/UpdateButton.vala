public class FeedReader.UpdateButton : Gtk.Button {

	private Gtk.Image m_icon;
	private Gtk.Spinner m_spinner;
	private bool m_status;
	private Gtk.Stack m_stack;

	public UpdateButton (string iconname) {

		m_spinner = new Gtk.Spinner();
		m_stack = new Gtk.Stack();
		m_spinner.set_size_request(24,24);
		this.set_relief(Gtk.ReliefStyle.NONE);

		m_icon = new Gtk.Image.from_icon_name(iconname, Gtk.IconSize.LARGE_TOOLBAR);
		m_stack.add_named(m_spinner, "spinner");
		m_stack.add_named(m_icon, "icon");
		this.add(m_stack);
		this.set_focus_on_click(false);
		this.set_tooltip_text(_("update Feeds"));
		this.show_all();

		if(settings_state.get_boolean("currently-updating"))
			updating(true);
		else
			updating(false);
	}

	public void updating(bool status)
	{

		logger.print(LogMessage.DEBUG, "UpdateButton: update status");
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
		logger.print(LogMessage.DEBUG, "UpdateButton: setSensitive %s".printf(sensitive ? "true" : "false"));
		this.sensitive = sensitive;
	}

}
