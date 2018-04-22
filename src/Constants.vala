//	This file is part of FeedReader.
//
//	FeedReader is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	FeedReader is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General public License for more details.
//
//	You should have received a copy of the GNU General public License
//	along with FeedReader.  If not, see <http://www.gnu.org/licenses/>.

namespace FeedReader {

	public class TagID : GLib.Object {
		public const string NEW = "blubb";
	}

	public class AboutInfo : GLib.Object {
		public const string programmName  = "FeedReader";
		public const string copyright     = "Copyright © 2014-2017 Jan Lukas Gernert";
		public const string version       = "@VERSION@";
		public const string comments      = N_("Desktop Client for various RSS Services");
		public const string[] authors     = { "Jan Lukas Gernert", "Bilal Elmoussaoui", "Anwesh Reddy" , "Jason Scurtu", null };
		public const string[] documenters = { "nobody", null };
		public const string[] artists     = {"Jan Lukas Gernert", "Harvey Cabaguio", "Jorge Marques", "Andrew Joyce", null};
		public const string iconName      = "org.gnome.FeedReader";
		public const string translators   = N_("translator-credits");
		public const string website       = "http://jangernert.github.io/FeedReader/";
	}

	public class Menu : GLib.Object {
		public const string about = _("About");
		public const string settings = _("Settings");
		public const string reset = _("Change Account");
		public const string quit = _("Quit");
		public const string bugs = _("Report a Bug");
		public const string bounty = _("Bounties");
		public const string shortcuts = _("Shortcuts");
	}

	public class MediaButton : GLib.Object {
		public const string PLAY = "Play";
		public const string PAUSE = "Pause";
		public const string MUTE = "Mute";
		public const string UNMUTE = "Unmute";
		public const string CLOSE = "Close";
	}

	public class Constants : GLib.Object {

		public const string INSTALL_PREFIX	= "@PREFIX@";
		public const string INSTALL_LIBDIR	= "@PKGLIBDIR@";
		public const string LOCALE_DIR 		= "@LOCALE_DIR@";
		public const string GIT_SHA1		= "@VCS_TAG@";
		public const string USER_AGENT		= "FeedReader @VERSION@";
		public const int DB_SCHEMA_VERSION  = 5;
		public const int REDOWNLOAD_FAVICONS_AFTER_DAYS = 7;

		// tango colors
		public const string[] COLORS = {
									"#edd400", // butter medium
									"#f57900", // orange medium
									"#c17d11", // chocolate medium
									"#73d216", // chameleon medium
									"#3465a4", // sky blue medium
									"#75507b", // plum medium
									"#cc0000", // scarlet red medium
									"#d3d7cf", // aluminium medium

									"#fce94f", // butter light
									"#fcaf3e", // orange light
									"#e9b96e", // chocolate light
									"#8ae234", // chameleon light
									"#729fcf", // sky blue light
									"#ad7fa8", // plum light
									"#ef2929", // scarlet red light
									"#eeeeec", // aluminium light

									"#c4a000", // butter dark
									"#ce5c00", // orange dark
									"#8f5902", // chocolate dark
									"#4e9a06", // chameleon dark
									"#204a87", // sky blue dark
									"#5c3566", // plum dark
									"#a40000", // scarlet red dark
									"#babdb6"  // aluminium dark
								};
	}
}
