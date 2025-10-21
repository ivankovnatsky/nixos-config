#!/usr/bin/env nu

# FIXME: `kn top pods` is not handled correctly.
def main [...args] {
    let output = kubectl ...$args | complete | get stdout | lines
    
    # Check if output is empty
    if ($output | is-empty) {
        print "No resources found"
        return
    }
    
    # Check if the output contains "No resources found"
    if ($output | first | str contains "No resources found") {
        print ($output | first)
        return
    }
    
    # Check if the output looks like a table (has multiple columns)
    let first_line = ($output | first)
    if not ($first_line | str contains "   ") {
        print $first_line
        return
    }
    
    let headers = ($first_line | split row -r '\s+')
    let first_column = ($headers | first)
    
    $output
    | skip 1
    | parse --regex ($headers | each {|h| '(\S+)\s*'} | str join "")
    | rename ...$headers
    | sort-by { |row| $row | get $first_column }
    | table
} 
