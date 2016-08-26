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

public class FeedReader.ShareRow : Gtk.ListBoxRow {

    private string m_id;

	public ShareRow(OAuth type, string id, string username, string iconName)
	{
		m_id = id;
        var icon = new Gtk.Image.from_icon_name(iconName, Gtk.IconSize.DND);
        var serviceLabel = new Gtk.Label(username);
        serviceLabel.set_line_wrap_mode(Pango.WrapMode.WORD);
        serviceLabel.set_ellipsize(Pango.EllipsizeMode.END);
        serviceLabel.set_alignment(0.0f, 0.5f);
        serviceLabel.get_style_context().add_class("h4");

		var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);
        box.margin = 3;
        box.pack_start(icon, false, false, 8);
        box.pack_start(serviceLabel, true, true, 0);

		this.add(box);
		this.margin = 2;
		this.show_all();
	}

    public string getID()
    {
        return m_id;
    }

}
