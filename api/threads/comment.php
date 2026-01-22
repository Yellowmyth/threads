<?php
require_once '../config.php';
$userId = validateJWT();
if (!$userId) {
    http_response_code(401);
    echo json_encode(["error" => "Unauthorized"]);
    exit();
}

$thread_id = isset($_GET['id']) ? (int)$_GET['id'] : null;
$data = json_decode(file_get_contents("php://input"), true);

if ($thread_id && !empty($data['content'])) {
    $stmt = $conn->prepare("INSERT INTO comments (thread_id, user_id, content) VALUES (?, ?, ?)");
    if ($stmt->execute([$thread_id, $userId, $data['content']])) {
        http_response_code(201);
        echo json_encode(["message" => "Comment added successfully"]);
    } else {
        http_response_code(500);
        echo json_encode(["error" => "Unable to add comment"]);
    }
} else {
    http_response_code(400);
    echo json_encode(["error" => "Thread ID and content are required"]);
}
?>
