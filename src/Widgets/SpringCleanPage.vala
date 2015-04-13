public class FeedReader.SpringCleanPage : Gtk.Bin {

	private Gtk.Spinner m_spinner;
	private Gtk.Box m_spinnerBox;

	public SpringCleanPage() {
		m_spinnerBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 20);

		m_spinner = new Gtk.Spinner();
		m_spinner.set_size_request(40, 40);
		m_spinner.start();

		var label = new Gtk.Label(_("FeedReader is cleaning the database.\nThis shouldn't take too long."));
		label.get_style_context().add_class("h2");
		label.set_alignment(0, 0.5f);
		label.set_ellipsize (Pango.EllipsizeMode.END);
		label.set_line_wrap_mode(Pango.WrapMode.WORD_CHAR);
		label.set_line_wrap(true);
		label.set_lines(2);

		m_spinnerBox.pack_start(m_spinner, false, false, 0);
		m_spinnerBox.pack_end(label, false, false, 0);

		this.set_halign(Gtk.Align.CENTER);
		this.set_valign(Gtk.Align.CENTER);
		this.margin = 20;
		this.add(m_spinnerBox);
	}
}
