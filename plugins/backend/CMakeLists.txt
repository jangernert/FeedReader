option(TTRSS "Enable Tiny Tiny RSS backend" ON)
option(OWNCLOUD "Enable ownCloud News backend" ON)
option(INOREADER "Enable InoReader backend" ON)
option(FEEDLY "Enable feedly backend" ON)
option(OLDREADER "Enable The Old Reader backend" ON)
option(LOCAL "Enable local RSS backend" ON)
option(FRESH "Enable FreshRSS backend" ON)
option(FEEDBIN "Enable Feedbin backend" ON)
option(FEEDHQ "Enable Feedbin backend" OFF)
option(BAZQUX "Enable Feedbin backend" OFF)

MESSAGE(STATUS "Backend TTRSS:	" ${TTRSS})
MESSAGE(STATUS "Backend OWNCLOUD:	" ${OWNCLOUD})
MESSAGE(STATUS "Backend INOREADER:	" ${INOREADER})
MESSAGE(STATUS "Backend FEEDLY:	" ${FEEDLY})
MESSAGE(STATUS "Backend OLDREADER:	" ${OLDREADER})
MESSAGE(STATUS "Backend LOCAL:	" ${LOCAL})
MESSAGE(STATUS "Backend FRESH:	" ${FRESH})
MESSAGE(STATUS "Backend FEEDBIN:	" ${FEEDBIN})
MESSAGE(STATUS "Backend FEEDHQ:	" ${FEEDHQ})
MESSAGE(STATUS "Backend BAZQUX:	" ${FEEDHQ})

add_subdirectory(test)

if(TTRSS)
	add_subdirectory(ttrss)
endif(TTRSS)

if(OWNCLOUD)
	add_subdirectory(owncloud)
endif(OWNCLOUD)

if(INOREADER)
	add_subdirectory(inoreader)
endif(INOREADER)

if(FEEDLY)
	add_subdirectory(feedly)
endif(FEEDLY)

if(OLDREADER)
	add_subdirectory(oldreader)
endif(OLDREADER)

if(LOCAL)
	add_subdirectory(local)
endif(LOCAL)

if(FRESH)
	add_subdirectory(fresh)
endif(FRESH)

if(FEEDBIN)
	add_subdirectory(feedbin)
endif(FEEDBIN)

if(FEEDHQ)
	add_subdirectory(feedhq)
endif(FEEDHQ)

if(BAZQUX)
	add_subdirectory(bazqux)
endif(BAZQUX)
