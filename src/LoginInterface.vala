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

public interface FeedReader.LoginInterface : GLib.Object {

	public signal void login();

	public abstract Gtk.Stack m_stack { get; construct set; }
	public abstract Gtk.ListStore m_listStore { get; construct set; }
	public abstract Logger m_logger { get; construct set; }
	public abstract string m_installPrefix { get; construct set; }

	public abstract void init();

	public abstract bool needWebLogin();

	public abstract void showHtAccess();

	public abstract void writeData();

	public abstract string extractCode(string redirectURL);

	public abstract string buildLoginURL();

}
