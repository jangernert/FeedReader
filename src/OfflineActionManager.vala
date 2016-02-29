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

public class FeedReader.OfflineActionManager : GLib.Object {

	private OfflineActions m_lastAction = OfflineActions.NONE;
	private string m_ids = "";

	public OfflineActionManager()
	{

	}


	public void markArticleRead(string id, ArticleStatus read)
	{
		var offlineAction = OfflineActions.MARK_READ;
		if(read == ArticleStatus.UNREAD)
			offlineAction = OfflineActions.MARK_UNREAD;

		var action = new OfflineAction(offlineAction, id, "");
		addAction(action);
	}

	public void markArticleStarred(string id, ArticleStatus marked)
	{
		var offlineAction = OfflineActions.MARK_STARRED;
		if(marked == ArticleStatus.UNMARKED)
			offlineAction = OfflineActions.MARK_UNSTARRED;

		var action = new OfflineAction(offlineAction, id, "");
		addAction(action);
	}

	public void markFeedRead(string id)
	{
		var action = new OfflineAction(OfflineActions.MARK_READ_FEED, id, "");
		addAction(action);
	}

	public void markCategoryRead(string id)
	{
		var action = new OfflineAction(OfflineActions.MARK_READ_CATEGORY, id, "");
		addAction(action);
	}

	public void markAllRead()
	{
		var action = new OfflineAction(OfflineActions.MARK_READ_ALL, "", "");
		addAction(action);
	}

	private void addAction(OfflineAction action)
	{
		if(dataBase.offlineActionNecessary(action))
		{
			dataBase.addOfflineAction(action.getType(), action.getID());
		}
		else
		{
			dataBase.deleteOppositeOfflineAction(action);
		}
	}

	public void goOnline()
	{
		if(dataBase.isTableEmpty("OfflineActions"))
			return;

		var actions = dataBase.readOfflineActions();

		foreach(OfflineAction action in actions)
		{
			logger.print(LogMessage.DEBUG, "OfflineActionManager: goOnline %s %s".printf(action.getID(), action.getType().to_string()));
			switch(action.getType())
			{
				case OfflineActions.MARK_READ:
				case OfflineActions.MARK_UNREAD:
				case OfflineActions.MARK_STARRED:
				case OfflineActions.MARK_UNSTARRED:
					if(action.getType() != m_lastAction && m_ids != "")
					{
						m_ids += action.getID();
						executeActions(m_ids.substring(1), m_lastAction);
						m_lastAction = OfflineActions.NONE;
						m_ids = "";
					}
					else
					{
						m_ids += "," + action.getID();
					}
					break;
				case OfflineActions.MARK_READ_FEED:
					server.setFeedRead(action.getID());
					break;
				case OfflineActions.MARK_READ_CATEGORY:
					server.setCategorieRead(action.getID());
					break;
				case OfflineActions.MARK_READ_ALL:
					server.markAllItemsRead();
					break;
			}

			m_lastAction = action.getType();
		}

		if(m_ids != "")
		{
			executeActions(m_ids.substring(1), m_lastAction);
		}

		dataBase.resetOfflineActions();
	}

	private void executeActions(string ids, OfflineActions action)
	{
		logger.print(LogMessage.DEBUG, "OfflineActionManager: executeActions %s %s".printf(ids, action.to_string()));
		switch(action)
		{
			case OfflineActions.MARK_READ:
				server.setArticleIsRead(ids, ArticleStatus.READ);
				break;
			case OfflineActions.MARK_UNREAD:
				server.setArticleIsRead(ids, ArticleStatus.UNREAD);
				break;
			case OfflineActions.MARK_STARRED:
				server.setArticleIsMarked(ids, ArticleStatus.MARKED);
				break;
			case OfflineActions.MARK_UNSTARRED:
				server.setArticleIsMarked(ids, ArticleStatus.UNMARKED);
				break;
		}
	}

}
