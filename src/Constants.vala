
// Backends
const int TYPE_NONE = -1;
const int TYPE_TTRSS = 0;
const int TYPE_FEEDLY = 1;
const int TYPE_OWNCLOUD = 2;


// TTRSS connection Errors
const int NO_ERROR = 3;
const int ERR_NO_RESPONSE = 4;
const int ERR_INVALID_SESSIONID = 5;
const int ERR_TTRSS_API = 6;
const int ERR_UNKNOWN = 7;


// TTRSS Special FeedID's
const int TTRSS_ID_ARCHIVED = 0;
const int TTRSS_ID_STARRED = -1;
const int TTRSS_ID_PUBLISHED = -2;
const int TTRSS_ID_FRESH = -3;
const int TTRSS_ID_ALL = -4;
const int TTRSS_ID_RECENTLY_READ = -6;

// TTRSS Article Status
const int STATUS_READ = 8;
const int STATUS_UNREAD = 9;
const int STATUS_UNMARKED = 10;
const int STATUS_MARKED = 11;
const int STATUS_TOGGLE = 12;


// Login Errors
const int LOGIN_SUCCESS = 13;
const int LOGIN_MISSING_USER = 14;
const int LOGIN_MISSING_PASSWD = 15;
const int LOGIN_MISSING_URL = 16;
const int LOGIN_ALL_EMPTY = 17;
const int LOGIN_UNKNOWN_ERROR = 18;
const int LOGIN_FIRST_TRY = 19;
const int LOGIN_NO_BACKEND = 20;


// Feedly Login Secrets
const string base_uri = "http://cloud.feedly.com";
const string apiClientId = "boutroue";
const string apiClientSecret = "FE012EGICU4ZOBDRBEOVAJA1JZYH";
const string apiRedirectUri = "http://localhost";
const string apiAuthScope = "https://cloud.feedly.com/subscriptions";

// database
const int DB_INSERT_OR_IGNORE = 21;
const int DB_INSERT_OR_REPLACE = 22;
const int DB_UPDATE_ROW = 23;

// feed list
const int FEEDLIST_ALL_FEEDS = 24;
const int FEEDLIST_SPACER = 25;
const int FEEDLIST_SEPERATOR = 26;
const int FEEDLIST_CATEGORY = 27;
const int FEEDLIST_FEED = 28;
const int FEEDLIST_HEADLINE = 29;
const int FEEDLIST_TAG = 30;

// special category ID's
const string CAT_ID_NONE = "-99";
const string CAT_ID_TTRSS_SPECIAL = "-1";
const string CAT_ID_MASTER = "-2";
const string FEEDID_ALL_FEEDS = "-3";
