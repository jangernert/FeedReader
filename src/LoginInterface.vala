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
	public signal void writeFeed(string url, string category);

	public abstract void init();

	public abstract string getWebsite();

	public abstract BackendFlags getFlags();

	public abstract string getID();

	public abstract Gtk.Box? getWidget();

	public abstract string iconName();

	public abstract string serviceName();

	public abstract bool needWebLogin();

	public abstract void showHtAccess();

	public abstract void writeData();

	public abstract void poastLoginAction();

	public abstract bool extractCode(string redirectURL);

	public abstract string buildLoginURL();

}
