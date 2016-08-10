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

	public enum Backend {
		NONE = -1,
		TTRSS = 0,
		FEEDLY,
		OWNCLOUD,
		INOREADER
	}

	public enum OAuth {
		NONE,
		FEEDLY,
		READABILITY,
		INSTAPAPER,
		POCKET,
		MAIL
	}

	public enum LogLevel {
		OFF,
		ERROR,
		MORE,
		DEBUG
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
		TTRSS_API,
		OWNCLOUD_API,
		TTRSS_API_DISABLED,
		CA_ERROR,
		UNAUTHORIZED,
		UNKNOWN
	}

	public enum TTRSSSpecialID {
		ARCHIVED      = 0,
		STARRED       = -1,
		PUBLISHED     = -2,
		FRESH         = -3,
		ALL           = -4,
		RECENTLY_READ = -6
	}

	public enum OwnCloudType {
		FEED,
		FOLDER,
		STARRED,
		ALL
	}

	public enum ArticleStatus {
		READ = 8,
		UNREAD,
		UNMARKED,
		MARKED,
		TOGGLE,
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
		ALL_EMPTY,
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

	public enum OfflineActions {
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

	public enum InoSubscriptionAction {
		EDIT,
		SUBSCRIBE,
		UNSUBSCRIBE
	}

	namespace TagID {
		const string NEW = "blubb";
	}

	namespace InoReaderSecret {
		const string base_uri = "https://www.inoreader.com/reader/api/0/";
		const string apikey = "1000001058";
		const string apitoken = "a3LyhdTSKk_dcCygZUZBZenIO2SQcpzz";
	}

	namespace FeedlySecret {
		 const string base_uri        = "http://cloud.feedly.com";
		 const string apiClientId     = "boutroue";
		 const string apiClientSecret = "FE012EGICU4ZOBDRBEOVAJA1JZYH";
		 const string apiRedirectUri  = "http://localhost";
		 const string apiAuthScope    = "https://cloud.feedly.com/subscriptions";
	}

	namespace ReadabilitySecrets {
		const string base_uri			= "https://www.readability.com/api/rest/v1/";
		const string oauth_consumer_key		= "jangernert";
		const string oauth_consumer_secret	= "3NSxqNW5d6zVwvZV6tskzVrqctHZceHr";
		const string oauth_callback			= "feedreader://readability";
	}

	namespace InstapaperSecrets {
		const string base_uri			= "https://www.instapaper.com/api/";
		const string oauth_consumer_key		= "b7681e07bf554b15813511217054e1b2";
		const string oauth_consumer_secret	= "c5307cb359d54685904f6d38aaeede6f";
		const string oauth_callback			= "feedreader://instapaper";
	}

	namespace PocketSecrets {
		const string base_uri			= "https://getpocket.com/v3/";
		const string oauth_consumer_key		= "43273-30a11c29b5eeabfa905df168";
		const string oauth_callback			= "feedreader://pocket";
	}

	namespace AboutInfo {
		 const string programmName  = _("FeedReader");
		 const string copyright     = "Copyright © 2014 Jan Lukas Gernert";
		 const string version       = "1.7-dev";
		 const string comments      = _("Desktop Client for various RSS Services");
		 const string[] authors     = { "Jan Lukas Gernert", "Bilal Elmoussaoui", null };
		 const string[] documenters = { "nobody", null };
		 const string[] artists     = {"Jan Lukas Gernert", "Harvey Cabaguio", "Jorge Marques", "Andrew Joyce", null};
		 const string iconName      = "feedreader";
		 const string translators   = _("translator-credits");
		 const string website       = "http://jangernert.github.io/FeedReader/";
		 const string websiteLabel  = _("FeedReader Website");
	}

	namespace Menu {
		const string about = _("About");
		const string settings = _("Settings");
		const string reset = _("Change Account");
		const string quit = _("Quit");
		const string bugs = _("Report a bug");
		const string bounty = _("Bounties");
		const string shortcuts = _("Shortcuts");
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

	public enum ArticleTheme {
		DEFAULT,
		SPRING,
		MIDNIGHT,
		PARCHMENT
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
		SPACER,
		SEPERATOR,
		CATEGORY,
		FEED,
		HEADLINE,
		TAG
	}

	public enum FeedListSort {
		RECEIVED,
		ALPHABETICAL
	}

	namespace CategoryID {
		 const string NONE          = "-99";
		 const string TTRSS_SPECIAL = "-1";
		 const string MASTER        = "-2";
		 const string TAGS          = "-3";
		 const string NEW			= "-4";
	}

	namespace FeedID {
		const string SEPARATOR = "-5";
		const string ALL = "-4";
		const string CATEGORIES = "-2";
	}

	const int DBusAPIVersion = 16;

	// tango colors
	const string[] COLORS = {
								"#edd400", // butter medium
								"#f57900", // orange medium
								"#c17d11", // chocolate medium
								"#73d216", // chameleon medium
								"#3465a4", // sky blue medium
								"#75507b", // plum medium
								"#cc0000", // scarlet red medium
								"#d3d7cf", // aluminium medium

								"#fce94f", // butter light
								"#fcaf3e", // orange light
								"#e9b96e", // chocolate light
								"#8ae234", // chameleon light
								"#729fcf", // sky blue light
								"#ad7fa8", // plum light
								"#ef2929", // scarlet red light
								"#eeeeec", // aluminium light

								"#c4a000", // butter dark
								"#ce5c00", // orange dark
								"#8f5902", // chocolate dark
								"#4e9a06", // chameleon dark
								"#204a87", // sky blue dark
								"#5c3566", // plum dark
								"#a40000", // scarlet red dark
								"#babdb6"  // aluminium dark
							};
}
