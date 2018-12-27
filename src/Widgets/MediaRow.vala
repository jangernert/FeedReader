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

public class FeedReader.mediaRow : Gtk.ListBoxRow {

private Enclosure m_enc;

public mediaRow(Enclosure enc)
{
	m_enc = enc;

	int lastSlash = m_enc.get_url().last_index_of_char('/');
	string fileName = m_enc.get_url().substring(lastSlash + 1);
	string icon_name = "image-x-generic-symbolic";

	switch(enc.get_enclosure_type())
	{
	case EnclosureType.IMAGE:
		icon_name = "image-x-generic-symbolic";
		break;

	case EnclosureType.AUDIO:
		icon_name = "audio-speakers-symbolic";
		break;

	case EnclosureType.VIDEO:
		icon_name = "media-playback-start-symbolic";
		break;
	}
	var icon = new Gtk.Image.from_icon_name(icon_name, Gtk.IconSize.SMALL_TOOLBAR);

	var label = new Gtk.Label(GLib.Uri.unescape_string(fileName));
	label.set_line_wrap_mode(Pango.WrapMode.WORD);
	label.set_ellipsize(Pango.EllipsizeMode.END);
	label.set_alignment(0.0f, 0.5f);
	label.get_style_context().add_class("h4");

	var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);
	box.margin = 3;
	box.pack_start(icon, false, false, 8);
	box.pack_start(label, true, true, 0);

	this.add(box);
	this.margin = 2;
	this.show_all();
}

public string getURL()
{
	return m_enc.get_url();
}

}
