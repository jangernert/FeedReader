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
private int m_urlLength = 0;
private string m_url;
private Gtk.Stack m_stack;
private Gtk.Label m_countLabel;

public TwitterForm(string url)
{
	m_url = url;
	m_stack = new Gtk.Stack();
	string body = _("Hey,\n\nCheck out this interesting article I just read: $URL");

	m_textView = new Gtk.TextView();
	m_textView.set_wrap_mode(Gtk.WrapMode.WORD);
	m_textView.buffer.text = body;
	m_textView.border_width = 2;
	m_textView.get_style_context().add_class("h3");

	var scrolled = new Gtk.ScrolledWindow(null, null);
	scrolled.get_style_context().add_class(Gtk.STYLE_CLASS_FRAME);
	scrolled.add(m_textView);

	int margin = 5;
	m_textView.left_margin = margin;
	m_textView.right_margin = margin;
	m_textView.top_margin = margin;
	m_textView.bottom_margin = margin;

	var limitLabel = new Gtk.Label(_("Limit: "));
	limitLabel.set_alignment(0.0f, 0.5f);
	limitLabel.get_style_context().add_class("h3");

	m_countLabel = new Gtk.Label("");
	m_countLabel.set_alignment(0.0f, 0.5f);
	m_countLabel.get_style_context().add_class("h3");
	var spinner = new Gtk.Spinner();

	m_stack.add_named(m_countLabel, "label");
	m_stack.add_named(spinner, "spinner");

	m_textView.buffer.changed.connect(() => {
			updateCount();
		});

	var button = new Gtk.Button.with_label(_("Tweet"));
	button.get_style_context().add_class(Gtk.STYLE_CLASS_SUGGESTED_ACTION);
	button.clicked.connect(() => { share(); });

	var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
	box.pack_start(limitLabel, false, false, 0);
	box.pack_start(m_stack, false, false, 0);
	box.pack_end(button, false, false, 0);

	var backButton = new Gtk.Button.from_icon_name("go-previous-symbolic");
	backButton.set_focus_on_click(false);
	backButton.set_relief(Gtk.ReliefStyle.NONE);
	backButton.halign = Gtk.Align.START;
	backButton.clicked.connect(() => {
			goBack();
		});

	var headline = new Gtk.Label(_("Tweet to Followers"));
	headline.get_style_context().add_class("h2");
	headline.set_alignment(0.4f, 0.5f);
	var box2 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
	box2.pack_start(backButton, false, false, 0);
	box2.pack_start(headline, true, true, 0);

	this.pack_start(box2, false, false, 0);
	this.pack_start(scrolled);
	this.pack_end(box, false, false);
	this.orientation = Gtk.Orientation.VERTICAL;
	this.spacing = 5;
	this.margin = 10;
	this.show_all();

	m_stack.set_visible_child_name("spinner");
	spinner.start();
}

public string getTweet()
{
	return m_textView.buffer.text;
}

public async void setAPI(TwitterAPI api)
{
	SourceFunc callback = setAPI.callback;

	new Thread<void*>(null, () => {
			m_urlLength = api.getUrlLength();
			Idle.add((owned) callback, GLib.Priority.HIGH_IDLE);
			return null;
		});

	yield;
	updateCount();
	m_stack.set_visible_child_name("label");
}

private int calcLenght(string text)
{
	if(text.contains("$URL"))
	{
		if(m_url.length >= m_urlLength)
		{
			return (text.length-3) + m_urlLength;
		}
		else
		{
			return (text.length-3) + m_url.length;
		}
	}

	return text.length;
}

private void updateCount()
{
	m_countLabel.set_text(calcLenght(m_textView.buffer.text).to_string() + "/140");
}

}
