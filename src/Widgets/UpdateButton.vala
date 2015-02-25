public class FeedReader.UpdateButton : Gtk.Button {

	private Gtk.Image m_icon;
	private Gtk.Spinner m_spinner;
	private bool m_status;

	public UpdateButton (string iconname) {
		
		m_spinner = new Gtk.Spinner();
		m_spinner.set_size_request(24,24);

		m_icon = new Gtk.Image.from_icon_name(iconname, Gtk.IconSize.LARGE_TOOLBAR);
		this.add(m_icon);
		
		if(settings_state.get_boolean("currently-updating"))
			updating(true);
	}

	public void updating(bool status)
	{
		logger.print(LogMessage.DEBUG, "UpdateButton: update status");
		m_status = status;
		if(status)
		{
			this.remove(m_icon);
			this.add(m_spinner);
			this.setSensitive(false);
			m_spinner.start();
		}
		else
		{
			this.remove(m_spinner);
			this.add(m_icon);
			this.setSensitive(true);
			m_spinner.stop();
		}
		this.show_all();
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

