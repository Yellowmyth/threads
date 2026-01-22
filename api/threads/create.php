<?php
require_once '../config.php';
$userId = validateJWT();

if (!$userId) {
    http_response_code(401);
    echo json_encode(["error" => "Unauthorized"]);
    exit();
}

$data = json_decode(file_get_contents("php://input"), true);

if (!empty($data['content'])) {
    $content = $data['content'];
    $image = !empty($data['image']) ? $data['image'] : null;

    try {
        $stmt = $conn->prepare("INSERT INTO threads (user_id, content, image) VALUES (?, ?, ?)");
        if ($stmt->execute([$userId, $content, $image])) {
            http_response_code(201);
            echo json_encode(["message" => "Thread created successfully", "id" => $conn->lastInsertId()]);
        } else {
            http_response_code(500);
            echo json_encode(["error" => "Unable to create thread"]);
        }
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(["error" => "Database error: " . $e->getMessage()]);
    }
} else {
    http_response_code(400);
    echo json_encode(["error" => "Content is required"]);
}
?>
