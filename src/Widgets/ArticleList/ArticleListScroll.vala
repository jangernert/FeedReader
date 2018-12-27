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
private double m_valueThreshold = 50.0;
private double m_bottomThreshold = 200.0;
private ArticleListBalance m_balance = ArticleListBalance.NONE;

private bool m_allowSignals = true;
private bool m_scrolledTopOnCooldown = false;
private bool m_scrolledBottomOnCooldown = false;
private int m_scrollCooldown = 500;         // cooldown in ms

//Transition times
private int64 m_startTime = 0;
private int64 m_endTime = 0;
private double m_transitionDiff = 0.0;
private double m_transitionStartValue = 0.0;
private int m_transitionDuration = 500 * 1000;
private uint m_scrollCallbackID = 0;
private uint m_savetyFallbackID = 0;
private uint m_scrollCooldownID = 0;



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
		Logger.debug(@"Balance TOP $inc");
		this.vadjustment.value += inc;
		m_balance = ArticleListBalance.NONE;
	}
	else if(m_balance == ArticleListBalance.BOTTOM)
	{
		double inc = (m_upperCache - upper);
		Logger.debug(@"Balance BOTTOM $inc");
		this.vadjustment.value -= inc;
		m_balance = ArticleListBalance.NONE;
	}

	if(GLib.Math.fabs(vadjustment.upper - m_upperCache) > 2.0)
		checkScrolledDown();

	m_upperCache = vadjustment.upper;
	m_valueCache = vadjustment.value;
}

private void trackValue()
{
	if(vadjustment.value > (m_valueCache + m_valueThreshold))
		valueChanged(ScrollDirection.DOWN);
	else if(vadjustment.value < (m_valueCache - m_valueThreshold))
		valueChanged(ScrollDirection.UP);

	checkScrolledTop();
	checkScrolledDown();

	m_upperCache = vadjustment.upper;
	m_valueCache = vadjustment.value;
}

private void checkScrolledTop()
{
	if(m_allowSignals
	   && vadjustment.value < 2.0
	   && !m_scrolledTopOnCooldown)
	{
		m_scrolledTopOnCooldown = true;
		scrolledTop();
		GLib.Timeout.add(m_scrollCooldown, () => {
				m_scrolledTopOnCooldown = false;
				if(vadjustment.value < 2.0)
					scrolledTop();
				return false;
			});
	}
}

private void checkScrolledDown()
{
	double max = vadjustment.upper - vadjustment.page_size;
	if(m_allowSignals
	   && max > 0.0
	   && vadjustment.value >= (max - m_bottomThreshold)
	   && !m_scrolledBottomOnCooldown)
	{
		Logger.debug("ArticleListScroll: scrolled down");
		m_scrolledBottomOnCooldown = true;
		scrolledBottom();
		// reset cooldown after 5s if something went wrong
		m_savetyFallbackID = GLib.Timeout.add_seconds(5, () => {
				m_savetyFallbackID = 0;
				m_scrolledBottomOnCooldown = false;
				return GLib.Source.REMOVE;
			});
	}
}

public void startScrolledDownCooldown()
{
	if(m_scrollCooldownID != 0)
	{
		GLib.Source.remove(m_scrollCooldownID);
		m_scrollCooldownID = 0;
	}

	m_scrollCooldownID = GLib.Timeout.add(m_scrollCooldown, () => {
			Logger.debug("ArticleListScroll: scrolled down off cooldown");
			m_scrollCooldownID = 0;
			m_scrolledBottomOnCooldown = false;
			if(m_savetyFallbackID != 0)
			{
			        GLib.Source.remove(m_savetyFallbackID);
			        m_savetyFallbackID = 0;
			}
			double max = vadjustment.upper - vadjustment.page_size;
			if(vadjustment.value >= max - 5)
			{
			        Logger.debug("ArticleListScroll: trigger scrolledBottom()");
			        scrolledBottom();
			}

			return GLib.Source.REMOVE;
		});
}

public void balanceNextScroll(ArticleListBalance mode)
{
	m_balance = mode;
}

public void scrollDiff(double diff, bool animate = true)
{
	Logger.debug("ArticleListScroll.scrollDiff: value: %f - diff: %f".printf(this.vadjustment.value, diff));
	scrollToPos(this.vadjustment.value + diff, animate);
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
		Logger.debug(@"ArticleListScroll.scrollToPos: $pos");
		m_startTime = this.get_frame_clock().get_frame_time();
		m_endTime = m_startTime + m_transitionDuration;

		double leftOverScroll = 0.0;
		if(m_scrollCallbackID != 0)
		{
			leftOverScroll = m_transitionStartValue + m_transitionDiff - this.vadjustment.value;
			this.remove_tick_callback(m_scrollCallbackID);
			m_scrollCallbackID = 0;
		}

		Logger.debug(@"ArticleListScroll.scrollToPos: leftOverScroll $leftOverScroll");
		Logger.debug(@"ArticleListScroll.scrollToPos: %f".printf(pos+leftOverScroll));

		if(pos == -1)
			m_transitionDiff = (vadjustment.upper - vadjustment.page_size - vadjustment.value);
		else
			m_transitionDiff = (pos-this.vadjustment.value)+leftOverScroll;

		m_transitionStartValue = this.vadjustment.value;
		Logger.debug(@"ArticleListScroll.scrollDiff: startValue $m_transitionStartValue");
		m_scrollCallbackID = this.add_tick_callback(scrollTick);
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
	if(y > additionalRows * rowHeight + scrollHeight)
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
		m_transitionStartValue = 0.0;
		m_scrollCallbackID = 0;
		return false;
	}

	return true;
}

inline double easeOutCubic(double t)
{
	double p = t - 1;
	return p * p * p +1;
}

public void allowSignals(bool allow)
{
	m_allowSignals = allow;
}

}
