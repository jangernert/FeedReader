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

public class FeedReader.CachedAction : GLib.Object {

private CachedActions m_action;
private string m_id;
private string m_argument;

public CachedAction(CachedActions action, string id, string argument) {
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

public CachedActions getType()
{
	return m_action;
}

public void setType(CachedActions action)
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

public CachedActions opposite()
{
	switch(m_action)
	{
	case CachedActions.MARK_READ:
		return CachedActions.MARK_UNREAD;
	case CachedActions.MARK_UNREAD:
		return CachedActions.MARK_READ;
	case CachedActions.MARK_STARRED:
		return CachedActions.MARK_UNSTARRED;
	case CachedActions.MARK_UNSTARRED:
		return CachedActions.MARK_STARRED;
	}

	return CachedActions.NONE;
}

public void print()
{
	Logger.debug("CachedAction: %s %s".printf(m_action.to_string(), m_id));
}
}
