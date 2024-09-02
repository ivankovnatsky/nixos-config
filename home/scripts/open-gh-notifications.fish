#!/usr/bin/env fish

set -g browser Safari

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

function collect_actions_urls
    gh api notifications --paginate | jq -r ".[] | .repository.html_url + \"/actions\"" | sort -u
end

function main
    argparse h/help r/running s/show -- $argv
    or begin
        print_help
        return 1
    end

    if set -q \_flag_help
        print_help
        return 0
    end

    set -l issue_urls (collect_urls "Issue")
    set -l pr_urls (collect_urls "PullRequest")
    set -l actions_urls (collect_actions_urls)
    set -l all_urls $issue_urls $pr_urls $actions_urls

    if test (count $all_urls) -eq 0
        echo "No notifications found."
        return 0
    end

    echo "URLs to open:"
    printf "%s\n" $all_urls

    if set -q \_flag_show
        if set -q \_flag_running
            echo "Would open URLs in the current browser window (omit --show option to actually open)"
        else
            echo "Would open URLs in a new browser window (omit --show option to actually open)"
        end
    else
        if set -q \_flag_running
            echo "Opening URLs in the current browser window"
            open -a $browser $all_urls
        else
            echo "Opening URLs in a new browser window"
            open -n -a $browser $all_urls
        end
    end
end

main $argv
