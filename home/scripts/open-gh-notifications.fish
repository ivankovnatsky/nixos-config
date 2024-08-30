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

# BUG: When not opening PR itself, it does not get marked as viewed.
function get_latest_url
    set -l api_url $argv[1]
    set -l timeline_url (string replace "/pulls/" "/issues/" $api_url)
    set -l timeline_url (string replace -r '/issues/\d+$' '$0/timeline' $timeline_url)

    set -l latest_url (gh api $timeline_url --paginate | jq -r 'map(select(.html_url != null)) | last | .html_url') &
    wait

    if test -n "$latest_url" -a "$latest_url" != null
        echo $latest_url
    else
        # If no events with html_url, return the original issue/PR URL
        echo (string replace "api.github.com/repos" "github.com" (string replace "/pulls/" "/pull/" $api_url))
    end
end

function collect_urls
    set -l type $argv[1]

    begin
        gh api notifications --paginate | jq -r ".[] | select(.subject.type == \"$type\") | .subject.url" | while read -l url
            get_latest_url $url &
        end
        wait
    end &
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

    echo "URLs to open:"
    for url in $all_urls
        echo $url &
    end

    wait

    if set -q _flag_show
        if set -q _flag_running
            echo "Would open URLs in a new browser window (omit --show option to actually open)"
        else
            echo "Would open URLs in the current browser window (omit --show option to actually open)"
        end
    else
        if set -q _flag_running
            echo "Opening URLs in the current browser window"
            open -a $browser $all_urls
        else
            echo "Opening URLs in a new browser window"
            open --new -a $browser $all_urls
        end
    end
end

main $argv
