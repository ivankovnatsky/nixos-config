#!/usr/bin/env nu

# Clean up pod name by removing dynamic suffixes
def clean_pod_name [name: string] {
    $name
    | str replace -r '-[0-9a-f]+-[0-9a-z]+$' ''  # Remove hash suffixes
    | str replace -r '-[0-9]+$' ''                # Remove numeric suffixes
}

# Get pods in current namespace and count replicas
kubectl get pods
| lines
| skip 1                    # Skip header line
| each { |line|
    let parts = ($line | split row " " | where {|it| $it != ""})
    let name = (clean_pod_name $parts.0)
    {name: $name, replicas: 1}
}
| group-by name
| transpose name pods
| each { |entry|
    {name: $entry.name, replicas: ($entry.pods | length)}
}
| sort-by -r replicas
| table
