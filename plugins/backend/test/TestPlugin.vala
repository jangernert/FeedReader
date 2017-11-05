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

namespace FeedReader.Tests {
	public void add_plugin_tests(FeedServerInterface plugin, string host, string username, string password) throws Error
	{
		var settings_backend = GLib.SettingsBackend.memory_settings_backend_new();
		var secret_service = Secret.Service.get_sync(Secret.ServiceFlags.NONE);
		var secrets = Secret.Collection.create_sync(secret_service, "feedreader_tests", null, Secret.CollectionCreateFlags.COLLECTION_CREATE_NONE);

		DataBase db_write = new DataBase.in_memory();
		DataBaseReadOnly db = new DataBaseReadOnly.in_memory();
		plugin.init(settings_backend, secrets, db, db_write);
	}
}
