/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * ttrss_interface.vala
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

public class feedly_interface : GLib.Object {

	private FeedlyAPI m_api;
	private Soup.Session m_session;
	private string m_contenttype;
	private Json.Parser m_parser;

	
	public feedly_interface ()
	{
		string devel_token = "AgC3A157ImEiOiJGZWVkbHkgRGV2ZWxvcGVyIiwiZSI6MTQyODA4ODYxOTIwNSwiaSI6IjliN2ZkYjg3LTljYWUtNGIyNy05NGQyLTEwMGExMTM4YTg2OSIsInAiOjYsInQiOjEsInYiOiJwcm9kdWN0aW9uIiwidyI6IjIwMTQuMjciLCJ4Ijoic3RhbmRhcmQifQ:feedlydev";
		m_api = FeedlyAPI.get_api_with_token (devel_token);
		
		m_session = new Soup.Session ();
		m_contenttype = "application/x-www-form-urlencoded";
		m_parser = new Json.Parser ();
	}

	
	public bool login(out string error_message)
	{
		return check_internet_connection ();
	}
	
	public bool check_internet_connection () {
        try {
            Resolver resolver = Resolver.get_default ();
            resolver.lookup_by_name ("www.feedly.com", null);
            return true;
        } catch (Error e) {
            stdout.printf ("Error: %s\n", e.message);
            return false;
        }
    }


}

