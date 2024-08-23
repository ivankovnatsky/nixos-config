#!/usr/bin/env fish

function collect_urls
    set -l type $argv[1]
    set -l url_suffix $argv[2]

    gh api notifications --paginate | jq -r ".[] | select(.subject.type == \"$type\") | .subject.url" | while read -l url
        set -l data (gh api $url)
        set -l html_url (echo $data | jq -r '.html_url')
        echo "$html_url$url_suffix"
    end
end

function main
    set -l issue_urls (collect_urls "Issue" "")
    set -l pr_urls (collect_urls "PullRequest" "/files")

    set -l all_urls $issue_urls $pr_urls

    if test (count $all_urls) -eq 0
        echo "No notifications found."
        return
    end

    open -n -a Safari $all_urls
end

main
