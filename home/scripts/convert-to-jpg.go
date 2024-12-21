package main

import (
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
)

const helpText = `convert-to-jpg - Convert images to JPG format in current directory

Usage: convert-to-jpg [--help]

Supported formats: HEIC, PNG, WEBP, TIFF, BMP

Uses optimal number of CPU cores for parallel processing
Original files are deleted after successful conversion
All metadata is stripped from converted JPG files`

func showHelp() {
	fmt.Println(helpText)
}

func convertFile(file string, wg *sync.WaitGroup, errorChan chan<- error) {
	defer wg.Done()

	// Generate output filename
	jpgFile := strings.TrimSuffix(file, filepath.Ext(file)) + ".jpg"

	// Convert image using ImageMagick
	cmd := exec.Command("magick", file, jpgFile)
	if err := cmd.Run(); err != nil {
		errorChan <- fmt.Errorf("error converting %s: %v", file, err)
		return
	}

	// Strip metadata using exiftool
	cmd = exec.Command("exiftool", "-all=", "-overwrite_original", jpgFile)
	if err := cmd.Run(); err != nil {
		errorChan <- fmt.Errorf("error stripping metadata from %s: %v", jpgFile, err)
		return
	}

	// Remove original file
	if err := os.Remove(file); err != nil {
		errorChan <- fmt.Errorf("error removing original file %s: %v", file, err)
		return
	}

	fmt.Printf("Converted, stripped metadata, and deleted: %s\n", file)
}

func main() {
	help := flag.Bool("help", false, "Show help message")
	flag.Parse()

	if *help {
		showHelp()
		return
	}

	// Calculate optimal number of workers (75% of CPU cores)
	numWorkers := int(float64(runtime.NumCPU()) * 0.75)
	if numWorkers < 1 {
		numWorkers = 1
	}

	fmt.Printf("Converting images using %d parallel jobs...\n", numWorkers)

	formats := []string{"HEIC", "PNG", "WEBP", "TIFF", "BMP"}
	var wg sync.WaitGroup
	errorChan := make(chan error, 100)

	// Process each format
	for _, format := range formats {
		// Find files with both upper and lowercase extensions
		pattern := fmt.Sprintf("*.%s", format)
		files, err := filepath.Glob(pattern)
		if err != nil {
			fmt.Printf("Error finding %s files: %v\n", format, err)
			continue
		}

		lowerPattern := fmt.Sprintf("*.%s", strings.ToLower(format))
		lowerFiles, err := filepath.Glob(lowerPattern)
		if err != nil {
			fmt.Printf("Error finding %s files: %v\n", strings.ToLower(format), err)
			continue
		}

		files = append(files, lowerFiles...)

		if len(files) > 0 {
			fmt.Printf("Converting %s files...\n", format)

			// Process files with worker pool
			semaphore := make(chan struct{}, numWorkers)
			for _, file := range files {
				wg.Add(1)
				semaphore <- struct{}{} // Acquire
				go func(f string) {
					convertFile(f, &wg, errorChan)
					<-semaphore // Release
				}(file)
			}
		}
	}

	// Wait for all conversions to complete
	go func() {
		wg.Wait()
		close(errorChan)
	}()

	// Print any errors that occurred
	for err := range errorChan {
		fmt.Fprintln(os.Stderr, err)
	}

	fmt.Println("Conversion complete!")
} 
