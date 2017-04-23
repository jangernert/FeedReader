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

    private Gtk.ProgressBar m_progress;
    private uint m_timeout_source_id = 0;

    public ArticleViewLoadProgress()
    {
        m_progress = new Gtk.ProgressBar();
        m_progress.set_show_text(false);
        this.set_transition_type(Gtk.RevealerTransitionType.CROSSFADE);
        this.set_transition_duration(300);
        this.no_show_all = true;
        this.add(m_progress);
    }

    public void setPercentage(uint percentage)
    {
        m_progress.set_fraction(percentage);
    }

    public void setPercentageF(double percentage)
    {
        m_progress.set_fraction(percentage);
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
                  this.set_reveal_child(true);
                  m_timeout_source_id = 0;
                  return false;
            });
        }
        else
        {
            this.set_reveal_child(false);
        }
	}

    public void reset()
    {
        reveal(false);
    }


}
