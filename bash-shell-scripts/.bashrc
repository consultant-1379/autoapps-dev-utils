##################################################
# AutoApps .bashrc File
##################################################
# Git directory is relative to your home (~) directory. Update as necessary!
gitDirName="Git/autoapps"
signum=$(whoami)
##################################################
# Environment Variables
##################################################
export COMPOSE_CONVERT_WINDOWS_PATHS=1
##################################################
# Aliases
##################################################
alias c='clear;'
alias h='history'
alias l='ls -l'
alias lc='ls -C'
alias p='pwd -P' # shows the "real" path in bash, not the path via symlinks
alias q='exit'
# Git aliases
alias add='git add'
alias addall='git add -A'
alias amend='git commit --amend'
alias amendq='git commit --amend --no-edit'
alias branches='git branch -a'
alias checkoutall='checkout .'
alias diff='git diff --word-diff'
alias log='git log'
alias save='git stash save'
# Directory aliases
alias jee='cd testsuite/integration/jee/'
##################################################
# Functions
##################################################
# Prints out the authors of all commits within a repo
author(){
    if [[ "$#" -eq 0 ]]; then
        _author
    else
        _authorGrep | grep "$1"
    fi
}
# Delete untracked (new) files and directories from git repo
clean(){
    git clean -fd
}
# Prints a ranked list of the number of commiters per author
commiters(){
    _commiters | egrep -i "$1"
}
# Pushes code to Gerrit as a "draft". The review will not be visible to anyone watching the repo, and can only be seen by those added as reviewers.
draft(){
    git push origin HEAD:refs/drafts/master
}
# Add all unstages changes, amends the latest commit with new changes, and pushes to draft
# Should only be used when updating changes in an existing commit.
draftq(){
    addall &&
    amendq &&
    draft
}
# Shows the files changed in the last commit
lastcommit(){
    git show --name-only HEAD
}
# Add all unstages changes, amends the latest commit with new changes, and pushes to review
# Should only be used when updating changes in an existing commit
pushq(){
    addall &&
    amendq &&
    if [[ "$#" -eq 1 ]]; then
        reviewmaster "$1"
    else
        reviewmaster
    fi
}
# Pull latest code from remote branch
rebase(){
    git pull --rebase
}
# Reloads the .bashrc file into your terminal
reload(){
    source ~/.bashrc
}
# Reset local repo to remote branch
reset(){
    git reset --hard origin/master
}
# Pushes to review branch. You can optionally add a topic name after the alias to link multiple Gerrit commits to a single topic.
# For example, "reviewmaster dSONP-1234" will give your review a topic link of "dSONP-1234".
reviewmaster(){
    if [[ "$#" -eq 0 ]]; then
        git push origin HEAD:refs/for/master
    else
        git push origin HEAD:refs/for/master/"$1"
    fi
}
# Resets local repo to remote branch, then pull latest code
rrebase(){
    reset
    rebase
}
# Resets local repo to remote branch, then pull latest code
# Same as rrebase, I just keep typing this by accident
rreset(){
    rrebase
}
# Stashes local changes (if any), rebases repo, then pops the stashed changes
stash(){
    if [[ "$(basename "$(dirname "$PWD")")" == "$gitDirName" ]]; then
        _print ">>> Stashing $(basename $PWD) - Old status <<<\n"
        git status
        stashResult=$(git stash | xargs)
        if [[ "$stashResult" == "No local changes to save" ]]; then
            _print "\n>>> $(basename $PWD) has no changes to stash - Rebasing <<<\n"
            git pull --rebase
        else
            _print "\n>>> $(basename $PWD) stashed - Rebasing <<<\n"
            git pull --rebase
            _print "\n>>> $(basename $PWD) rebased - New status <<<\n"
            git stash pop -q
        fi
        git status
    else
        echo ">>> Not in git repo <<<"
        kill -SIGINT $$
    fi
}
# Clear all stashes in a repo
stashclear(){
    stashSize=$(stashes | wc -l | xargs)
    if [[ ! "$stashSize" -eq 0 ]]; then
        _print "Current stash count: $stashSize"
        git stash clear
        stashSize=$(stashes | wc -l | xargs)
        if [[ "$stashSize" -eq 0 ]]; then
            _print "Stashes cleared!"
        else
            _print ">>> Error clearing stashes! <<<";
        fi
    else
        _print "No stashes to clear!"
    fi
}
# List all stashes in a repo
stashes(){
    git stash list
}
# Get the status of the git repo
status(){
    git status "$@"
}
# Undoes the last commit, and moves the files back into staging
# Does NOT undo the changes on your local machine
uncommit(){
    git reset --soft HEAD^
}
# Resets a file back to master when conflicts occur
unconflict(){
    git reset HEAD "$@"
    git checkout -- "$@"
}
##################################################
# Docker Functions
##################################################
# Runs a dockerdown command on the current directory, then changes to the input directory's testsuite/integration/jee directory
# Example: 'dockerchange ~/git/data-loading-service-enm'
dockerchange(){
    dockerdown &&
    cd "$1"/testsuite/integration/jee &&
    dockerup
}
# Cleans all images using 'docker rmi' for images that have been untagged (are now tagged as '<none>')
dockercleannone(){
    noneImages=$(docker images | grep "<none>" | tr -s ' ' | cut -d ' ' -f 3)
    numberOfNoneImages=$(echo -n "${noneImages//[[:spaces]]/}" | wc -w)
    if [[ "$numberOfNoneImages" -eq 0 ]]; then
        _print "No '<none>' images to clean"
        kill -SIGINT $$
    fi
    docker rmi ${noneImages}
}
# Runs docker-compose down, and then runs a container prune command to clean up container data
dockerdown(){
    docker-compose down -v --remove-orphans &&
    dockerprune
}
# "Fixes" the issue with UNIX/Windows line endings for the pre-start.sh script for the postgres images
dockerfix(){
    if [[ "$#" -eq 0 ]]; then
        _sedclean src/test/docker/postgres/config/init/scripts/pre-start/pre-start.sh
    else
        _sedclean "$1"
    fi
}
# Executes a docker exec into a container matching either the input image name or container ID
dockerhook(){
    containerId=$(docker ps | grep "$1" | tr -s ' ' | cut -d ' ' -f1 | xargs)
    winpty docker exec -it "$containerId" bash
}
# Stops and removes one or many running containers
dockerkill(){
    if [[ "$#" -eq 0 ]]; then
        numberOfContainers=$(docker ps -a -q | wc -l)
        if [[ "$numberOfContainers" -eq 0 ]]; then
            _print "No containers to kill"
        else
            _print "Killing $numberOfContainers containers"
            dockerkill $(docker ps -a -q)
        fi
    else
        docker stop "$@" &&
        docker rm "$@"
    fi
}
# Executes a 'docker container prune' to remove all unused containers. Automatically passes in a 'yes' to the confirmation prompt
dockerprune(){
    yes | docker container prune
}
# Runs docker-compose up, with the --build param to rebuild images on each execution
# Also fixes the line endings for the pre-start.sh script for the postgres images
dockerup(){
    export COMPOSE_HTTP_TIMEOUT=600
    dockerfix &&
    docker-compose up --build
}
##################################################
# Maven Functions
##################################################
analyze(){
    mvn dependency:analyze
}
jdreport(){
    mvn javadoc:javadoc | grep WARNING | grep -v ".m2" | grep -v "Javadoc Warnings"
}
mdeploy(){
    mvn deploy -DskipTafTests "$@"
}
# Executes a 'mvn clean install'
minstall(){
    mvn clean install -DskipTafTests "$@"
}
# Executes a 'mvn clean install' using Java 8. Update JAVA_HOME as necessary!
minstall8(){
    JAVA_HOME=C:/"Program Files"/Java/jdk1.8.0_181 || kill -SIGINT $$
    mvn clean install -DskipTafTests "$@"
}
# Removes the cached dependencies in your .m2 folder
mpurge(){
    mvn dependency:purge-local-repository
}
# Executes the checkstyle plugin
style(){
    mvn checkstyle:checkstyle-aggregate
}
##################################################
# Private Functions (not to be used directly)
##################################################
# Horrendous one-liner from SO which prints all authors in the repo, and number of files changed
_author(){
    git log --shortstat --pretty="%cE" | sed 's/\(.*\)@.*/\1/' | grep -v "^$" | awk 'BEGIN { line=""; } !/^ / { if (line=="" || !match(line, $0)) {line = $0 "," line }} /^ / { print line " # " $0; line=""}' | sort | sed -E 's/# //;s/ files? changed,//;s/([0-9]+) ([0-9]+ deletion)/\1 0 insertions\(+\), \2/;s/\(\+\)$/\(\+\), 0 deletions\(-\)/;s/insertions?\(\+\), //;s/ deletions?\(-\)//' | awk 'BEGIN {name=""; files=0; insertions=0; deletions=0;} {if ($1 != name && name != "") { print name ": " files " files changed, " insertions " insertions(+), " deletions " deletions(-), " insertions-deletions " net"; files=0; insertions=0; deletions=0; name=$1; } name=$1; files+=$2; insertions+=$3; deletions+=$4} END {print name ": " files " files changed, " insertions " insertions(+), " deletions " deletions(-), " insertions-deletions " net";}'
}
# Greps the result of the _author call using egrep for case insensitivity
_authorGrep(){
    _author | egrep -i "$1" | xargs
}
# Function to handle execution cancellation (CTRL+C) - prints static failure message
_catchcancel(){
    if [[ ! $? -eq 0 ]]; then
        _print ">>> Execution cancelled by user <<<"
        kill -SIGINT $$
    fi
}
# Function to handle execution errors, and prints input success/failure messages
_catcherror(){
    if [[ $? -eq 0 ]]; then
        _print "$1"
    else
        _print ">>> $2 <<<"
        kill -SIGINT $$
    fi
}
# Prints a ranked list of the number of commiters per author. Filters out CI/Jenkins users
_commiters(){
    git shortlog -s -n | egrep -v ENM_CI_Admin\|"CI Admin"\|Jenkins\|unknown\|AP_Parent\|self-service
}
# Copies a specified file to a specified file path in a docker container
# Arguments:
#    1: The file path on your local machine
#    2:    The docker container's ID
#    3: The destination file location on the docker container
_copydocker(){
    if [[ "$#" -eq 0 ]]; then
        _print "Expected 3 input arguments\n#1: The file path on your machine\n#2: The docker container ID\n#3: The destination location on the docker container"
        kill -SIGINT $$
    fi
    docker cp "$1" "$2":"$3"
}
# Prints the input string with a blank line above and below
_print(){
    printf "\n$@\n"
}
# Removes Unix line endings from the file that's passed in, assuming the file exists
_sedclean(){
    if [[ -f "$1" ]]; then
        sed -i 's/\r$//' "$1"
    fi
}

##################################################
# Update AutoApps Repos
##################################################
updateAllRepos() {
    cd ~/${gitDirName}/
    if [[ $? != 0 ]]
    then
        echo "The following directory: ~/${gitDirName} does not exist."
        echo "Set/Check the gitDirname environment variable in your .bashrc file"
        exit 2
    fi
    echo "--- Start pulling the AutoApps repositories--- \n"
    find . -type d -name .git -exec sh -c "cd \"{}\"/../ && echo && pwd && git pull --rebase --autostash origin master" \;
    echo "--- Finished pulling the AutoApps repositories--- \n"
}