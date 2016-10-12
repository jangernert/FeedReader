//	This file is part of FeedReader.
//
//	FeedReader is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	FeedReader is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General public License for more details.
//
//	You should have received a copy of the GNU General public License
//	along with FeedReader.  If not, see <http://www.gnu.org/licenses/>.

public class FeedReader.ArticleListScroll : Gtk.ScrolledWindow {

	public signal void scrolledTop();
	public signal void scrolledBottom();
	public signal void valueChanged(ScrollDirection direction);

	private double m_upperCache = 0.0;
	private double m_valueCache = 0.0;
	private double m_bottomThreshold = 200.0;
	private ArticleListBalance m_balance = ArticleListBalance.NONE;

	private bool m_scrolledBottomOnCooldown = false;
	private int m_scrolledBottomCooldown = 200; // cooldown in ms

	//Transition times
    private int64 m_startTime;
    private int64 m_endTime;
    private double m_transitionDiff;
    private double m_transitionStartValue;
	private int m_transitionDuration = 500 * 1000;


	public ArticleListScroll()
	{
		vadjustment.notify["upper"].connect(trackUpper);
		vadjustment.notify["value"].connect(trackValue);
		this.set_size_request(250, 0);
    }

	private void trackUpper()
	{
		double upper = vadjustment.upper;
		if(m_balance == ArticleListBalance.TOP)
		{
			double inc = (upper - m_upperCache);
			this.vadjustment.value += inc;
			m_balance = ArticleListBalance.NONE;
		}

		if(GLib.Math.fabs(vadjustment.upper - m_upperCache) > 2.0)
			checkScrolledDown();

		m_upperCache = vadjustment.upper;
		m_valueCache = vadjustment.value;
    }

	private void trackValue()
	{
		if(vadjustment.value > m_valueCache)
			valueChanged(ScrollDirection.DOWN);
		else if(vadjustment.value < m_valueCache)
			valueChanged(ScrollDirection.UP);

		if(vadjustment.value < 2.0)
			scrolledTop();

		checkScrolledDown();

		double upper = vadjustment.upper;
		if(m_balance == ArticleListBalance.BOTTOM)
		{
			double inc = (upper - m_upperCache);
			this.vadjustment.value -= inc;
			m_balance = ArticleListBalance.NONE;
		}
		m_upperCache = vadjustment.upper;
		m_valueCache = vadjustment.value;
	}

	private void checkScrolledDown()
	{
		double max = vadjustment.upper - vadjustment.page_size;
		if(vadjustment.value >= max - m_bottomThreshold
		&& !m_scrolledBottomOnCooldown)
		{
			scrolledBottom();
			m_scrolledBottomOnCooldown = true;
			GLib.Timeout.add(m_scrolledBottomCooldown, () => {
				m_scrolledBottomOnCooldown = false;
				return false;
			});
		}
	}

	public void balanceNextScroll(ArticleListBalance mode)
	{
		m_balance = mode;
    }

	public void scrollDiff(double diff, bool animate = true)
	{
		scrollToPos(vadjustment.value + diff, animate);
	}

	public void scrollToPos(double pos, bool animate = true)
	{
		if(!this.get_mapped())
		{
			setScroll(pos);
			return;
		}

		if(Gtk.Settings.get_default().gtk_enable_animations && animate)
		{
			m_startTime = this.get_frame_clock().get_frame_time();
			m_endTime = m_startTime + m_transitionDuration;

			if(pos == -1)
				m_transitionDiff =  (vadjustment.upper - vadjustment.page_size - vadjustment.value);
			else
				m_transitionDiff = pos-this.vadjustment.value;

			m_transitionStartValue = vadjustment.value;
			this.add_tick_callback(scrollTick);
		}
		else
		{
			setScroll(pos);
		}
	}

	public double getScroll()
	{
		return this.vadjustment.value;
	}

	private void setScroll(double pos)
	{
		if(pos == -1)
			this.vadjustment.value = this.vadjustment.upper - this.vadjustment.page_size;
		else
			this.vadjustment.value = pos;
	}

	public double getPageSize()
	{
		return this.vadjustment.page_size;
	}

	public int isVisible(Gtk.ListBoxRow row, int additionalRows = 0)
	{
		var rowHeight = row.get_allocated_height();
		var scrollHeight = this.get_allocated_height();
		int x, y = 0;

		row.translate_coordinates(this, 0, 0, out x, out y);

		// row is (additionalRows * rowHeight) above the current viewport
		if(y < -( (1+additionalRows) * rowHeight))
			return -1;

		// row is (additionalRows * rowHeight) below the current viewport
		if(y > (additionalRows) * rowHeight + scrollHeight)
			return 1;

		// row is visible
		return 0;
	}

	private bool scrollTick(Gtk.Widget widget, Gdk.FrameClock frame_clock)
	{
		if(!this.get_mapped())
		{
			vadjustment.value = m_transitionStartValue + m_transitionDiff;
			return false;
		}

		int64 now = frame_clock.get_frame_time();
		double t = 1.0;

		if(now < this.m_endTime)
			t = (now - m_startTime) / (double)(m_endTime - m_startTime);

		t = easeOutCubic(t);

		this.vadjustment.value = m_transitionStartValue + (t * m_transitionDiff);

		if(this.vadjustment.value <= 0 || now >= m_endTime)
		{
			this.queue_draw();
			return false;
		}

		return true;
	}

	inline double easeOutCubic(double t)
	{
		double p = t - 1;
		return p * p * p +1;
	}

}
