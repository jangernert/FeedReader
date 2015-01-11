
// Backends
const int TYPE_NONE = -1;
const int TYPE_TTRSS = 0;
const int TYPE_FEEDLY = 1;
const int TYPE_OWNCLOUD = 2;


// TTRSS connection Errors
const int NO_ERROR = 0;
const int ERR_NO_RESPONSE = 1;
const int ERR_INVALID_SESSIONID = 2;
const int ERR_TTRSS_API = 3;
const int ERR_UNKNOWN = 4;


// TTRSS Special FeedID's
const int TTRSS_ID_ARCHIVED = 0;
const int TTRSS_ID_STARRED = -1;
const int TTRSS_ID_PUBLISHED = -2;
const int TTRSS_ID_FRESH = -3;
const int TTRSS_ID_ALL = -4;
const int TTRSS_ID_RECENTLY_READ = -6;

// TTRSS Article Status
const int STATUS_READ = 0;
const int STATUS_UNREAD = 1;
const int STATUS_UNMARKED = 0;
const int STATUS_MARKED = 1;
const int STATUS_TOGGLE = 2;


// Login Errors
const int LOGIN_SUCCESS = 0;
const int LOGIN_MISSING_USER = 1;
const int LOGIN_MISSING_PASSWD = 2;
const int LOGIN_MISSING_URL = 3;
const int LOGIN_ALL_EMPTY = 4;
const int LOGIN_UNKNOWN_ERROR = 5;
const int LOGIN_FIRST_TRY = 6;
const int LOGIN_NO_BACKEND = 7;


// Feedly Login Secrets
const string base_uri = "http://cloud.feedly.com";
const string apiClientId = "boutroue";
const string apiClientSecret = "FE012EGICU4ZOBDRBEOVAJA1JZYH";
const string apiRedirectUri = "http://localhost";
const string apiAuthScope = "https://cloud.feedly.com/subscriptions";
