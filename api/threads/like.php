<?php
require_once '../config.php';
$userId = validateJWT();
if (!$userId) {
    http_response_code(401);
    echo json_encode(["error" => "Unauthorized"]);
    exit();
}

$thread_id = isset($_GET['id']) ? (int)$_GET['id'] : null;

if ($thread_id) {
    // Check if already liked
    $check = $conn->prepare("SELECT id FROM thread_likes WHERE thread_id = ? AND user_id = ?");
    $check->execute([$thread_id, $userId]);
    
    if ($check->rowCount() > 0) {
        // Unlike
        $stmt = $conn->prepare("DELETE FROM thread_likes WHERE thread_id = ? AND user_id = ?");
        $stmt->execute([$thread_id, $userId]);
        $action = "unliked";
    } else {
        // Like
        $stmt = $conn->prepare("INSERT INTO thread_likes (thread_id, user_id) VALUES (?, ?)");
        $stmt->execute([$thread_id, $userId]);
        $action = "liked";
    }
    
    // Get new count
    $countStmt = $conn->prepare("SELECT COUNT(*) as count FROM thread_likes WHERE thread_id = ?");
    $countStmt->execute([$thread_id]);
    $count = $countStmt->fetch(PDO::FETCH_ASSOC)['count'];
    
    http_response_code(200);
    echo json_encode(["message" => "Thread $action", "likes_count" => $count]);
} else {
    http_response_code(400);
    echo json_encode(["error" => "Thread ID is required"]);
}
?>
