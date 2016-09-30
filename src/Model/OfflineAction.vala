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

	private OfflineActions m_action;
	private string m_id;
	private string m_argument;

	public OfflineAction(OfflineActions action, string id, string argument) {
		m_action = action;
		m_id = id;
		m_argument = argument;
	}

	public string getID()
	{
		return m_id;
	}

	public void setID(string id)
	{
		m_id = id;
	}

	public OfflineActions getType()
	{
		return m_action;
	}

	public void setType(OfflineActions action)
	{
		m_action = action;
	}

	public string getArgument()
	{
		return m_argument;
	}

	public void setArgument(string argument)
	{
		m_argument = argument;
	}

	public OfflineActions opposite()
	{
		switch(m_action)
		{
			case OfflineActions.MARK_READ:
				return OfflineActions.MARK_UNREAD;
			case OfflineActions.MARK_UNREAD:
				return OfflineActions.MARK_READ;
			case OfflineActions.MARK_STARRED:
				return OfflineActions.MARK_UNSTARRED;
			case OfflineActions.MARK_UNSTARRED:
				return OfflineActions.MARK_STARRED;
		}

		return OfflineActions.NONE;
	}

	public void print()
	{
		logger.print(LogMessage.DEBUG, "OfflineAction: %s %s".printf(m_action.to_string(), m_id));
	}
}
