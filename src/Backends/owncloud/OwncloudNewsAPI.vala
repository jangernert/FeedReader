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
		m_password = OwncloudNews_Utils.getPasswd();
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
        else if(error == ConnectionError.UNAUTHORIZED)
		{
			return LoginResponse.UNAUTHORIZED;
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

    public void getFeeds(Gee.LinkedList<feed> feeds)
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
                            hasIcon = OwncloudNews_Utils.downloadIcon(feed_id, feed_node.get_string_member("faviconLink"));
                        }

    					feeds.add(
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


    public void getCategories(Gee.LinkedList<category> categories, Gee.LinkedList<feed> feeds)
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

                        categories.add(
        					new category (
        						id,
        						folder_node.get_string_member("name"),
        						OwncloudNews_Utils.countUnread(feeds, id),
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


    public void getNewArticles(Gee.LinkedList<article> articles, int lastModified, OwnCloudType type = OwnCloudType.ALL, int id = 0)
	{
        string args = "";
        args += "lastModified=%i&".printf(lastModified);
        args += "type=%i&".printf(type);
        args += "id=%i".printf(id);

        logger.print(LogMessage.DEBUG, "/items/updated?" + args);

		var message = new OwnCloudNews_Message(m_OwnCloudURL + "/items/updated?" + args, m_username, m_password, "GET");
		int error = message.send();
        var response = message.get_response_object();
        if(response.has_member("items"))
        {
            var article_array = response.get_array_member("items");
            var article_count = article_array.get_length();
            logger.print(LogMessage.DEBUG, "%u articles returned".printf(article_count));

            for(uint i = 0; i < article_count; i++)
            {
                var article_node = article_array.get_object_element(i);
                //logger.print(LogMessage.DEBUG, article_node.get_int_member("id").to_string());

                ArticleStatus unread = article_node.get_boolean_member("unread") ? ArticleStatus.UNREAD : ArticleStatus.READ;
                ArticleStatus marked = article_node.get_boolean_member("starred") ? ArticleStatus.MARKED : ArticleStatus.UNMARKED;

                var Article = new article (	article_node.get_int_member("id").to_string(),
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
                        					article_node.get_string_member("guidHash"),
                                            (int)article_node.get_int_member("lastModified"));

                articles.add(Article);
            }
        }
    }



    public void getArticles(Gee.LinkedList<article> articles, int skip, int count, bool read = true, OwnCloudType type = OwnCloudType.ALL, int id = 0)
	{
        string args = "";
        args += "oldestFirst=false&";
        args += "type=%i&".printf(type);
        args += "getRead=%s&".printf(read ? "true" : "false");
        args += "id=%i&".printf(id);
        args += "offset=%i".printf(skip);
        args += "&batchSize=%i".printf(count);

        logger.print(LogMessage.DEBUG, "items?" + args);

        var message = new OwnCloudNews_Message(m_OwnCloudURL + "items?" + args, m_username, m_password, "GET");
		int error = message.send();
        var response = message.get_response_object();
        if(response.has_member("items"))
        {
            var article_array = response.get_array_member("items");
            var article_count = article_array.get_length();
            logger.print(LogMessage.DEBUG, "%u articles returned".printf(article_count));

            for(uint i = 0; i < article_count; i++)
            {
                var article_node = article_array.get_object_element(i);

                ArticleStatus unread = article_node.get_boolean_member("unread") ? ArticleStatus.UNREAD : ArticleStatus.READ;
                ArticleStatus marked = article_node.get_boolean_member("starred") ? ArticleStatus.MARKED : ArticleStatus.UNMARKED;

                var Article = new article (	article_node.get_int_member("id").to_string(),
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
                        					article_node.get_string_member("guidHash"),
                                            (int)article_node.get_int_member("lastModified"));

                articles.add(Article);
            }
        }
	}


	public bool markFeedRead(string feedID, bool isCatID)
	{
		string type = "";

		if(isCatID)
			type = "folders";
		else
			type = "feeds";

		string url = "%s/%s/read?newestItemId=%i".printf(type, feedID, int.parse(dataBase.getNewestArticle()));

		var message = new OwnCloudNews_Message(m_OwnCloudURL + url, m_username, m_password, "PUT");
		int error = message.send();

		return true;
	}

	public bool markAllItemsRead()
	{
        string url = "items/read?newestItemId=%i".printf(int.parse(dataBase.getNewestArticle()));
        var message = new OwnCloudNews_Message(m_OwnCloudURL + url, m_username, m_password, "PUT");
        int error = message.send();
		return true;
	}


	public bool updateArticleUnread(string articleIDs, ArticleStatus unread)
	{
		string url = "items/%s/".printf(articleIDs);

		if(unread == ArticleStatus.UNREAD)
			url += "unread";
		else if(unread == ArticleStatus.READ)
			url += "read";

		var message = new OwnCloudNews_Message(m_OwnCloudURL + url, m_username, m_password, "PUT");
		int error = message.send();

		return true;
	}


    public bool updateArticleMarked(string articleID, ArticleStatus marked)
	{
        var article = dataBase.read_article(articleID);
        string url = "/items/%s/%s/".printf(article.getFeedID(), article.getHash());

        if(marked == ArticleStatus.MARKED)
            url += "star";
        else if(marked == ArticleStatus.UNMARKED)
            url += "unstar";

        var message = new OwnCloudNews_Message(m_OwnCloudURL + url, m_username, m_password, "PUT");
        int error = message.send();

		return true;
	}

    public bool ping()
    {
        var message = new OwnCloudNews_Message(m_OwnCloudURL, m_username, m_password, "PUT");
        int error = message.send();
        
        if(error == ConnectionError.NO_RESPONSE)
		{
			return false;
		}

		return true;
    }
}
