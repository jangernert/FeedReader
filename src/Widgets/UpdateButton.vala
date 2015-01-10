/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * update-button.vala
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

public class UpdateButton : Gtk.Button {

	private Gtk.Image m_icon;
	private Gtk.Spinner m_spinner;
	private bool m_status;

	public UpdateButton (string iconname) {

		m_spinner = new Gtk.Spinner();
		m_spinner.set_size_request(24,24);

		m_icon = new Gtk.Image.from_icon_name(iconname, Gtk.IconSize.LARGE_TOOLBAR);
		this.add(m_icon);
		
		if(feedreader_settings.get_boolean("currently-updating"))
			updating(true);
	}

	public void updating(bool status)
	{
		m_status = status;
		if(status)
		{
			this.remove(m_icon);
			this.add(m_spinner);
			this.sensitive = false;
			m_spinner.start();
		}
		else
		{
			this.remove(m_spinner);
			this.add(m_icon);
			this.sensitive = true;
			m_spinner.stop();
		}
		this.show_all();
	}
	
	public bool getStatus()
	{
		return m_status;
	}

}

