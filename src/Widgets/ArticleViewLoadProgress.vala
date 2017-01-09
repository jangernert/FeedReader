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

public class FeedReader.ArticleViewLoadProgress : Gtk.Revealer {

    private Gtk.Label m_label;
    private Gtk.Spinner m_spinner;
    private Gtk.Box m_box;
    private uint m_timeout_source_id = 0;

    public ArticleViewLoadProgress()
    {
        m_label = new Gtk.Label("0%");
        m_label.get_style_context().add_class("h2");
        m_spinner = new Gtk.Spinner();
        m_spinner.set_size_request(24, 24);
        m_spinner.margin = 10;
        m_label.margin_end = 10;

        m_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        m_box.get_style_context().add_class("osd");
        m_box.pack_start(m_spinner);
        m_box.pack_start(m_label);

        this.valign = Gtk.Align.CENTER;
        this.halign = Gtk.Align.CENTER;
        this.set_transition_type(Gtk.RevealerTransitionType.CROSSFADE);
		this.set_transition_duration(300);
		this.no_show_all = true;
        this.add(m_box);
    }

    public void setPercentage(uint percentage)
    {
        m_label.set_text("%u %%".printf(percentage));
    }

    public void setPercentageF(double percentage)
    {
        m_label.set_text("%u %%".printf((uint)(percentage*100)));
    }

    public void reveal(bool show)
	{
        if(m_timeout_source_id > 0)
		{
            GLib.Source.remove(m_timeout_source_id);
            m_timeout_source_id = 0;
        }

		if(show)
		{
			this.visible = true;
            m_timeout_source_id = Timeout.add(300, () => {
                m_spinner.show();
                m_label.show();
                m_box.show();
                m_spinner.start();
                this.set_reveal_child(true);
                m_timeout_source_id = 0;
                return false;
            });
		}
        else
        {
            m_spinner.stop();
            this.set_reveal_child(false);
        }
	}

    public void reset()
    {
        reveal(false);
    }


}
