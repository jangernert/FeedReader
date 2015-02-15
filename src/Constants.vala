namespace FeedReader {

	namespace Backend {
		const int NONE = -1;
		const int TTRSS = 0;
		const int FEEDLY = 1;
		const int OWNCLOUD = 2;
	}
	
	public enum LogLevel {
		OFF,
		ERROR,
		MORE,
		DEBUG
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

	namespace ConnectionError {
		const int SUCCESS = 3;
		const int NO_RESPONSE = 4;
		const int INVALID_SESSIONID = 5;
		const int TTRSS_API = 6;
		const int UNKNOWN = 7;
	}

	namespace TTRSSSpecialID {
		const int ARCHIVED = 0;
		const int STARRED = -1;
		const int PUBLISHED = -2;
		const int FRESH = -3;
		const int ALL = -4;
		const int RECENTLY_READ = -6;
	}

	namespace ArticleStatus {
		const int READ = 8;
		const int UNREAD = 9;
		const int UNMARKED = 10;
		const int MARKED = 11;
		const int TOGGLE = 12;
	}

	namespace LoginResponse {
		const int SUCCESS = 13;
		const int MISSING_USER = 14;
		const int MISSING_PASSWD = 15;
		const int MISSING_URL = 16;
		const int ALL_EMPTY = 17;
		const int UNKNOWN_ERROR = 18;
		const int FIRST_TRY = 19;
		const int NO_BACKEND = 20;
	}


	namespace FeedlySecret {
		const string base_uri = "http://cloud.feedly.com";
		const string apiClientId = "boutroue";
		const string apiClientSecret = "FE012EGICU4ZOBDRBEOVAJA1JZYH";
		const string apiRedirectUri = "http://localhost";
		const string apiAuthScope = "https://cloud.feedly.com/subscriptions";
	}

	namespace DataBase {
		const int INSERT_OR_IGNORE = 21;
		const int INSERT_OR_REPLACE = 22;
		const int UPDATE_ROW = 23;
	}

	namespace FeedList {
		const int ALL_FEEDS = 24;
		const int SPACER = 25;
		const int SEPERATOR = 26;
		const int CATEGORY = 27;
		const int FEED = 28;
		const int HEADLINE = 29;
		const int TAG = 30;
	}

	namespace CategoryID {
		const string NONE = "-99";
		const string TTRSS_SPECIAL = "-1";
		const string MASTER = "-2";
		const string TAGS = "-3";
	}
	
	namespace FeedID {
		const string ALL = "-4";
	}
					
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


