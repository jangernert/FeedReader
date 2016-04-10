<?php
class Api_feedreader extends Plugin {
	private $host;
	private $dbh;

	function about()
	{
		return array(1.0,
			"API plugin for FeedReader",
			"JeanLuc",
			true
			);
	}
	
	function api_version()
	{
		return 2;
	}
	
	function init($host)
	{
		$this->host = $host;
		$this->dbh = $host->get_dbh();
		$this->host->add_api_method("addLabel", $this);
		$this->host->add_api_method("removeLabel", $this);
		$this->host->add_api_method("renameLabel", $this);
		$this->host->add_api_method("addCategory", $this);
		$this->host->add_api_method("removeCategory", $this);
		$this->host->add_api_method("renameCategory", $this);
		$this->host->add_api_method("renameFeed", $this);
	}
	
	function removeLabel()
	{
		$label_id = (int)db_escape_string($_REQUEST["label_id"]);
		if($label_id != "")
		{
			label_remove(feed_to_label_id($label_id), $_SESSION["uid"]);
			return array(API::STATUS_OK);
		}
		else
		{
			return array(API::STATUS_ERR, array("error" => 'INCORRECT_USAGE'));
		}
	}
	
	function addLabel()
	{
		$caption = db_escape_string($_REQUEST["caption"]);
		if($caption != "")
		{
			label_create($caption);
			$id = label_find_id($caption, $_SESSION["uid"]);
			return array(API::STATUS_OK, label_to_feed_id($id));
		}
		else
		{
			return array(API::STATUS_ERR, array("error" => 'INCORRECT_USAGE'));
		}
	}
	
	function renameLabel()
	{
		$caption = db_escape_string($_REQUEST["caption"]);
		$label_id = feed_to_label_id((int)db_escape_string($_REQUEST["label_id"]));
		
		if($label_id != "" && $caption != "")
		{
			$this->dbh->query("UPDATE ttrss_labels2 SET caption = '$caption' WHERE id = '$label_id' AND owner_uid = " . $_SESSION["uid"]);
			return array(API::STATUS_OK);
		}
		else
		{
			return array(API::STATUS_ERR, array("error" => 'INCORRECT_USAGE'));
		}
	}
	
	function removeCategory()
	{
		$category_id = (int)db_escape_string($_REQUEST["category_id"]);
		if($category_id != "")
		{
			$this->dbh->query("DELETE FROM ttrss_feed_categories WHERE id = '$category_id' AND owner_uid = ".$_SESSION["uid"]);
			ccache_remove($category_id, $_SESSION["uid"], true);
			return array(API::STATUS_OK);
		}
		else
		{
			return array(API::STATUS_ERR, array("error" => 'INCORRECT_USAGE'));
		}
	}
	
	function addCategory()
	{
		$caption = db_escape_string($_REQUEST["caption"]);
		if($caption != "")
		{
			add_feed_category($caption);
			return array(API::STATUS_OK, get_feed_category($caption));
		}
		else
		{
			return array(API::STATUS_ERR, array("error" => 'INCORRECT_USAGE'));
		}
	}
	
	function renameCategory() {
		$cat_id = (int)db_escape_string($_REQUEST["category_id"]);
		$caption = db_escape_string($_REQUEST["caption"]);

		if($caption != "")
		{
			$this->dbh->query("UPDATE ttrss_feed_categories SET title = '$caption' WHERE id = '$cat_id' AND owner_uid = " . $_SESSION["uid"]);
			return array(API::STATUS_OK);
		}
		else
		{
			return array(API::STATUS_ERR, array("error" => 'INCORRECT_USAGE'));
		}
	}
	
	function renameFeed() {
		$feed_id = (int)db_escape_string($_REQUEST["feed_id"]);
		$caption = db_escape_string($_REQUEST["caption"]);

		if($caption != "")
		{
			$this->dbh->query("UPDATE ttrss_feeds SET title = '$caption' WHERE id = '$feed_id' AND owner_uid = " . $_SESSION["uid"]);
			return array(API::STATUS_OK);
		}
		else
		{
			return array(API::STATUS_ERR, array("error" => 'INCORRECT_USAGE'));
		}
	}
}
?>
