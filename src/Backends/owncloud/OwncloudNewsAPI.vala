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

public class FeedReader.OwncloudNewsAPI : GLib.Object {

    private string m_OwnCloudURL;
	private string m_OwnCloudVersion;
	private Json.Parser m_parser;
    private string m_username;
    private string m_password;

    public OwncloudNewsAPI()
    {
        m_parser = new Json.Parser ();
    }

    public LoginResponse login()
    {
        logger.print(LogMessage.DEBUG, "OwnCloud: login");
        m_username = OwncloudNews_Utils.getUser();
		//passwd = OwncloudNews_Utils.getPasswd();
        m_password = "wissen";
		m_OwnCloudURL = OwncloudNews_Utils.getURL();

		if(m_OwnCloudURL == "" && m_username == "" && m_password == ""){
			m_OwnCloudURL = "example-host/owncloud";
			return LoginResponse.ALL_EMPTY;
		}
		if(m_OwnCloudURL == ""){
			return LoginResponse.MISSING_URL;
		}
		if(m_username == ""){
			return LoginResponse.MISSING_USER;
		}
		if(m_password == ""){
			return LoginResponse.MISSING_PASSWD;
		}

        var message = new OwnCloudNews_Message(m_OwnCloudURL + "status", m_username, m_password, "GET");
		int error = message.send();

        if(error == ConnectionError.SUCCESS)
		{
			var response = message.get_response_object();
			m_OwnCloudVersion = response.get_string_member("version");
			logger.print(LogMessage.INFO, "OwnCloud version: %s".printf(m_OwnCloudVersion));
			return LoginResponse.SUCCESS;
		}
		else if(error == ConnectionError.OWNCLOUD_API)
		{
			return LoginResponse.WRONG_LOGIN;
		}
		else if(error == ConnectionError.NO_RESPONSE)
		{
			return LoginResponse.NO_CONNECTION;
		}
        else if(error == ConnectionError.CA_ERROR)
        {
            return LoginResponse.CA_ERROR;
        }

        return LoginResponse.UNKNOWN_ERROR;
    }


    public bool isloggedin()
	{
        var message = new OwnCloudNews_Message(m_OwnCloudURL + "version", m_username, m_password, "GET");

		if(message.send() == ConnectionError.SUCCESS)
        {
            return true;
        }

		return false;
	}


    public bool supportTags()
	{
		return false;
	}

    public void getFeeds(ref GLib.List<feed> feeds)
	{
		if(isloggedin())
		{
			var message = new OwnCloudNews_Message(m_OwnCloudURL + "feeds", m_username, m_password, "GET");
			int error = message.send();

			if(error == ConnectionError.SUCCESS)
			{
				var response = message.get_response_object();
                if(response.has_member("feeds"))
                {
                    var feed_array = response.get_array_member("feeds");
                    var feed_count = feed_array.get_length();

                    for(uint i = 0; i < feed_count; i++)
    				{
    					var feed_node = feed_array.get_object_element(i);
    					string feed_id = feed_node.get_int_member("id").to_string();
                        bool hasIcon = false;

    					if(feed_node.has_member("faviconLink"))
                        {
    						OwncloudNews_Utils.downloadIcon(feed_id, feed_node.get_string_member("faviconLink"));
                            hasIcon = true;
                        }

    					feeds.append(
    						new feed (
    								feed_id,
    								feed_node.get_string_member("title"),
    								feed_node.get_string_member("link"),
    								hasIcon,
    								(int)feed_node.get_int_member("unreadCount"),
    								{ feed_node.get_int_member("folderId").to_string() }
    							)
    					);
    				}
                }
			}
		}
	}


    public void getCategories(ref GLib.List<category> categories, ref GLib.List<feed> feeds)
	{
		if(isloggedin())
		{
			var message = new OwnCloudNews_Message(m_OwnCloudURL + "folders", m_username, m_password, "GET");
			int error = message.send();
            int orderID = 0;

			if(error == ConnectionError.SUCCESS)
			{
				var response = message.get_response_object();

                if(response.has_member("folders"))
                {
                    var folder_array = response.get_array_member("folders");
                    var folder_count = folder_array.get_length();

                    for(uint i = 0; i < folder_count; i++)
    				{
                        ++orderID;
                        var folder_node = folder_array.get_object_element(i);
                        string id = folder_node.get_int_member("id").to_string();

                        categories.append(
        					new category (
        						id,
        						folder_node.get_string_member("name"),
        						OwncloudNews_Utils.countUnread(ref feeds, id),
        						orderID,
        						CategoryID.MASTER,
        						1
        					)
        				);
                    }
                }
			}
		}
	}


    public void getNewArticles(ref GLib.List<article> articles, int lastModified, OwnCloudType type = OwnCloudType.ALL, int id = 0)
	{
        string args = "";
        args += "lastModified=%i&".printf(lastModified);
        args += "type=%i&".printf(type);
        args += "id=%i".printf(id);

		var message = new OwnCloudNews_Message(m_OwnCloudURL + "items?" + args, m_username, m_password, "GET");
		int error = message.send();
        var response = message.get_response_object();
        if(response.has_member("items"))
        {
            var article_array = response.get_array_member("items");
            var article_count = article_array.get_length();

            for(uint i = 0; i < article_count; i++)
            {
                var article_node = article_array.get_object_element(i);

                ArticleStatus unread = article_node.get_boolean_member("unread") ? ArticleStatus.UNREAD : ArticleStatus.READ;
                ArticleStatus marked = article_node.get_boolean_member("starred") ? ArticleStatus.MARKED : ArticleStatus.UNMARKED;

                articles.append(
                    new article (	article_node.get_int_member("id").to_string(),
                					article_node.get_string_member("title"),
                					article_node.get_string_member("url"),
                					article_node.get_int_member("feedId").to_string(),
                					unread,
                					marked,
                					article_node.get_string_member("body"),
                					"",
                					article_node.get_string_member("author"),
                					new DateTime.from_unix_local(article_node.get_int_member("lastModified")),
                					-1,
                					"",
                					article_node.get_string_member("guidHash")
                                )
                );
            }
        }
    }



    public void getArticles(ref GLib.List<article> articles, int maxArticles, bool read = true, OwnCloudType type = OwnCloudType.ALL, int id = 0, int skip = 0, int limit = 200)
	{
        string args = "";
        args += "oldestFirst=false&";
        args += "type=%i&".printf(type);
        args += "getRead=%s&".printf(read ? "true" : "false");
        args += "id=%i&".printf(id);
        args += "offset=%i".printf(skip);

		if(maxArticles < limit)
            args += "batchSize=%i&".printf(maxArticles);
		else
            args += "batchSize=%i&".printf(limit);

        var message = new OwnCloudNews_Message(m_OwnCloudURL + "items?" + args, m_username, m_password, "GET");
		int error = message.send();
        var response = message.get_response_object();
        if(response.has_member("items"))
        {
            var article_array = response.get_array_member("items");
            var article_count = article_array.get_length();

            for(uint i = 0; i < article_count; i++)
            {
                var article_node = article_array.get_object_element(i);

                ArticleStatus unread = article_node.get_boolean_member("unread") ? ArticleStatus.UNREAD : ArticleStatus.READ;
                ArticleStatus marked = article_node.get_boolean_member("starred") ? ArticleStatus.MARKED : ArticleStatus.UNMARKED;

                articles.append(
                    new article (	article_node.get_int_member("id").to_string(),
                					article_node.get_string_member("title"),
                					article_node.get_string_member("url"),
                					article_node.get_int_member("feedId").to_string(),
                					unread,
                					marked,
                					article_node.get_string_member("body"),
                					"",
                					article_node.get_string_member("author"),
                					new DateTime.from_unix_local(article_node.get_int_member("lastModified")),
                					-1,
                					"",
                					article_node.get_string_member("guidHash")
                                )
                );
            }
        }
	}


    public bool markFeedRead(string feedID, bool isCatID)
	{
		bool return_value = false;

        if(isCatID)
        {

        }
        else
        {

        }

		return return_value;
	}


    public bool updateArticleUnread(string articleIDs, ArticleStatus unread)
	{
		bool return_value = false;
		return return_value;
	}


    public bool updateArticleMarked(int articleID, ArticleStatus marked)
	{
		bool return_value = false;
		return return_value;
	}
}
