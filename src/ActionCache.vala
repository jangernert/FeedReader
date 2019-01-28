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

public class FeedReader.ActionCache : GLib.Object {

// Similar to CachedActionManager this class collects all the actions done during a period of time
// to use that information at a later point of time
// however this class does not write the actions to the database
// this class is used cache the actions during a sync so the synced data can be updated accordingly afterwards
// this prevents articles that were marked as read after the sync began but before the data was written to the database
// to suddenly become unread again after the sync (and similar issues)

private Gee.List<CachedAction> m_list;

private static ActionCache? m_cache = null;

public static ActionCache get_default()
{
	if(m_cache == null)
		m_cache = new ActionCache();

	return m_cache;
}

private ActionCache()
{
	m_list = new Gee.ArrayList<CachedAction>();
}

public void markArticleRead(string id, ArticleStatus read)
{
	var cachedAction = CachedActions.MARK_READ;
	if(read == ArticleStatus.UNREAD)
		cachedAction = CachedActions.MARK_UNREAD;

	var action = new CachedAction(cachedAction, id, "");
	addAction(action);
}

public void markArticleStarred(string id, ArticleStatus marked)
{
	var cachedAction = CachedActions.MARK_STARRED;
	if(marked == ArticleStatus.UNMARKED)
		cachedAction = CachedActions.MARK_UNSTARRED;

	var action = new CachedAction(cachedAction, id, "");
	addAction(action);
}

public void markFeedRead(string id)
{
	var action = new CachedAction(CachedActions.MARK_READ_FEED, id, "");
	addAction(action);
}

public void markCategoryRead(string id)
{
	var action = new CachedAction(CachedActions.MARK_READ_CATEGORY, id, "");
	addAction(action);
}

public void markAllRead()
{
	var action = new CachedAction(CachedActions.MARK_READ_ALL, "", "");
	addAction(action);
}

private void addAction(CachedAction action)
{
	switch(action.getType())
	{
	case CachedActions.MARK_READ:
	case CachedActions.MARK_UNREAD:
	case CachedActions.MARK_STARRED:
	case CachedActions.MARK_UNSTARRED:
		removeOpposite(action);
		break;

	case CachedActions.MARK_READ_FEED:
		removeForFeed(action.getID());
		break;

	case CachedActions.MARK_READ_CATEGORY:
		removeForCategory(action.getID());
		break;

	case CachedActions.MARK_READ_ALL:
		removeForALL();
		break;
	}

	m_list.add(action);
}

private void removeOpposite(CachedAction action)
{
	foreach(CachedAction a in m_list)
	{
		if(a.getID() == action.getID()
		   && a.getType() == action.opposite())
		{
			m_list.remove(a);
			break;
		}
	}
}

private void removeForFeed(string feedID)
{
	DataBaseReadOnly db = null;
	foreach(CachedAction a in m_list)
	{
		if(a.getType() == CachedActions.MARK_READ
		   || a.getType() == CachedActions.MARK_UNREAD)
		{
			if (db == null)
				db = DataBase.readOnly();
			if(feedID == db.getFeedIDofArticle(a.getID()))
			{
				m_list.remove(a);
			}
		}
	}
}

private void removeForCategory(string catID)
{
	var feedIDs = DataBase.readOnly().getFeedIDofCategorie(catID);
	foreach(string feedID in feedIDs)
	{
		foreach(CachedAction a in m_list)
		{
			if(a.getType() == CachedActions.MARK_READ_FEED
			   && a.getID() == feedID)
			{
				m_list.remove(a);
			}
		}

		removeForFeed(feedID);
	}
}

private void removeForALL()
{
	foreach(CachedAction a in m_list)
	{
		switch(a.getType())
		{
		case CachedActions.MARK_READ:
		case CachedActions.MARK_UNREAD:
		case CachedActions.MARK_READ_FEED:
		case CachedActions.MARK_READ_CATEGORY:
		case CachedActions.MARK_READ_ALL:
			m_list.remove(a);
			break;
		}
	}
}

public ArticleStatus checkStarred(string articleID, ArticleStatus marked)
{
	var type = CachedActions.NONE;
	if(marked == ArticleStatus.UNMARKED)
		type = CachedActions.MARK_STARRED;
	else if(marked == ArticleStatus.MARKED)
		type = CachedActions.MARK_UNSTARRED;

	foreach(CachedAction a in m_list)
	{
		if(a.getType() == type
		   && a.getID() == articleID)
		{
			if(type == CachedActions.MARK_STARRED)
				return ArticleStatus.MARKED;

			if(type == CachedActions.MARK_UNSTARRED)
				return ArticleStatus.UNMARKED;
		}
	}

	return marked;
}

public ArticleStatus checkRead(Article a)
{
	if(a.getUnread() == ArticleStatus.READ)
	{
		foreach(CachedAction action in m_list)
		{
			if(action.getType() == CachedActions.MARK_UNREAD
			   && action.getID() == a.getArticleID())
				return ArticleStatus.UNREAD;
		}
	}
	else if(a.getUnread() == ArticleStatus.UNREAD)
	{
		DataBaseReadOnly db = null;
		foreach(CachedAction action in m_list)
		{
			switch(action.getType())
			{
			case CachedActions.MARK_READ_ALL:
				return ArticleStatus.READ;

			case CachedActions.MARK_READ_FEED:
				if(action.getID() == a.getFeedID())
					return ArticleStatus.READ;
				break;

			case CachedActions.MARK_READ_CATEGORY:
				if (db == null)
					db = DataBase.readOnly();
				var feedIDs = db.getFeedIDofCategorie(a.getArticleID());
				foreach(string feedID in feedIDs)
				{
					if(feedID == a.getFeedID())
						return ArticleStatus.READ;
				}
				break;
			}
		}
	}

	return a.getUnread();
}
}
