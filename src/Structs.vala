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

    public struct Response {
        uint status;
        string data;
    }

    private struct ResourceMetadata
	{
		private const string CACHE_GROUP = "cache";
		private const string ETAG_KEY = "etag";
		private const string LAST_MODIFIED_KEY = "last_modified";

		string? etag;
		string? last_modified;

		public ResourceMetadata()
		{
		}

		public ResourceMetadata.from_file(string filename)
		{
			var config = new KeyFile();
			try
			{
				config.load_from_file(filename, KeyFileFlags.NONE);
				try { this.etag = config.get_string(CACHE_GROUP, ETAG_KEY); }
				catch (KeyFileError.KEY_NOT_FOUND e) {}
				catch (KeyFileError.GROUP_NOT_FOUND e) {}
				try { this.last_modified = config.get_string(CACHE_GROUP, LAST_MODIFIED_KEY); }
				catch (KeyFileError.KEY_NOT_FOUND e) {}
				catch (KeyFileError.GROUP_NOT_FOUND e) {}
			}
			catch (KeyFileError e)
			{
				Logger.warning(@"FaviconMetadata.from_file: Failed to load $filename: " + e.message);
			}
			catch (FileError e)
			{
				Logger.warning(@"FaviconMetadata.from_file: Failed to load $filename: " + e.message);
			}
		}

		public void save_to_file(string filename)
		{
			if(this.etag == null && this.last_modified == null)
			{
				if(FileUtils.unlink(filename) != 0)
					Logger.warning(@"FaviconMetadata.save_to_file: Error deleting metadata file $filename");
			}
			else
			{
				var config = new KeyFile();
				config.set_string(CACHE_GROUP, ETAG_KEY, this.etag);
				config.set_string(CACHE_GROUP, LAST_MODIFIED_KEY, this.last_modified);
				try
				{
					config.save_to_file(filename);
				}
				catch (FileError e)
				{
					Logger.warning(@"FaviconMetadata.save_to_file: Failed to save metadata file $filename: " + e.message);
				}
			}
		}
	}

}
