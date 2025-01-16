#!/usr/bin/env fish

function print_help
    echo "Usage: open-gh-notifications [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  -r, --running     Open notifications in a running browser window"
    echo "  -s, --show        Just print the URLs script would open in the browser"
    echo "  -h, --help        Display this help message"
    echo ""
    echo "Examples:"
    echo "  open-gh-notifications"
    echo "  open-gh-notifications --running"
    echo "  open-gh-notifications --show"
    echo "  open-gh-notifications --running --show"
end

function collect_urls
    set -l type $argv[1]
    gh api notifications --paginate | jq -r ".[] | select(.subject.type == \"$type\") | .subject.url" | 
    string replace "api.github.com/repos" "github.com" |
    string replace "/pulls/" "/pull/"
end

function open_urls_in_batches
    set -l urls $argv[1..-2]
    set -l running $argv[-1]

    test (count $urls) -eq 0; and return

    if test "$running" = "true"
        printf "%s\n" $urls | parallel --jobs 10 "open {}"
    else
        # Open first URL in new window
        open -n $urls[1]
        # Process remaining URLs in parallel if any exist
        if test (count $urls) -gt 1
            printf "%s\n" $urls[2..-1] | parallel --jobs 10 "open {}"
        end
    end
end

function main
    argparse h/help r/running s/show -- $argv
    or begin
        print_help
        return 1
    end

    if set -q _flag_help
        print_help
        return 0
    end

    set -l issue_urls (collect_urls "Issue")
    set -l pr_urls (collect_urls "PullRequest")
    set -l all_urls $issue_urls $pr_urls

    if test (count $all_urls) -eq 0
        echo "No notifications found."
        return 0
    end

    # First print all URLs that were found
    echo "URLs to open:"
    printf "%s\n" $all_urls

    # Determine the mode (show vs open, and running vs new window)
    set -l action "Would open"
    set -l target "a new browser window"
    
    if set -q _flag_running
        set target "the current browser window"
    end
    
    if not set -q _flag_show
        set action "Opening"
        open_urls_in_batches $all_urls (test -n "$_flag_running")
    end
    
    echo "$action URLs in $target"
end

main $argv
