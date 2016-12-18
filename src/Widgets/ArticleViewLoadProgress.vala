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

public class FeedReader.ArticleViewLoadProgress : Gtk.Box {

    private Gtk.Label m_label;
    private Gtk.Spinner m_spinner;
    private double m_opacityGoal = 1.0;
    private uint m_timeout_source_id = 0;

    public ArticleViewLoadProgress()
    {
        m_label = new Gtk.Label("0%");
        m_label.get_style_context().add_class("h2");
        m_spinner = new Gtk.Spinner();
        m_spinner.set_size_request(24, 24);
        m_spinner.margin = 10;
        m_label.margin_end = 10;
        this.orientation = Gtk.Orientation.HORIZONTAL;
        this.pack_start(m_spinner);
        this.pack_start(m_label);
        this.valign = Gtk.Align.CENTER;
        this.halign = Gtk.Align.CENTER;
        this.get_style_context().add_class("overlay");
		this.no_show_all = true;
        this.opacity = 1.0;
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
			m_spinner.show();
            m_label.show();
            m_spinner.start();
		}

        m_timeout_source_id = Timeout.add(300, () => {
            m_timeout_source_id = Timeout.add(15, () => {
    			if(show)
    			{
    				if(this.opacity-m_opacityGoal <= 0.04)
    				{
    					this.opacity = m_opacityGoal;
    					m_timeout_source_id = 0;
    					return false;
    				}

    				if(this.opacity == 1.0)
    				{
    					m_timeout_source_id = 0;
    					return false;
    				}

    				this.opacity += 0.04;
    			}
    			else
    			{
    				if(this.opacity == 0.0)
    				{
                        this.visible = false;
                        m_spinner.stop();
    					m_timeout_source_id = 0;
    					return false;
    				}

    				this.opacity -= 0.04;
    			}

                return true;
            });
            return false;
        });
	}


}
