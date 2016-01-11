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

	public OfflineActionManager()
	{

	}


	public void markArticleRead(string id)
	{
		dataBase.addOfflineAction(OfflineActions.MARK_READ, id);
	}

	public void markArticleUnread(string id)
	{
		dataBase.addOfflineAction(OfflineActions.MARK_UNREAD, id);
	}

	public void markArticleStarred(string id)
	{
		dataBase.addOfflineAction(OfflineActions.MARK_STARRED, id);
	}

	public void markArticleUnstarred(string id)
	{
		dataBase.addOfflineAction(OfflineActions.MARK_UNSTARRED, id);
	}

	public void markFeedRead(string id)
	{
		dataBase.addOfflineAction(OfflineActions.MARK_READ_FEED, id);
	}

	public void markCategoryRead(string id)
	{
		dataBase.addOfflineAction(OfflineActions.MARK_READ_CATEGORY, id);
	}


	public void goOnline()
	{

		// empty TABLE

	}


}
