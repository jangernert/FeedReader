/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * ttrssrow.vala
 * Copyright (C) 2014 JeanLuc <jeanluc@jeanluc-desktop>
 *
 * tt-rss is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * tt-rss is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public class baseRow : Gtk.ListBoxRow {

	protected Gtk.Label m_spacer;
	protected Gtk.Label m_label;
	protected Gtk.Box m_box;
	protected Gtk.Image m_icon;
	protected string m_unread_count;
	protected Gtk.Label m_unread;
	protected Gtk.Revealer m_revealer;
	protected bool m_isRevealed;

	
	public baseRow () {
		
	}

	protected void scale_pixbuf(ref Gdk.Pixbuf icon, int size)
	{
		var width = icon.get_width();
		var height = icon.get_height();

		double aspect_ratio = (double)width/(double)height;
		if(width > height)
		{
			width = size;
			height = (int)((float)size /aspect_ratio);
		}
		else if(height > width)
		{
			height = size;
			width = (int)((float)size /aspect_ratio);
		}
		else
		{
			height = size;
			width = size;
		}

		icon = icon.scale_simple(width, height, Gdk.InterpType.BILINEAR);
	}

	public void set_unread_count(string unread_count)
	{
		m_unread_count = unread_count;

		if(int.parse(m_unread_count) > 0)
		{
			m_unread.set_text ("<span font_weight=\"ultrabold\" >" + m_unread_count.to_string () + "</span>");
			m_unread.set_use_markup (true);
		}
		else
		{
			m_unread.set_text ("");
		}
	}

	public void reveal(bool reveal)
	{
		m_revealer.set_reveal_child(reveal);
		m_isRevealed = reveal;
	}

	public bool isRevealed()
	{
		return m_isRevealed;
	}

}

