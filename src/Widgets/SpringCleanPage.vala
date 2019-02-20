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
