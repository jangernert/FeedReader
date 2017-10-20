const string user_env = "FEEDBIN_TEST_USER";
const string password_env = "FEEDBIN_TEST_PASSWORD";

void delete_subscription(FeedbinAPI api, string url)
{
    var subscriptions = api.get_subscriptions();
    foreach(var subscription in subscriptions)
    {
        if(subscription.feed_url != url)
            continue;
        api.delete_subscription(subscription.id);
        break;
    }
}

void add_login_tests()
{
    string? username = Environment.get_variable(user_env);
    string? password = Environment.get_variable(password_env);
    if(username == null || password == null)
		return;

	// Stick a random number at the end of Feed URL's to ensure that they're
	// unique, even if we run two tests against the same account
	uint nonce = Random.next_int();

    Test.add_data_func ("/feedbinapi/login", () => {

        var api = new FeedbinAPI(username, password);
        assert(api.login());

        api = new FeedbinAPI("wrong", "password");
        assert(!api.login());

        api.username = username;
        assert(!api.login());

        api.password = password;
        assert(api.login());
    });

    Test.add_data_func ("/feedbinapi/subscription", () => {
        if(username == null || password == null)
        {
            Test.skip(@"Need $user_env and $password_env set to run Feedbin tests");
            return;
        }

        var api = new FeedbinAPI(username, password);

        var url = "https://www.brendanlong.com/feeds/all.atom.xml?feedreader-test-subscribe-$nonce";
        delete_subscription(api, url);

        var subscription_id = api.add_subscription(url);
        assert(subscription_id != 0);

        var created_subscription = api.get_subscription(subscription_id);
        assert(created_subscription.id == subscription_id);

        bool found_subscription = false;
        foreach(var subscription in api.get_subscriptions())
        {
            if(subscription.id == subscription_id)
            {
                assert(subscription.feed_url == created_subscription.feed_url);
                found_subscription = true;
            }
        }
        assert(found_subscription);

        string title = "Rename test";
        api.rename_subscription(subscription_id, title);
        var renamed_subscription = api.get_subscription(subscription_id);
        assert(renamed_subscription.title == title);

        api.delete_subscription(subscription_id);
        foreach(var subscription in api.get_subscriptions())
        {
            assert(subscription.id != subscription_id);
            assert(subscription.feed_url != url);
        }
    });

    Test.add_data_func ("/feedbinapi/taggings", () => {
        if(username == null || password == null)
        {
            Test.skip(@"Need $user_env and $password_env set to run Feedbin tests");
            return;
        }

        var api = new FeedbinAPI(username, password);

        var url = @"https://www.brendanlong.com/feeds/all.atom.xml?feedreader-test-taggings-$nonce";
        delete_subscription(api, url);

        var subscription_id = api.add_subscription(url);
        assert(subscription_id != 0);

        var created_subscription = api.get_subscription(subscription_id);
        assert(created_subscription.id == subscription_id);

        // The subscription is new so it shouldn't have any taggings
        var taggings = api.get_taggings();
        foreach(var tagging in taggings)
        {
            assert(tagging.feed_id != created_subscription.feed_id);
        }

        string category = "Taggings Test";
        api.add_tagging(created_subscription.feed_id, category);

        // Check taggings
        int64? tagging_id = null;
        foreach(var tagging in api.get_taggings())
        {
            if(tagging.feed_id == created_subscription.feed_id)
            {
                assert(tagging.name == category);
                tagging_id = tagging.id;
                break;
            }
        }
        assert(tagging_id != null);

        // Delete the tag and verify that it's gone
        api.delete_tagging(tagging_id);
        foreach(var tagging in api.get_taggings())
        {
            assert(tagging.feed_id != created_subscription.feed_id);
		}

		// cleanup
		api.delete_subscription(subscription_id);
    });

    Test.add_data_func ("/feedbinapi/entries", () => {
        if(username == null || password == null)
        {
            Test.skip(@"Need $user_env and $password_env set to run Feedbin tests");
            return;
        }

        var api = new FeedbinAPI(username, password);

		// Note: This one shouldn't be deleted or recreated, since we want the entries to be available
        var url = "https://www.brendanlong.com/feeds/all.atom.xml?feed-reader-test-entries";

        var subscription_id = api.add_subscription(url);
        assert(subscription_id != 0);

        var subscription = api.get_subscription(subscription_id);
        assert(subscription.id == subscription_id);

        /* FIXME: Figure out why this next line is failing
        var entries = api.get_entries(1, false, null, subscription.feed_id);
        foreach(var entry in entries)
        {
            assert(entry.feed_id == subscription.feed_id);
        }

		assert(entries.size > 0);
		int i = Random.int_range(0, entries.size);
        var entry = entries.to_array()[i];
        var entry_ids = new Gee.ArrayList<int64?>();
        entry_ids.add(entry.id);

        // read status
        api.set_entries_read(entry_ids, true);
        var unread_entries = api.get_unread_entries();
        assert(!unread_entries.contains(entry.id));

        api.set_entries_read(entry_ids, false);
        unread_entries = api.get_unread_entries();
        assert(unread_entries.contains(entry.id));

        api.set_entries_read(entry_ids, true);
        unread_entries = api.get_unread_entries();
        assert(!unread_entries.contains(entry.id));

        // starred status
        api.set_entries_starred(entry_ids, true);
        var starred_entries = api.get_starred_entries();
        assert(starred_entries.contains(entry.id));

        api.set_entries_starred(entry_ids, false);
        starred_entries = api.get_starred_entries();
        assert(!starred_entries.contains(entry.id));

        api.set_entries_starred(entry_ids, true);
        starred_entries = api.get_starred_entries();
        assert(starred_entries.contains(entry.id));
        */
    });
}

void main(string[] args)
{
    Test.init(ref args);

    // Tests that don't need a login
    Test.add_data_func ("/feedbinapi/construct", () => {
        var api = new FeedbinAPI("user", "password");
        assert(api != null);
    });

    Test.add_data_func ("/feedbinapi/bad login", () => {
        var api = new FeedbinAPI("user", "password");

        assert(!api.login());
    });

    add_login_tests();

    Test.run ();
}
