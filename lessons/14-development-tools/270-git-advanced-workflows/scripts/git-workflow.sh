#!/bin/bash
# Advanced Git workflow automation script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MAIN_BRANCH="main"
DEVELOP_BRANCH="develop"
FEATURE_PREFIX="feature/"
RELEASE_PREFIX="release/"
HOTFIX_PREFIX="hotfix/"

# Utility functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a git repository"
        exit 1
    fi
}

# Get current branch
get_current_branch() {
    git symbolic-ref --short HEAD
}

# Check if branch exists
branch_exists() {
    git show-ref --verify --quiet refs/heads/$1
}

# Check if working directory is clean
is_working_directory_clean() {
    git diff-index --quiet HEAD --
}

# GitFlow initialization
gitflow_init() {
    log_info "Initializing GitFlow..."
    
    # Create develop branch if it doesn't exist
    if ! branch_exists $DEVELOP_BRANCH; then
        log_info "Creating develop branch"
        git checkout -b $DEVELOP_BRANCH $MAIN_BRANCH
        git push -u origin $DEVELOP_BRANCH
    fi
    
    log_success "GitFlow initialized"
}

# Start a new feature
feature_start() {
    local feature_name=$1
    
    if [[ -z $feature_name ]]; then
        log_error "Feature name is required"
        exit 1
    fi
    
    local feature_branch="${FEATURE_PREFIX}${feature_name}"
    
    # Check if feature branch already exists
    if branch_exists $feature_branch; then
        log_error "Feature branch '$feature_branch' already exists"
        exit 1
    fi
    
    # Switch to develop and pull latest changes
    log_info "Switching to develop branch"
    git checkout $DEVELOP_BRANCH
    git pull origin $DEVELOP_BRANCH
    
    # Create and switch to feature branch
    log_info "Creating feature branch '$feature_branch'"
    git checkout -b $feature_branch
    git push -u origin $feature_branch
    
    log_success "Feature '$feature_name' started"
    log_info "You can now work on your feature in branch '$feature_branch'"
}

# Finish a feature
feature_finish() {
    local current_branch=$(get_current_branch)
    
    # Check if we're on a feature branch
    if [[ ! $current_branch =~ ^${FEATURE_PREFIX} ]]; then
        log_error "Not on a feature branch"
        exit 1
    fi
    
    # Check if working directory is clean
    if ! is_working_directory_clean; then
        log_error "Working directory is not clean. Please commit or stash your changes"
        exit 1
    fi
    
    local feature_name=${current_branch#$FEATURE_PREFIX}
    
    log_info "Finishing feature '$feature_name'"
    
    # Push any remaining changes
    git push origin $current_branch
    
    # Switch to develop and pull latest changes
    git checkout $DEVELOP_BRANCH
    git pull origin $DEVELOP_BRANCH
    
    # Merge feature branch
    log_info "Merging feature branch into develop"
    git merge --no-ff $current_branch -m "Merge feature '$feature_name' into develop"
    
    # Push develop
    git push origin $DEVELOP_BRANCH
    
    # Delete feature branch
    log_info "Deleting feature branch"
    git branch -d $current_branch
    git push origin --delete $current_branch
    
    log_success "Feature '$feature_name' finished and merged into develop"
}

# Start a release
release_start() {
    local version=$1
    
    if [[ -z $version ]]; then
        log_error "Version is required"
        exit 1
    fi
    
    local release_branch="${RELEASE_PREFIX}${version}"
    
    # Check if release branch already exists
    if branch_exists $release_branch; then
        log_error "Release branch '$release_branch' already exists"
        exit 1
    fi
    
    # Switch to develop and pull latest changes
    log_info "Switching to develop branch"
    git checkout $DEVELOP_BRANCH
    git pull origin $DEVELOP_BRANCH
    
    # Create and switch to release branch
    log_info "Creating release branch '$release_branch'"
    git checkout -b $release_branch
    git push -u origin $release_branch
    
    log_success "Release '$version' started"
    log_info "You can now prepare the release in branch '$release_branch'"
}

# Finish a release
release_finish() {
    local current_branch=$(get_current_branch)
    
    # Check if we're on a release branch
    if [[ ! $current_branch =~ ^${RELEASE_PREFIX} ]]; then
        log_error "Not on a release branch"
        exit 1
    fi
    
    # Check if working directory is clean
    if ! is_working_directory_clean; then
        log_error "Working directory is not clean. Please commit or stash your changes"
        exit 1
    fi
    
    local version=${current_branch#$RELEASE_PREFIX}
    
    log_info "Finishing release '$version'"
    
    # Push any remaining changes
    git push origin $current_branch
    
    # Merge into main
    log_info "Merging release into main"
    git checkout $MAIN_BRANCH
    git pull origin $MAIN_BRANCH
    git merge --no-ff $current_branch -m "Merge release '$version' into main"
    
    # Create tag
    log_info "Creating tag 'v$version'"
    git tag -a "v$version" -m "Release version $version"
    
    # Merge back into develop
    log_info "Merging release into develop"
    git checkout $DEVELOP_BRANCH
    git pull origin $DEVELOP_BRANCH
    git merge --no-ff $current_branch -m "Merge release '$version' back into develop"
    
    # Push everything
    git push origin $MAIN_BRANCH
    git push origin $DEVELOP_BRANCH
    git push origin "v$version"
    
    # Delete release branch
    log_info "Deleting release branch"
    git branch -d $current_branch
    git push origin --delete $current_branch
    
    log_success "Release '$version' finished and tagged"
}

# Start a hotfix
hotfix_start() {
    local version=$1
    
    if [[ -z $version ]]; then
        log_error "Version is required"
        exit 1
    fi
    
    local hotfix_branch="${HOTFIX_PREFIX}${version}"
    
    # Check if hotfix branch already exists
    if branch_exists $hotfix_branch; then
        log_error "Hotfix branch '$hotfix_branch' already exists"
        exit 1
    fi
    
    # Switch to main and pull latest changes
    log_info "Switching to main branch"
    git checkout $MAIN_BRANCH
    git pull origin $MAIN_BRANCH
    
    # Create and switch to hotfix branch
    log_info "Creating hotfix branch '$hotfix_branch'"
    git checkout -b $hotfix_branch
    git push -u origin $hotfix_branch
    
    log_success "Hotfix '$version' started"
    log_info "You can now work on the hotfix in branch '$hotfix_branch'"
}

# Finish a hotfix
hotfix_finish() {
    local current_branch=$(get_current_branch)
    
    # Check if we're on a hotfix branch
    if [[ ! $current_branch =~ ^${HOTFIX_PREFIX} ]]; then
        log_error "Not on a hotfix branch"
        exit 1
    fi
    
    # Check if working directory is clean
    if ! is_working_directory_clean; then
        log_error "Working directory is not clean. Please commit or stash your changes"
        exit 1
    fi
    
    local version=${current_branch#$HOTFIX_PREFIX}
    
    log_info "Finishing hotfix '$version'"
    
    # Push any remaining changes
    git push origin $current_branch
    
    # Merge into main
    log_info "Merging hotfix into main"
    git checkout $MAIN_BRANCH
    git pull origin $MAIN_BRANCH
    git merge --no-ff $current_branch -m "Merge hotfix '$version' into main"
    
    # Create tag
    log_info "Creating tag 'v$version'"
    git tag -a "v$version" -m "Hotfix version $version"
    
    # Merge back into develop
    log_info "Merging hotfix into develop"
    git checkout $DEVELOP_BRANCH
    git pull origin $DEVELOP_BRANCH
    git merge --no-ff $current_branch -m "Merge hotfix '$version' back into develop"
    
    # Push everything
    git push origin $MAIN_BRANCH
    git push origin $DEVELOP_BRANCH
    git push origin "v$version"
    
    # Delete hotfix branch
    log_info "Deleting hotfix branch"
    git branch -d $current_branch
    git push origin --delete $current_branch
    
    log_success "Hotfix '$version' finished and tagged"
}

# Show current status
show_status() {
    log_info "Git Workflow Status"
    echo "===================="
    echo
    echo "Current branch: $(get_current_branch)"
    echo "Working directory: $(is_working_directory_clean && echo "Clean" || echo "Dirty")"
    echo
    echo "Recent commits:"
    git log --oneline -5
    echo
    echo "Branch list:"
    git branch -a
}

# Main script logic
main() {
    check_git_repo
    
    case "${1:-}" in
        init)
            gitflow_init
            ;;
        feature)
            case "${2:-}" in
                start)
                    feature_start "${3:-}"
                    ;;
                finish)
                    feature_finish
                    ;;
                *)
                    log_error "Usage: $0 feature {start|finish} [name]"
                    exit 1
                    ;;
            esac
            ;;
        release)
            case "${2:-}" in
                start)
                    release_start "${3:-}"
                    ;;
                finish)
                    release_finish
                    ;;
                *)
                    log_error "Usage: $0 release {start|finish} [version]"
                    exit 1
                    ;;
            esac
            ;;
        hotfix)
            case "${2:-}" in
                start)
                    hotfix_start "${3:-}"
                    ;;
                finish)
                    hotfix_finish
                    ;;
                *)
                    log_error "Usage: $0 hotfix {start|finish} [version]"
                    exit 1
                    ;;
            esac
            ;;
        status)
            show_status
            ;;
        *)
            echo "Git Advanced Workflow Manager"
            echo "============================="
            echo
            echo "Usage: $0 {init|feature|release|hotfix|status}"
            echo
            echo "Commands:"
            echo "  init                     Initialize GitFlow"
            echo "  feature start <name>     Start a new feature"
            echo "  feature finish           Finish current feature"
            echo "  release start <version>  Start a new release"
            echo "  release finish           Finish current release"
            echo "  hotfix start <version>   Start a new hotfix"
            echo "  hotfix finish            Finish current hotfix"
            echo "  status                   Show current status"
            echo
            echo "Examples:"
            echo "  $0 init"
            echo "  $0 feature start user-authentication"
            echo "  $0 feature finish"
            echo "  $0 release start 1.2.0"
            echo "  $0 release finish"
            echo "  $0 hotfix start 1.2.1"
            echo "  $0 hotfix finish"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
