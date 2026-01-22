<?php
require_once '../config.php';

$data = json_decode(file_get_contents("php://input"), true);

if (
    !empty($data['username']) &&
    !empty($data['email']) &&
    !empty($data['password'])
) {
    // Check if user exists
    $check = $conn->prepare("SELECT id FROM users WHERE username = ? OR email = ?");
    $check->execute([$data['username'], $data['email']]);
    
    if ($check->rowCount() > 0) {
        http_response_code(400);
        echo json_encode(["error" => "Username or email already exists"]);
        exit();
    }

    $password_hash = password_hash($data['password'], PASSWORD_BCRYPT);
    $full_name = !empty($data['full_name']) ? $data['full_name'] : $data['username'];
    $bio = !empty($data['bio']) ? $data['bio'] : '';
    $profile_image = !empty($data['profile_image']) ? $data['profile_image'] : '';

    $stmt = $conn->prepare("INSERT INTO users (username, email, password, full_name, bio, profile_image) VALUES (?, ?, ?, ?, ?, ?)");
    
    if ($stmt->execute([$data['username'], $data['email'], $password_hash, $full_name, $bio, $profile_image])) {
        $userId = $conn->lastInsertId();
        $token = generateJWT($userId);
        
        http_response_code(201);
        echo json_encode([
            "message" => "User registered successfully",
            "token" => $token,
            "user" => [
                "id" => $userId,
                "username" => $data['username'],
                "email" => $data['email'],
                "full_name" => $full_name
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode(["error" => "Unable to register user"]);
    }
} else {
    http_response_code(400);
    echo json_encode(["error" => "Incomplete data"]);
}
?>
