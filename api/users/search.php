<?php
require_once '../config.php';

$current_user_id = validateJWT();
if ($current_user_id) {
    $current_user_id = (int)$current_user_id;
}

$search = isset($_GET['search']) ? $_GET['search'] : '';

$query = "SELECT id, username, email, full_name, bio, profile_image,
          (SELECT COUNT(*) FROM followers WHERE following_id = users.id) as followers_count,
          (SELECT COUNT(*) FROM followers WHERE follower_id = users.id) as following_count";

if ($current_user_id) {
    $query .= ", (SELECT COUNT(*) FROM followers WHERE follower_id = $current_user_id AND following_id = users.id) as is_following";
} else {
    $query .= ", 0 as is_following";
}

$query .= " FROM users";

if ($search) {
    $query .= " WHERE username LIKE ? OR full_name LIKE ?";
} else {
    // If no search, show some suggested users (excluding current user)
    if ($current_user_id) {
        $query .= " WHERE id != $current_user_id";
    }
}

$query .= " ORDER BY followers_count DESC LIMIT 20";

$stmt = $conn->prepare($query);
if ($search) {
    $searchTerm = "%$search%";
    $stmt->execute([$searchTerm, $searchTerm]);
} else {
    $stmt->execute();
}

$users = $stmt->fetchAll(PDO::FETCH_ASSOC);

// Format Boolean for is_following
foreach ($users as &$user) {
    $user['is_following'] = (int)$user['is_following'] > 0;
}

http_response_code(200);
echo json_encode($users);
?>
