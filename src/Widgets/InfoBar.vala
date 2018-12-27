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

public class FeedReader.InfoBar : Gtk.Revealer {

// THIS IS BASICALLY A WORKAROUND FOR THIS GTK+ BUG:
// https://bugzilla.gnome.org/show_bug.cgi?id=710888

private Gtk.Label m_Label;

public InfoBar(string text)
{
	m_Label = new Gtk.Label(text);

	var bar = new Gtk.InfoBar();
	bar.valign = Gtk.Align.START;
	bar.get_content_area().add(m_Label);
	bar.set_message_type(Gtk.MessageType.WARNING);
	bar.set_show_close_button(true);
	bar.response.connect((response_id) => {
			if(response_id == Gtk.ResponseType.CLOSE)
				this.set_reveal_child(false);
		});

	this.set_transition_duration(200);
	this.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
	this.valign = Gtk.Align.START;
	this.add(bar);
}

public void reveal()
{
	this.show_all();
	this.set_reveal_child(true);
}

public void setText(string text)
{
	m_Label.set_text(text);
}

}
