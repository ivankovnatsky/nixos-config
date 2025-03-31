#!/usr/bin/env fish

function show_help
    echo "convert-to-jpg - Convert images to JPG format in current directory"
    echo
    echo "Usage: convert-to-jpg [--help]"
    echo
    echo "Supported formats: HEIC, PNG, WEBP, TIFF, BMP"
    echo
    echo "Uses optimal number of CPU cores for parallel processing"
    echo "Original files are deleted after successful conversion"
    echo "All metadata is stripped from converted JPG files"
    return 0
end

if test (count $argv) -gt 0; and test "$argv[1]" = --help
    show_help
    exit 0
end

# Calculate optimal number of jobs (75% of CPU cores)
set -l cpu_cores (sysctl -n hw.ncpu)
set -l num_jobs (math "round($cpu_cores * 0.75)")

# Silence GNU Parallel citation notice
if not test -e ~/.parallel/will-cite
    mkdir -p ~/.parallel
    touch ~/.parallel/will-cite
end

# List of supported image formats
set formats HEIC PNG WEBP TIFF BMP

echo "Converting images using $num_jobs parallel jobs..."

for ext in $formats
    # Convert both uppercase and lowercase extensions
    set -l files (find . -maxdepth 1 -type f -iname "*.$ext")
    if test (count $files) -gt 0
        echo "Converting $ext files..."
        printf "%s\n" $files | parallel --bar -j $num_jobs "
            set jpg_file (echo {} | string replace -r '\.(HEIC|PNG|WEBP|TIFF|BMP)\$' '.jpg' -i)
            magick {} \"\$jpg_file\" && exiftool -all= -overwrite_original \"\$jpg_file\" && rm {} && echo \"Converted, stripped metadata, and deleted: {}\" || echo \"Error converting: {}\"
        "
    end
end

echo "Conversion complete!"
