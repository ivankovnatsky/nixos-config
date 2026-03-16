<?php
$uri = $_SERVER['REQUEST_URI'];
$path = parse_url($uri, PHP_URL_PATH);
$file = $_SERVER['DOCUMENT_ROOT'] . $path;

// Serve existing static files directly
if ($path !== '/' && is_file($file)) {
    return false;
}

// Route everything else through index.php (pretty URLs)
include $_SERVER['DOCUMENT_ROOT'] . '/index.php';
