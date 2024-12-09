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
    set -l batch_size 5
    
    for i in (seq 1 $batch_size (count $urls))
        set -l end_idx (math "$i + $batch_size - 1")
        if test $end_idx -gt (count $urls)
            set end_idx (count $urls)
        end
        
        # Process each URL in the batch individually
        for url in $urls[$i..$end_idx]
            if test "$running" = "true"
                open $url
            else
                open --new $url
            end
        end
        
        sleep 1
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

    echo "URLs to open:"
    printf "%s\n" $all_urls

    if set -q _flag_show
        if set -q _flag_running
            echo "Would open URLs in the current browser window (omit --show option to actually open)"
        else
            echo "Would open URLs in a new browser window (omit --show option to actually open)"
        end
    else
        if set -q _flag_running
            echo "Opening URLs in the current browser window"
            open_urls_in_batches $all_urls "true"
        else
            echo "Opening URLs in a new browser window"
            open_urls_in_batches $all_urls "false"
        end
    end
end

main $argv
