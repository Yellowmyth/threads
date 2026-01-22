<?php
require_once '../config.php';

$data = json_decode(file_get_contents("php://input"), true);

if (!empty($data['email']) && !empty($data['password'])) {
    $stmt = $conn->prepare("SELECT id, username, email, password, full_name, bio, profile_image FROM users WHERE email = ?");
    $stmt->execute([$data['email']]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($user && password_verify($data['password'], $user['password'])) {
        $token = generateJWT($user['id']);
        unset($user['password']); // Remove password from response
        
        http_response_code(200);
        echo json_encode([
            "message" => "Login successful",
            "token" => $token,
            "user" => $user
        ]);
    } else {
        http_response_code(401);
        echo json_encode(["error" => "Invalid email or password"]);
    }
} else {
    http_response_code(400);
    echo json_encode(["error" => "Incomplete data"]);
}
?>
