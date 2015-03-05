public class FeedReader.InitSyncPage : Gtk.Alignment {

	private Gtk.Spinner m_spinner;
	private Gtk.Box m_layout;
	public signal void finished();

	public InitSyncPage() {
		m_layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 20);

		m_spinner = new Gtk.Spinner();
		m_spinner.set_size_request(40, 40);
		m_spinner.start();

		var label = new Gtk.Label(_("FeedReader is now getting the first batch of articles.\nDepending on your connection and settings this can take some time."));
		label.get_style_context().add_class("h2");
		label.set_alignment(0, 0.5f);
		label.set_ellipsize (Pango.EllipsizeMode.END);
		label.set_line_wrap_mode(Pango.WrapMode.WORD_CHAR);
		label.set_line_wrap(true);
		label.set_lines(2);

		m_layout.pack_start(m_spinner, false, true, 0);
		m_layout.pack_start(label, false, true, 0);

		this.@set(0.5f, 0.5f, 0.0f, 0.0f);
		this.set_padding(20, 20, 20, 20);
		this.add(m_layout);
		this.show_all();
	}


	public void start()
	{
		GLib.Timeout.add_seconds_full(GLib.Priority.DEFAULT, 2, () => {
			try{
				feedDaemon_interface.startInitSync();
			}catch (IOError e) {
				logger.print(LogMessage.ERROR, e.message);
			}
			return false;
		});
	}


}
