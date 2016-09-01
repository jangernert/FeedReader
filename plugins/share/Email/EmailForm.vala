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


public class FeedReader.EmailForm : ShareForm {

	private Gtk.Entry m_entry;
	private Gtk.TextView m_textView;

	public EmailForm(string url)
	{
		string body = _("Hey,\n\nCheck out this interesting article I just read: $URL\n\n- sent by FeedReader");
		string to = "john.doe@domain.com";

		var labelTo = new Gtk.Label(_("To:"));
		labelTo.set_alignment(0.0f, 0.5f);
		labelTo.get_style_context().add_class("h4");
		m_entry = new Gtk.Entry();
		m_entry.set_text(to);
		var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
		box.pack_start(labelTo, false, false);
		box.pack_start(m_entry, true, true);

		var scrolled = new Gtk.ScrolledWindow(null, null);
		m_textView = new Gtk.TextView();
		m_textView.set_wrap_mode(Gtk.WrapMode.WORD);
		m_textView.buffer.text = body;
		m_textView.border_width = 1;

		int margin = 5;
		m_textView.left_margin = margin;
		m_textView.right_margin = margin;
		m_textView.top_margin = margin;
		m_textView.bottom_margin = margin;

		this.pack_start(box, false, false);
		this.pack_start(m_textView);
		this.show_all();
	}

	public string getTo()
	{
		return m_entry.get_text();
	}

	public string getBody()
	{
		return m_textView.buffer.text;
	}

}
