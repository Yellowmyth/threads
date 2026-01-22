<?php
require_once '../config.php';

// Optional auth to see if user liked the thread
$current_user_id = validateJWT();
if ($current_user_id) {
    $current_user_id = (int)$current_user_id;
}

$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 20;
$offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;
$user_id_filter = isset($_GET['user_id']) ? (int)$_GET['user_id'] : null;

$query = "SELECT t.*, u.username, u.full_name, u.profile_image, 
          (SELECT COUNT(*) FROM thread_likes WHERE thread_id = t.id) as likes_count,
          (SELECT COUNT(*) FROM comments WHERE thread_id = t.id) as comments_count";

if ($current_user_id) {
    $query .= ", (SELECT COUNT(*) FROM thread_likes WHERE thread_id = t.id AND user_id = $current_user_id) as is_liked";
} else {
    $query .= ", 0 as is_liked";
}

$query .= " FROM threads t JOIN users u ON t.user_id = u.id";

if ($user_id_filter) {
    $query .= " WHERE t.user_id = $user_id_filter";
}

$query .= " ORDER BY t.created_at DESC LIMIT $limit OFFSET $offset";

$stmt = $conn->prepare($query);
$stmt->execute();
$threads = $stmt->fetchAll(PDO::FETCH_ASSOC);

// Format Boolean for is_liked
foreach ($threads as &$thread) {
    $thread['is_liked'] = $thread['is_liked'] > 0;
}

http_response_code(200);
echo json_encode($threads);
?>
