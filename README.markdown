# _git_ SVN Sync

This repository is intended to provide synchronization between a
running SVN repository and _git_, so that we can get away from
subversion while the build jobs are ported.

## Workflow

The idea is to use pure _git_ exclusively. The subversion repository is
up to date and used to build artifacts and jars, but nobody is
expected to write to it except the _git_ sync client.

Therefore _git_ would be used both at client and server side. This is an
improvement over using git-svn because it allows to commit branches to
the server, and avoids rewriting history when commiting to svn, among
other things.

## Technical view

For every project in subversion, two _git_ repositories are created, the
server and the sync client.

### _git_ Server

It is a normal bare repository, which supports every git
operation. Every developer clones this repository and uses it
exclusively for the project.

When someone pushes changes to the master branch, a hook is run which
uses the sync client to bring the changes to subversion.

### _git_ Sync client

This is a repository which is a clone of the _git_ server. When the
post-receive hook at the server is activated, the following happens at
this client:

 * Changes are pulled from the server to the master branch.
 * The master branch is merged into a svn sync branch.
 * The changes are sent to subversion via git-svn.
 
This repository is not intended for developers to use. It rejects
every push and commit, and should only automatically sync with the
server.

### Maintaining consistency

The _git_ server and subversion should be in the same state at every
time. To guarantee this, the following conditions are required:

 * Only the _git_ sync client should ever send changes to
   subversion. The write access to svn should be restricted to the
   remote _git_ user.
 * Nobody except the build jobs in jenkins uses subversion directly
   anymore. Developers interact only with the _git_ server.
 * The _git_ sync client is never modified. It only pulls changes from
   the _git_ server (only fast-forward allowed).

The consistency is assured via hooks that are installed at the server
and sync client. Access to subversion has to be configured separately.

### Reporting

If something does not work correctly, a mail will be sent specifying
the project which had the problem and the registered error

## Setup

### Initial setup

The machine where the repositories are installed needs the following
environment variables (defined in its ~/.bashrc):

  * **GIT_SCRIPTS**: directory where the _git_ sync scripts are located
  * **GIT_BASE**: directory where the _git_ repositories are stored.
  * **GIT_SVN_SYNC_BASE**: directory where the sync repositories are stored.
  * **GIT_SVN_SYNC_BRANCH**: name of the branch that is synchronized
      with subversion.
      
This repository should be cloned in the directory **GIT_SCRIPTS**.      

### SVN User

Git needs to have write access to subversion.

### Git config

For the git user that will sync with svn

    git config --global user.email "the@email"
    git config --global user.name "Git User"
      
### New project

Each project in subversion can be initialized with the
install/git-repository-from-svn.sh script. It makes sure that the
initial setup is carried and that the hooks are activated.


