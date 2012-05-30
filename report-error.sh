# -*- mode: Shell-script-*-
#!/usr/bin/bash
#
# Author: Mario Fernandez
#
# Sends an email with the error message obtained from syncing a repository.

destination=${1?No destination provided}
project=${2?No project provided}
message=${3?No message provided}

cat > /tmp/git-sync-failure <<EOF
 The project $project could not be correctly synchronized. The output of the script was:

 $message
EOF

subject="Git-SVN failed for project $project"
mail -s "$subject" $destination < /tmp/git-sync-failure
