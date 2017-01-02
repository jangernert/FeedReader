#!/bin/sh
DOMAIN=FeedReader
BASEDIR=$(dirname $0)
OUTPUT_FILE=${BASEDIR}/po/${DOMAIN}.pot

echo "Extracting translatable strings... "

# Extract the strings from D source code. Since xgettext does not support D
# as a language we use Vala, which works reasonable well.
find ${BASEDIR}/ -name '*.vala' | xgettext \
  --output $OUTPUT_FILE \
  --files-from=- \
  --directory=$BASEDIR \
  --language=Vala \
  --keyword=C_:1c,2 \
  --from-code=utf-8
  --from-code=utf-8

xgettext \
  --join-existing \
  --output $OUTPUT_FILE \
  --default-domain=$DOMAIN \
  --package-name=$DOMAIN \
  --directory=$BASEDIR \
  --foreign-user \
  --language=Desktop \
  ${BASEDIR}/data/feedreader.desktop.in

xgettext \
  --join-existing \
  --output $OUTPUT_FILE \
  --default-domain=$DOMAIN \
  --package-name=$DOMAIN \
  --directory=$BASEDIR \
  --foreign-user \
  --language=Desktop \
  ${BASEDIR}/data/feedreader-autostart.desktop.in

xgettext \
  --join-existing \
  --output $OUTPUT_FILE \
  --default-domain=$DOMAIN \
  --package-name=$DOMAIN \
  --directory=$BASEDIR \
  --foreign-user \
  --language=appdata \
  ${BASEDIR}/data/feedreader.appdata.xml.in

# Merge the messages with existing po files
echo "Merging with existing translations... "
for file in ${BASEDIR}/po/*.po
do
  echo -n $file
  msgmerge --update $file $OUTPUT_FILE
done