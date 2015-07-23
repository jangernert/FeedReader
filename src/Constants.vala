namespace FeedReader {

	public enum Backend {
		NONE = -1,
		TTRSS = 0,
		FEEDLY,
		OWNCLOUD
	}

	public enum OAuth {
		NONE,
		FEEDLY,
		READABILITY,
		INSTAPAPER,
		POCKET,
		EVERNOTE
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
		NO_CONNECTION
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

	namespace EvernoteSecrets {
		const string base_uri			= "https://sandbox.evernote.com/";
		const string oauth_consumer_key		= "eviltwin1125";
		const string oauth_consumer_secret	= "50ee4def493350c5";
		const string oauth_callback			= "feedreader://evernote";
	}

	namespace AboutInfo {
		 const string programmName  = _("FeedReader");
		 const string copyright     = "Copyright © 2014 Jan Lukas Gernert";
		 const string version       = "1.1 dev";
		 const string comments      = _("Desktop Client for various RSS Services");
		 const string[] authors     = { "Jan Lukas Gernert", null };
		 const string[] documenters = { "nobody", null };
		 const string[] artists     = {"Jan Lukas Gernert", "Harvey Cabaguio", "Jorge Marques", "Andrew Joyce", null};
		 const string iconName      = "internet-news-reader";
		 const string translators   = null;
		 const string website       = null;
		 const string websiteLabel  = null;
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

	public enum DropArticles {
		NEVER,
		ONE_WEEK,
		ONE_MONTH,
		SIX_MONTHS
	}

	public enum ContentGrabber {
		NONE,
		BUILTIN,
		READABILITY
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

	namespace CategoryID {
		 const string NONE          = "-99";
		 const string TTRSS_SPECIAL = "-1";
		 const string MASTER        = "-2";
		 const string TAGS          = "-3";
	}

	namespace FeedID {
		const string ALL = "-4";
		const string CATEGORIES = "-2";
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

	/*const StringPair[] htmlSpecial = {
								new StringPair("\n", " "),
								new StringPair("_", " "),
								new StringPair("&nbsp;", " "),
								new StringPair("&iexcl;", "¡"),
								new StringPair("&cent;", "¢"),
								new StringPair("&pound;", "£"),
								new StringPair("&curren;", "¤"),
								new StringPair("&yen;", "¥"),
								new StringPair("&brvbar;", "¦"),
								new StringPair("&sect;", "§"),
								new StringPair("&uml;", "¨"),
								new StringPair("&copy;", "©"),
								new StringPair("&ordf;", "ª"),
								new StringPair("&laquo;", "«"),
								new StringPair("&not;", "¬"),
								new StringPair("&shy;", " "),
								new StringPair("&reg;", "®"),
								new StringPair("&macr;", "¯"),
								new StringPair("&deg;", "°"),
								new StringPair("&plusmn;", "±"),
								new StringPair("&sup2;", "²"),
								new StringPair("&sup3;", "³"),
								new StringPair("&acute;", "´"),
								new StringPair("&micro;", "µ"),
								new StringPair("&para;", "¶"),
								new StringPair("&middot;", "·"),
								new StringPair("&cedil;", "¸"),
								new StringPair("&sup1;", "¹"),
								new StringPair("&ordm;", "º"),
								new StringPair("&raquo;", "»"),
								new StringPair("&frac14;", "¼"),
								new StringPair("&frac12;", "½"),
								new StringPair("&frac34;", "¾"),
								new StringPair("&iquest;", "¿"),
								new StringPair("&Agrave;", "À"),
								new StringPair("&Aacute;", "Á"),
								new StringPair("&Acirc;", "Â"),
								new StringPair("&Atilde;", "Ã"),
								new StringPair("&Auml;", "Ä"),
								new StringPair("&Aring;", "Å"),
								new StringPair("&AElig;", "Æ"),
								new StringPair("&Ccedil;", "Ç"),
								new StringPair("&Egrave;", "È"),
								new StringPair("&Eacute;", "É"),
								new StringPair("&Ecirc;", "Ê"),
								new StringPair("&Euml;", "Ë"),
								new StringPair("&Igrave;", "Ì"),
								new StringPair("&Iacute;", "Í"),
								new StringPair("&Icirc;", "Î"),
								new StringPair("&Iuml;", "Ï"),
								new StringPair("&ETH;", "Ð"),
								new StringPair("&Ntilde;", "Ñ"),
								new StringPair("&Ograve;", "Ò"),
								new StringPair("&Oacute;", "Ó"),
								new StringPair("&Ocirc;", "Ô"),
								new StringPair("&Otilde;", "Õ"),
								new StringPair("&Ouml;", "Ö"),
								new StringPair("&times;", "×"),
								new StringPair("&Oslash;", "Ø"),
								new StringPair("&Ugrave;", "Ù"),
								new StringPair("&Uacute;", "Ú"),
								new StringPair("&Ucirc;", "Û"),
								new StringPair("&Uuml;", "Ü"),
								new StringPair("&Yacute;", "Ý"),
								new StringPair("&THORN;", "Þ"),
								new StringPair("&szlig;", "ß"),
								new StringPair("&agrave;", "à"),
								new StringPair("&aacute;", "á"),
								new StringPair("&acirc;", "â"),
								new StringPair("&atilde;", "ã"),
								new StringPair("&auml;", "ä"),
								new StringPair("&aring;", "å"),
								new StringPair("&aelig;", "æ"),
								new StringPair("&ccedil;", "ç"),
								new StringPair("&egrave;", "è"),
								new StringPair("&eacute;", "é"),
								new StringPair("&ecirc;", "ê"),
								new StringPair("&euml;", "ë"),
								new StringPair("&igrave;", "ì"),
								new StringPair("&iacute;", "í"),
								new StringPair("&icirc;", "î"),
								new StringPair("&iuml;", "ï"),
								new StringPair("&eth;", "ð"),
								new StringPair("&ntilde;", "ñ"),
								new StringPair("&ograve;", "ò"),
								new StringPair("&oacute;", "ó"),
								new StringPair("&ocirc;", "ô"),
								new StringPair("&otilde;", "õ"),
								new StringPair("&ouml;", "ö"),
								new StringPair("&divide;", "÷"),
								new StringPair("&oslash;", "ø"),
								new StringPair("&ugrave;", "ù"),
								new StringPair("&uacute;", "ú"),
								new StringPair("&ucirc;", "û"),
								new StringPair("&uuml;", "ü"),
								new StringPair("&yacute;", "ý"),
								new StringPair("&thorn;", "þ"),
								new StringPair("&yuml;", "ÿ"),
								new StringPair("&OElig;", "Œ"),
								new StringPair("&oelig;", "œ"),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),
								new StringPair("", ""),

	};*/
}
