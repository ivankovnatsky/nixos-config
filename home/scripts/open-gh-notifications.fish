#!/usr/bin/env fish

function print_help
    echo "Usage: open-gh-notifications [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  -s, --show        Just print the URLs script would open in the browser"
    echo "  -h, --help        Display this help message"
    echo ""
    echo "Examples:"
    echo "  open-gh-notifications"
    echo "  open-gh-notifications --show"
end

function collect_urls
    set -l type $argv[1]
    gh api notifications --paginate | jq -r ".[] | select(.subject.type == \"$type\") | .subject.url" |
        string replace "api.github.com/repos" "github.com" |
        string replace /pulls/ /pull/
end

function open_urls_in_batches
    set -l urls $argv[1..-1]

    test (count $urls) -eq 0; and return

    # Split URLs into issues and PRs
    set -l issue_urls
    set -l pr_urls
    for url in $urls
        if string match -q "*pull*" $url
            set -a pr_urls $url
        else
            set -a issue_urls $url
        end
    end

    # Open issues without /files
    printf "%s\n" $issue_urls | parallel --will-cite --jobs 10 "open {}"
    # Open PRs with /files
    printf "%s\n" $pr_urls | parallel --will-cite --jobs 10 "open {}/files"
end

function main
    argparse h/help s/show -- $argv
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

    # Determine the mode (show vs open)
    set -l action "Would open"
    set -l target "a new browser window"

    if not set -q _flag_show
        set action Opening
        open_urls_in_batches $all_urls
    end

    echo "$action URLs in $target"
end

main $argv
