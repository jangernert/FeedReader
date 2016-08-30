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

public interface FeedReader.ShareAccountInterface : GLib.Object {

	public signal void addAccount(string id, string type, string username, string iconName, string accountName);

	public signal void deleteAccount(string id);

	public abstract Logger m_logger { get; construct set; }

	public abstract string pluginID();

	public abstract string pluginName();

	public abstract bool addBookmark(string id, string url);

	public abstract bool logout(string id);

	public abstract string getIconName();

	public abstract string getUsername(string id);

	public abstract bool needSetup();

	public abstract ServiceSetup? newSetup_withID(string id, string username);

	public abstract ServiceSetup? newSetup();

	//public abstract Gtk.Widget? shareWidget();
}
