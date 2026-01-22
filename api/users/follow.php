<?php
require_once '../config.php';
$followerId = validateJWT();
if (!$followerId) {
    http_response_code(401);
    echo json_encode(["error" => "Unauthorized"]);
    exit();
}

$followingId = isset($_GET['id']) ? (int)$_GET['id'] : null;

if ($followingId && $followerId != $followingId) {
    // Check if already following
    $check = $conn->prepare("SELECT id FROM followers WHERE follower_id = ? AND following_id = ?");
    $check->execute([$followerId, $followingId]);
    
    if ($check->rowCount() > 0) {
        // Unfollow
        $stmt = $conn->prepare("DELETE FROM followers WHERE follower_id = ? AND following_id = ?");
        $stmt->execute([$followerId, $followingId]);
        $action = "unfollowed";
    } else {
        // Follow
        $stmt = $conn->prepare("INSERT INTO followers (follower_id, following_id) VALUES (?, ?)");
        $stmt->execute([$followerId, $followingId]);
        $action = "followed";
    }
    
    // Get new counts
    $followStmt = $conn->prepare("SELECT 
        (SELECT COUNT(*) FROM followers WHERE following_id = ?) as followers_count,
        (SELECT COUNT(*) FROM followers WHERE follower_id = ?) as following_count");
    $followStmt->execute([$followingId, $followerId]);
    $counts = $followStmt->fetch(PDO::FETCH_ASSOC);
    
    http_response_code(200);
    echo json_encode([
        "message" => "User $action", 
        "followers_count" => $counts['followers_count'],
        "following_count" => $counts['following_count']
    ]);
} else {
    http_response_code(400);
    echo json_encode(["error" => "Invalid target user ID"]);
}
?>
