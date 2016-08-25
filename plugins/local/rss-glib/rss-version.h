/* rss-version.h - RSS-GLib versioning information
 * 
 * This file is part of RSS-GLib.
 * Copyright (C) 2008  Christian Hergert <chris@dronelabs.com>
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *   Christian Hergert	<chris@dronelabs.com>
 */

#ifndef __RSS_VERSION_H__
#define __RSS_VERSION_H__

/**
 * SECTION:rss-version
 * @title: Versioning
 * @short_description: RSS-GLib version checking
 *
 * RSS-GLib provides macros to check the version of the library
 * at compile-time
 */

/**
 * RSS_MAJOR_VERSION:
 *
 * Rss major version component (e.g. 1 if %RSS_VERSION is 1.2.3)
 */
#define RSS_MAJOR_VERSION              (0)

/**
 * RSS_MINOR_VERSION:
 *
 * Rss minor version component (e.g. 2 if %RSS_VERSION is 1.2.3)
 */
#define RSS_MINOR_VERSION              (2)

/**
 * RSS_MICRO_VERSION:
 *
 * Rss micro version component (e.g. 3 if %RSS_VERSION is 1.2.3)
 */
#define RSS_MICRO_VERSION              (3)

/**
 * RSS_VERSION
 *
 * Rss version.
 */
#define RSS_VERSION                    (0.2.3)

/**
 * RSS_VERSION_S:
 *
 * Rss version, encoded as a string, useful for printing and
 * concatenation.
 */
#define RSS_VERSION_S                  "0.2.3"

/**
 * RSS_VERSION_HEX:
 *
 * Rss version, encoded as an hexadecimal number, useful for
 * integer comparisons.
 */
#define RSS_VERSION_HEX                (RSS_MAJOR_VERSION << 24 | \
                                        RSS_MINOR_VERSION << 16 | \
                                        RSS_MICRO_VERSION << 8)

/**
 * RSS_CHECK_VERSION:
 * @major: required major version
 * @minor: required minor version
 * @micro: required micro version
 *
 * Compile-time version checking. Evaluates to %TRUE if the version
 * of Rss is greater than the required one.
 */
#define RSS_CHECK_VERSION(major,minor,micro)                             \
        (RSS_MAJOR_VERSION > (major) ||                                  \
        (RSS_MAJOR_VERSION == (major) && RSS_MINOR_VERSION > (minor)) || \
        (RSS_MAJOR_VERSION == (major) && RSS_MINOR_VERSION == (minor) && \
         RSS_MICRO_VERSION >= (micro)))

#endif /* __RSS_VERSION_H__ */
