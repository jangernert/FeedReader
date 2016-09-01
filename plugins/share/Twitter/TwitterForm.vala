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

		m_countLabel = new Gtk.Label("");
		m_countLabel.set_alignment(0.0f, 0.5f);
		var spinner = new Gtk.Spinner();

		m_stack.add_named(m_countLabel, "label");
		m_stack.add_named(spinner, "spinner");

		m_textView.buffer.changed.connect(() => {
			m_countLabel.set_text(calcLenght(m_textView.buffer.text).to_string() + "/140");
		});


		this.pack_start(m_textView);
		this.pack_start(m_stack, false, false, 5);
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

		ThreadFunc<void*> run = () => {

	        m_urlLength = api.getUrlLength();
			m_countLabel.set_text(calcLenght(m_textView.buffer.text).to_string() + "/140");

	        Idle.add((owned) callback);
	        return null;
	    };
    	Thread.create<void*>(run, false);

		yield;
		m_stack.set_visible_child_name("label");
	}

	private int calcLenght(string text)
	{
		if(text.contains("$URL"))
		{
			if(m_url.length >= m_urlLength)
				return (text.length-3) + m_urlLength;
			else
				return (text.length-3) + m_url.length;
		}

		return text.length;
	}

}
