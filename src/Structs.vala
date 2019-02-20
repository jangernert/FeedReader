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

namespace FeedReader {

	public struct BackendInfo {
		string ID;
		string name;
		BackendFlags flags;
		string website;
		string iconName;
	}

	public struct Response {
		uint status;
		string data;
		Soup.MessageHeaders headers;

		public bool is_ok()
		{
			return status >= 200 && status < 400;
		}
	}

	public struct ResourceMetadata
	{
		private const string CACHE_GROUP = "cache";
		private const string ETAG_KEY = "etag";
		private const string LAST_MODIFIED_KEY = "last_modified";
		private const string EXPIRES_KEY = "last_checked";

		string? etag;
		string? last_modified;
		DateTime? expires;

		public ResourceMetadata()
		{
		}

		public ResourceMetadata.from_data(string data)
		{
			try
			{
				var config = new KeyFile();
				config.load_from_data(data, data.length, KeyFileFlags.NONE);
				try { this.etag = config.get_string(CACHE_GROUP, ETAG_KEY); }
				catch (KeyFileError.KEY_NOT_FOUND e) {}
				catch (KeyFileError.GROUP_NOT_FOUND e) {}
				try { this.last_modified = config.get_string(CACHE_GROUP, LAST_MODIFIED_KEY); }
				catch (KeyFileError.KEY_NOT_FOUND e) {}
				catch (KeyFileError.GROUP_NOT_FOUND e) {}

				int64? expires = null;
				try { expires = config.get_int64(CACHE_GROUP, EXPIRES_KEY); }
				catch (KeyFileError.KEY_NOT_FOUND e) {}
				catch (KeyFileError.GROUP_NOT_FOUND e) {}
				if(expires != null)
				{
					this.expires = new DateTime.from_unix_utc(expires);
				}
			}
			catch (KeyFileError e)
			{
				Logger.warning(@"FaviconMetadata.from_file: Failed to load from $data");
			}
		}

		public static async ResourceMetadata from_file_async(string filename)
		{
			try
			{
				var file = File.new_for_path(filename);
				uint8[] contents;
				yield file.load_contents_async(null, out contents, null);
				return ResourceMetadata.from_data((string)contents);
			}
			catch (IOError.NOT_FOUND e)
			{
			}
			catch (Error e)
			{
				Logger.warning(@"FaviconMetadata.from_file: Failed to load $filename: " + e.message);
			}
			return ResourceMetadata();
		}

		public async void save_to_file_async(string filename)
		{
			var file = File.new_for_path(filename);
			if(this.etag == null && this.last_modified == null && this.expires == null)
			{
				try
				{
					yield file.delete_async();
				}
				catch (IOError.NOT_FOUND e)
				{
				}
				catch (Error e)
				{
					Logger.warning(@"FaviconMetadata.save_to_file: Error deleting metadata file $filename: " + e.message);
				}
			}
			else
			{
				var config = new KeyFile();
				if(this.etag != null)
				{
					config.set_string(CACHE_GROUP, ETAG_KEY, this.etag);
				}
				if(this.last_modified != null)
				{
					config.set_string(CACHE_GROUP, LAST_MODIFIED_KEY, this.last_modified);
				}
				if(this.expires != null)
				{
					config.set_int64(CACHE_GROUP, EXPIRES_KEY, this.expires.to_unix());
				}
				var data = config.to_data();
				try
				{
					try
					{
						file.get_parent().make_directory_with_parents();
					}
					catch (Error e)
					{
						// don't care if the folder already exists
					}
					yield file.replace_contents_async(data.data, null, false, FileCreateFlags.NONE, null, null);
				}
				catch (Error e)
				{
					Logger.warning(@"FaviconMetadata.save_to_file: Failed to save metadata file $filename,  $data:\n" + e.message);
				}
			}
		}

		public bool is_expired()
		{
			if(expires == null)
			{
				return true;
			}

			if(expires.compare(new DateTime.now_utc()) == 1)
			{
				return false;
			}

			return true;
		}
	}

}
