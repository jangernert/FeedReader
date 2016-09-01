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


public class FeedReader.TwitterForm : ShareForm {

	private Gtk.TextView m_textView;
	public signal void textChanged(string to, string body);

	public TwitterForm()
	{
		string body = _("Hey,\n\nCheck out this interesting article I just read: $URL");

		var scrolled = new Gtk.ScrolledWindow(null, null);
		m_textView = new Gtk.TextView();
		m_textView.set_wrap_mode(Gtk.WrapMode.WORD);
		m_textView.buffer.text = body;
		m_textView.border_width = 1;

		this.pack_start(m_textView);
		this.show_all();
	}

	public string getTweet()
	{
		return m_textView.buffer.text;
	}

}
