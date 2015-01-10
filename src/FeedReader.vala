/* -*- Mode: C; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * main.c
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

using GLib;
using Gtk;

dbManager dataBase;
GLib.Settings feedreader_settings;
FeedDaemon feedDaemon_interface;


[DBus (name = "org.gnome.feedreader")]
interface FeedDaemon : Object {
    public abstract void startSync() throws IOError;
    public abstract int login() throws IOError;
    public abstract int isLoggedIn() throws IOError;
    public abstract void changeUnread(string articleID, int read) throws IOError;
    public abstract void changeMarked(string articleID, int marked) throws IOError;
    public abstract void updateBadge() throws IOError;
    public signal void syncStarted();
    public signal void syncFinished();
    public signal void loginDialog(int ErrorCode);
}


public class rssReaderApp : Gtk.Application {

	private readerUI m_window;
	
	 
	protected override void startup () {
		startDaemon();
		
		dataBase = new dbManager();
		dataBase.init();
		
		feedreader_settings = new GLib.Settings ("org.gnome.feedreader");
		
		try{
			feedDaemon_interface = Bus.get_proxy_sync (BusType.SESSION, "org.gnome.feedreader", "/org/gnome/feedreader");
			
			feedDaemon_interface.syncStarted.connect(() => {
		        stdout.printf ("sync started\n");
		        m_window.setRefreshButton(true);
		    });
		    
		    feedDaemon_interface.syncFinished.connect(() => {
		        stdout.printf ("sync finished\n");
				m_window.updateFeedList();
				m_window.updateHeadlineList();
		        m_window.setRefreshButton(false);
		    });
		    
		    feedDaemon_interface.loginDialog.connect((ErrorCode) => {
		        stdout.printf ("show login dialog\n");
		        tryLogin(ErrorCode);
		    });
		}catch (IOError e) {
    		stderr.printf ("%s\n", e.message);
		}
		base.startup ();
	}
	
	protected override void activate ()
	{
		if (m_window == null)
		{
			m_window = new readerUI (this);
			m_window.set_icon_name ("internet-news-reader");
			tryLogin(LOGIN_FIRST_TRY);
		}
		
		m_window.show_all();
		updateBadge();
	}

	public void tryLogin(int ErrorCode)
	{
		stdout.printf("feedreader: trylogin\n");
		if(feedDaemon_interface.isLoggedIn() == LOGIN_SUCCESS)
		{
			getContent();
		}
		else
		{
			var dialog = new loginDialog(m_window, ErrorCode);
			dialog.submit_data.connect(() => {
				stdout.printf("initial sync\n");
				var status = feedDaemon_interface.login();
				tryLogin(status);
				GLib.Timeout.add_seconds_full(GLib.Priority.DEFAULT, 2, () => {
					sync();
					return false;
				});
			});
			dialog.show_all();
		}
	}

	private void getContent()
	{
		m_window.createFeedlist();
		m_window.createHeadlineList();
		
		dataBase.updateBadge.connect(updateBadge);
		
		GLib.Timeout.add_seconds_full(GLib.Priority.DEFAULT, 300, () => {
			sync();
			return true;
		});
	}
	
	private void updateBadge()
	{
		try{
			feedDaemon_interface.updateBadge();
		}catch (IOError e) {
    		stderr.printf ("%s\n", e.message);
		}
	}


	public void sync()
	{
		try{
			feedDaemon_interface.startSync();
		}catch (IOError e) {
    		stderr.printf ("%s\n", e.message);
		}
	}
	
	public void startDaemon()
	{
		string[] spawn_args = {"feedreader-daemon"};
		try{
			GLib.Process.spawn_async("/", spawn_args, null , GLib.SpawnFlags.SEARCH_PATH, null, null);
		}catch(GLib.SpawnError e){
			stdout.printf("error spawning command line: %s\n", e.message);
		}
	}

	public rssReaderApp () {
		GLib.Object (application_id: "org.gnome.FeedReader", flags: ApplicationFlags.FLAGS_NONE);
	}
}


public static int main (string[] args) {
	var app = new rssReaderApp();
	app.run(args);

	return 0;
}

