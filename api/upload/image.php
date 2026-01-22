<?php
require_once '../config.php';
// Optional: validateJWT(); // Enable to restrict uploads to logged in users

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['image'])) {
    $type = isset($_POST['type']) ? $_POST['type'] : 'threads'; // 'profiles' or 'threads'
    $targetDir = "../uploads/" . ($type === 'profiles' ? 'profiles/' : 'threads/');
    
    // Create directory if not exists
    if (!file_exists($targetDir)) {
        mkdir($targetDir, 0777, true);
    }
    
    $fileInfo = pathinfo($_FILES['image']['name']);
    $extension = $fileInfo['extension'];
    $newFilename = uniqid() . "." . $extension;
    $targetFile = $targetDir . $newFilename;
    
    if (move_uploaded_file($_FILES['image']['tmp_name'], $targetFile)) {
        http_response_code(200);
        // Return only the filename or relative path
        echo json_encode([
            "message" => "Image uploaded successfully",
            "filename" => $newFilename,
            "url" => "api/uploads/" . ($type === 'profiles' ? 'profiles/' : 'threads/') . $newFilename
        ]);
    } else {
        http_response_code(500);
        echo json_encode(["error" => "Failed to upload image"]);
    }
} else {
    http_response_code(400);
    echo json_encode(["error" => "No image uploaded"]);
}
?>
