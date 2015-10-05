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

	private string m_name;
    private Gtk.Label m_label;
    private Gtk.Box m_box;
    private string m_id;

	public ShareRow(string serviceName, OAuth type, string id)
	{
		m_id = id;
		m_name = serviceName;

        m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);
        m_box.margin = 3;
        string iconName = "";

        switch(type)
        {
            case OAuth.READABILITY:
                iconName = "feed-share-readability";
                break;

            case OAuth.INSTAPAPER:
                iconName = "feed-share-instapaper";
                break;

            case OAuth.POCKET:
                iconName = "feed-share-pocket";
                break;
        }
        var icon = new Gtk.Image.from_icon_name(iconName, Gtk.IconSize.DND);

        m_label = new Gtk.Label(serviceName);
        m_label.set_line_wrap_mode(Pango.WrapMode.WORD);
        m_label.set_ellipsize(Pango.EllipsizeMode.END);
        m_label.set_alignment(0.5f, 0.5f);

        m_box.pack_start(icon, false, false, 8);
        m_box.pack_start(m_label, true, true, 0);

		this.add(m_box);
		this.show_all();
	}

    public string getID()
    {
        return m_id;
    }

}
