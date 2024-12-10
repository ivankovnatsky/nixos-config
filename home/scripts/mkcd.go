// mkcd.go
package main

import (
    "fmt"
    "os"
)

func main() {
    if len(os.Args) < 2 {
        fmt.Println("Usage: mkcd <directory-name>")
        os.Exit(1)
    }
    
    dir := os.Args[1]
    if err := os.MkdirAll(dir, 0755); err != nil {
        fmt.Printf("Error creating directory: %v\n", err)
        os.Exit(1)
    }
    
    // Print command to be evaluated by shell
    fmt.Printf("cd %q\n", dir)
}
