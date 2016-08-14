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

public class FeedReader.feedlyLoginWidget : Gtk.Box {

	public feedlyLoginWidget()
	{
		var logo = new Gtk.Image.from_file(InstallPrefix + "/share/icons/hicolor/64x64/places/feed-service-feedly.svg");

		var text = new Gtk.Label(_("You will be redirected to the feedly website where you can use your Facebook-, Google-, Twitter-, Microsoft- or Evernote-Account to log in."));
		text.get_style_context().add_class("h3");
		text.set_justify(Gtk.Justification.CENTER);
		text.set_line_wrap_mode(Pango.WrapMode.WORD);
		text.set_line_wrap(true);
		text.set_lines(3);
		text.expand = false;
		text.set_width_chars(60);
		text.set_max_width_chars(60);

		this.orientation = Gtk.Orientation.VERTICAL;
		this.spacing = 10;
		this.pack_start(logo, false, false, 10);
		this.pack_start(text, true, true, 10);
		this.show_all();
	}

	public void populateList(Gtk.ListStore liststore)
	{
		Gtk.TreeIter iter;
		liststore.append(out iter);
		liststore.set(iter, 0, _("Feedly"));
	}
}
