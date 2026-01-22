<?php
require_once '../config.php';

$thread_id = isset($_GET['id']) ? (int)$_GET['id'] : null;

if ($thread_id) {
    $stmt = $conn->prepare("SELECT c.*, u.username, u.full_name, u.profile_image 
                            FROM comments c 
                            JOIN users u ON c.user_id = u.id 
                            WHERE c.thread_id = ? 
                            ORDER BY c.created_at ASC");
    $stmt->execute([$thread_id]);
    $comments = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    http_response_code(200);
    echo json_encode($comments);
} else {
    http_response_code(400);
    echo json_encode(["error" => "Thread ID is required"]);
}
?>
