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
using Gee;

public class  FeedReader.ArticleTheme {
    private static ArrayList<HashMap<string, string>> ? themes = null;


    public static ArrayList<HashMap> getThemes(){
        if(themes == null){
            // Local themes
            themes = new ArrayList<HashMap<string, string>> ();
            string local_dir = GLib.Environment.get_user_data_dir() + "/feedreader/themes/";
            grabThemes(local_dir);
            // Global themes
            string global_dir = Constants.INSTALL_PREFIX + "/share/FeedReader/ArticleView/";
            grabThemes(global_dir);
        }
        return themes;
    }

    private static HashMap<string, string> getThemeInfo (string theme_path) {
      var themeInfo = new HashMap<string, string> ();
      bool corrupted_theme = true;
      string theme_name = "";
      string author = "";
      try {
        Dir theme_dir = Dir.open(theme_path, 0);
        string ? name = null;
        while ((name = theme_dir.read_name()) != null){
          if (name == "theme.json"){
              corrupted_theme = false;
              string path = Path.build_filename(theme_path, name);
              Json.Parser parser = new Json.Parser();
              try {
                parser.load_from_file(path);
                Json.Object obj = parser.get_root().get_object();

                Value val;
                foreach (unowned string nname in obj.get_members()){
                  val = obj.get_member(nname).get_value();
                  switch(nname) {
                    case "author":
                      author = (string) val;
                    break;
                    case "name":
                      theme_name = (string) val;
                    break;
                  }
                }
              }catch(Error err){
                corrupted_theme = true;
              }
          }
        }
      }catch(GLib.FileError err){

      }
      if (!corrupted_theme){
        themeInfo.set("name", theme_name);
        themeInfo.set("author", author);
        themeInfo.set("path", theme_path);
      } else {
        themeInfo.set("corrupted", "true");
      }
      return themeInfo;
    }

    public static void grabThemes(string location) {
      try{
          Dir dir = Dir.open(location, 0);
          string ? name = null;
          while ((name = dir.read_name()) != null){
            string path = Path.build_filename(location, name);
            if(FileUtils.test(path, FileTest.IS_DIR)){
              var themeInfo = getThemeInfo(path);
              if (themeInfo.has_key("corrupted") == false){
                themes.add(themeInfo);
              }
            }
          }
      } catch (GLib.FileError err){

      }
    }

    public static bool isExists(string theme_location){
      // Check wether a theme exists or not
      bool exists = true;
      try {
        Dir.open(theme_location, 0);
      } catch(GLib.FileError err) {
        exists = false;
      }
      return exists;
    }
}
