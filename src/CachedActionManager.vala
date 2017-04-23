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

public class FeedReader.CachedActionManager : GLib.Object {

	private CachedActions m_lastAction = CachedActions.NONE;
	private string m_ids = "";

	private static CachedActionManager? m_manager = null;

	public static CachedActionManager get_default()
	{
		if(m_manager == null)
			m_manager = new CachedActionManager();

		return m_manager;
	}

	private CachedActionManager()
	{

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
		if(dbDaemon.get_default().cachedActionNecessary(action))
		{
			dbDaemon.get_default().addCachedAction(action.getType(), action.getID());
		}
		else
		{
			dbDaemon.get_default().deleteOppositeCachedAction(action);
		}
	}

	public void executeActions()
	{
		if(dbDaemon.get_default().isTableEmpty("CachedActions"))
		{
			Logger.debug("CachedActionManager - executeActions: no actions to perform");
			return;
		}


		Logger.debug("CachedActionManager: executeActions");

		var actions = dbDaemon.get_default().readCachedActions();

		foreach(CachedAction action in actions)
		{
			Logger.debug("CachedActionManager: executeActions %s %s".printf(action.getID(), action.getType().to_string()));
			switch(action.getType())
			{
				case CachedActions.MARK_READ:
				case CachedActions.MARK_UNREAD:
					if(action.getType() != m_lastAction && m_ids != "")
					{
						m_ids += action.getID();
						execute(m_ids.substring(1), m_lastAction);
						m_lastAction = CachedActions.NONE;
						m_ids = "";
					}
					else
					{
						m_ids += "," + action.getID();
					}
					break;
				case CachedActions.MARK_STARRED:
					FeedServer.get_default().setArticleIsMarked(action.getID(), ArticleStatus.MARKED);
					break;
				case CachedActions.MARK_UNSTARRED:
					FeedServer.get_default().setArticleIsMarked(action.getID(), ArticleStatus.UNMARKED);
					break;
				case CachedActions.MARK_READ_FEED:
					FeedServer.get_default().setFeedRead(action.getID());
					break;
				case CachedActions.MARK_READ_CATEGORY:
					FeedServer.get_default().setCategorieRead(action.getID());
					break;
				case CachedActions.MARK_READ_ALL:
					FeedServer.get_default().markAllItemsRead();
					break;
			}

			m_lastAction = action.getType();
		}

		if(m_ids != "")
		{
			execute(m_ids.substring(1), m_lastAction);
		}

		dbDaemon.get_default().resetCachedActions();
	}

	private void execute(string ids, CachedActions action)
	{
		Logger.debug("CachedActionManager: execute %s %s".printf(ids, action.to_string()));
		switch(action)
		{
			case CachedActions.MARK_READ:
				FeedServer.get_default().setArticleIsRead(ids, ArticleStatus.READ);
				break;
			case CachedActions.MARK_UNREAD:
				FeedServer.get_default().setArticleIsRead(ids, ArticleStatus.UNREAD);
				break;
		}
	}

}
