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
	string body = _("Hey,\n\nCheck out this interesting article I used FeedReader to read: $URL");
	string to = "john.doe@domain.com";

	var labelTo = new Gtk.Label(_("To:"));
	labelTo.set_alignment(0.0f, 0.5f);
	labelTo.get_style_context().add_class("h3");
	m_entry = new Gtk.Entry();
	m_entry.set_text(to);
	var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
	box.pack_start(labelTo, false, false);
	box.pack_start(m_entry, true, true);

	m_textView = new Gtk.TextView();
	m_textView.get_style_context().add_class("h3");
	m_textView.set_wrap_mode(Gtk.WrapMode.WORD);
	m_textView.buffer.text = body;
	m_textView.border_width = 2;

	var scrolled = new Gtk.ScrolledWindow(null, null);
	scrolled.get_style_context().add_class(Gtk.STYLE_CLASS_FRAME);
	scrolled.add(m_textView);

	int margin = 5;
	m_textView.left_margin = margin;
	m_textView.right_margin = margin;
	m_textView.top_margin = margin;
	m_textView.bottom_margin = margin;

	var button = new Gtk.Button.with_label(_("Send"));
	button.halign = Gtk.Align.END;
	button.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
	button.clicked.connect(() => { share(); });

	var backButton = new Gtk.Button.from_icon_name("go-previous-symbolic");
	backButton.set_focus_on_click(false);
	backButton.set_relief(Gtk.ReliefStyle.NONE);
	backButton.halign = Gtk.Align.START;
	backButton.clicked.connect(() => {
			goBack();
		});

	var headline = new Gtk.Label(_("Write Email"));
	headline.get_style_context().add_class("h2");
	headline.set_alignment(0.4f, 0.5f);
	var box2 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
	box2.pack_start(backButton, false, false, 0);
	box2.pack_start(headline, true, true, 0);

	this.pack_start(box2, false, false, 0);
	this.pack_start(box, false, false);
	this.pack_start(scrolled);
	this.pack_end(button, false, false);
	this.orientation = Gtk.Orientation.VERTICAL;
	this.spacing = 5;
	this.margin = 10;
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
