// mkcd.go
package main

import (
	"fmt"
	"os"
	"strings"
)

const helpText = `mkcd - Make directory and change into it

Usage: mkcd <directory-name>

Arguments:
<directory-name>   Name of the directory to create and change into
                   Must not start with '-' or special characters

Options:
-h, --help         Show this help message`

func isValidDirName(name string) bool {
	if name == "" || strings.HasPrefix(name, "-") {
		return false
	}
	// Additional validation for special characters if needed
	// This is a basic check for common problematic characters
	invalidChars := []string{"|", "&", ";", "(", ")", "<", ">", "*", "?"}
	for _, char := range invalidChars {
		if strings.Contains(name, char) {
			return false
		}
	}
	return true
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: mkcd <directory-name>")
		os.Exit(1)
	}

	arg := os.Args[1]
	if arg == "-h" || arg == "--help" {
		fmt.Println(helpText)
		os.Exit(0)
	}

	if !isValidDirName(arg) {
		fmt.Println("Error: Invalid directory name. Directory name must not start with '-' or contain special characters")
		os.Exit(1)
	}

	if err := os.MkdirAll(arg, 0755); err != nil {
		fmt.Printf("Error creating directory: %v\n", err)
		os.Exit(1)
	}

	// Print command to be evaluated by shell
	fmt.Printf("cd %q\n", arg)
}
