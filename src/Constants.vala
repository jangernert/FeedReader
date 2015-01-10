
// Backends
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
