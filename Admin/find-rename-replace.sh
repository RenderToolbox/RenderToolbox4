#! /bin/bash
# Helper script to rename m-files, and their occrrences as functions, throughout a project.

# replace what with what?
DIR=$1
FIND=$2
REPLACE=$3
echo "Finding <$FIND> and replacing it with <$REPLACE>"

# rename the file itself -- assume .m extension
ORIGINAL=$(find "$DIR" -type f -name "$FIND.m")
if [ $ORIGINAL ]
then
  ORIGINAL_NAME=$(basename $ORIGINAL)
  ORIGINAL_PATH=$(dirname $ORIGINAL)
  NEW=$ORIGINAL_PATH/$REPLACE.m
  echo "Renaming <$ORIGINAL> -> <$NEW>"
  mv $ORIGINAL $NEW
else
  echo "Not found."
  #exit
fi

# find and change occurrences as whole words
OCCURRENCES=$(grep -rl --include="*.m" "\b$FIND\b" "$DIR")
if [ -n "$OCCURRENCES" ]
then
  COUNT=$(echo "$OCCURRENCES" | wc -l )
  echo "Replacing Occurrences in $COUNT files:"
  echo "$OCCURRENCES"
  echo "$OCCURRENCES" | xargs sed -i "s/\b$FIND\b/$REPLACE/g"
else
  echo "No occurrences."
  exit
fi

echo "Done."

