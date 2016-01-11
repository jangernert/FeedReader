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

public class FeedReader.OfflineAction : GLib.Object {

	private OfflineAction m_action;
	private string m_id;
	private string m_argument;

	public OfflineAction(OfflineAction action, string id, string argument) {
		m_action = action;
		m_id = id;
		m_argument = argument;
	}

	public string getID()
	{
		return m_id;
	}

	public OfflineAction getAction()
	{
		return m_action;
	}

	public string getArgument()
	{
		return m_argument;
	}
}
