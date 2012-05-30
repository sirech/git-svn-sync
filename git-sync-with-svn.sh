# -*- mode: Shell-script-*-
#!/usr/bin/bash
#
# Author: Mario Fernandez
#
# Syncs git repository with subversion, using an extra git client.
#
# The client is a clone of the git repo. It has two branches:
#  - master: It is sync'ed with the git repo. Should always
#            fast-forward.
#  - GIT_SVN_SYNC_BRANCH: Sync'ed with SVN (via git-svn). Noone else
#            can write to svn.
#
# The changes from the git repo are pulled into master, and then
# merged to the svn sync branch. This branch is then synchronized with
# subversion.
#
# Required environment variabless:
#  - GIT_SCRIPTS: directory where the git sync scripts are located
#  - GIT_SVN_SYNC_BASE: directory where the sync repositories are
# stored.
#  - GIT_SVN_SYNC_BRANCH: name of the branch that is synchronized with
# subversion.
#
# Usage: git-sync-with-svn.sh project_name

destination=receiver@host.com
project=${1?No project provided}
location=${GIT_SVN_SYNC_BASE}/${project}

if [ ! -d $location ] ; then
    echo "The folder where the synchronization repository is supposed to be does not exist"
    exit 1
fi

unset GIT_DIR
cd $location

report () {
    echo $1
    sh ${GIT_SCRIPTS}/report-error.sh $destination "$project" "$1"
}

# Get changes from git repository
echo "Getting changes from git repository"
git checkout master || { report "Could not switch to master" ; exit 1; }

if [ -n "$(git status --porcelain)" ] ; then
    echo "Workspace is dirty. Clean it up (i.e with git reset --hard HEAD) before continuing"
    exit 1
fi

git pull --ff-only origin master || { report "Could not pull changes from git repository" ; exit 1; }

# Synchronize with SVN
echo "Synchronizing with SVN"
git checkout ${GIT_SVN_SYNC_BRANCH} || { report "Could not switch to sync branch" ; exit 1; }
# In case of conflicts, take the master, as we are sure that this is
# the correct branch
git merge -Xtheirs master || { report "Could not merge changes into sync branch" ; exit 1; }
git svn dcommit || { report "Could not send changes to svn repository" ; exit 1; }
