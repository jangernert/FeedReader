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

namespace FeedReader {

	public enum FeedID {
		SEPARATOR = -77,
		ALL,
		CATEGORIES;

		public string to_string()
		{
 			return ((int)this).to_string();
 		}
	}

	public enum ArticleListState {
		ALL,
		UNREAD,
		MARKED
	}

	public enum DragTarget {
		TAG,
		FEED,
		CAT
	}

	public enum ConsoleColor {
		BLACK,
		RED,
		GREEN,
		YELLOW,
		BLUE,
		MAGENTA,
		CYAN,
		WHITE,
	}

	public enum LogMessage {
		ERROR,
		WARNING,
		INFO,
		DEBUG
	}

	public enum ConnectionError {
		SUCCESS,
		NO_RESPONSE,
		INVALID_SESSIONID,
		API_ERROR,
		API_DISABLED,
		CA_ERROR,
		UNAUTHORIZED,
		UNKNOWN
	}

	public enum ArticleStatus {
		READ = 8,
		UNREAD,
		UNMARKED,
		MARKED,
		ALL;

		public string to_string()
		{
			return ((int)this).to_string();
		}

		public int to_int()
		{
			return (int)this;
		}
	}

	public enum LoginResponse {
		SUCCESS,
		MISSING_USER,
		MISSING_PASSWD,
		MISSING_URL,
		INVALID_URL,
		ALL_EMPTY,
		API_ERROR,
		UNKNOWN_ERROR,
		FIRST_TRY,
		NO_BACKEND,
		WRONG_LOGIN,
		NO_CONNECTION,
		NO_API_ACCESS,
		UNAUTHORIZED,
		CA_ERROR,
		PLUGIN_NEEDED
	}

	public enum ArticleListSort {
		RECEIVED,
		DATE
	}

	public enum CachedActions {
		NONE,
		MARK_READ,
		MARK_UNREAD,
		MARK_STARRED,
		MARK_UNSTARRED,
		MARK_READ_FEED,
		MARK_READ_CATEGORY,
		MARK_READ_ALL
	}

	public enum MediaType {
		VIDEO,
		AUDIO
	}

	public enum DisplayPosition {
		ALL,
		POS,
		LEFT
	}

	public enum MouseButton {
		LEFT = 1,
		MIDDLE,
		RIGHT,
	}

	public enum QueryType {
		INSERT,
		INSERT_OR_IGNORE,
		INSERT_OR_REPLACE,
		UPDATE,
		SELECT,
		DELETE
	}

	public enum FeedListTheme {
		GTK,
		DARK,
		ELEMENTARY
	}

	public enum FontSize {
		SMALL,
		NORMAL,
		LARGE,
		HUGE
	}

	public enum DropArticles {
		NEVER,
		ONE_WEEK,
		ONE_MONTH,
		SIX_MONTHS
	}

	public enum FeedListType {
		ALL_FEEDS,
		CATEGORY,
		FEED,
		TAG
	}

	public enum FeedListSort {
		RECEIVED,
		ALPHABETICAL
	}

	public enum CategoryID {
		NONE = -99,
		MASTER = -2,
		TAGS = -3,
		NEW = -4;

		public string to_string()
		{
 			return ((int)this).to_string();
 		}
	}

	public enum ArticleListBalance {
		NONE,
		TOP,
		BOTTOM
	}

	public enum ScrollDirection {
		UP,
		DOWN
	}

	[Flags] public enum BackendFlags {
		LOCAL,
		HOSTED,
		SELF_HOSTED,
		FREE_SOFTWARE,
		PROPRIETARY,
		FREE,
		PAID_PREMIUM,
		PAID
	}
}
