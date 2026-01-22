<?php
require_once '../config.php';

// Auth user if they want to see if follow status
$current_user_id = validateJWT();
if ($current_user_id) {
    $current_user_id = (int)$current_user_id;
}

$user_id = isset($_GET['id']) ? (int)$_GET['id'] : null;

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    if (!$user_id) {
        http_response_code(400);
        echo json_encode(["error" => "User ID is required"]);
        exit();
    }
    
    $stmt = $conn->prepare("SELECT id, username, email, full_name, bio, profile_image, created_at,
                            (SELECT COUNT(*) FROM followers WHERE following_id = ?) as followers_count,
                            (SELECT COUNT(*) FROM followers WHERE follower_id = ?) as following_count
                            FROM users WHERE id = ?");
    $stmt->execute([$user_id, $user_id, $user_id]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($user) {
        $user['is_following'] = false;
        if ($current_user_id && $current_user_id != $user_id) {
            $checkFollow = $conn->prepare("SELECT id FROM followers WHERE follower_id = ? AND following_id = ?");
            $checkFollow->execute([$current_user_id, $user_id]);
            $user['is_following'] = $checkFollow->rowCount() > 0;
        }
        
        http_response_code(200);
        echo json_encode($user);
    } else {
        http_response_code(404);
        echo json_encode(["error" => "User not found"]);
    }
} elseif ($_SERVER['REQUEST_METHOD'] === 'PUT' || $_SERVER['REQUEST_METHOD'] === 'POST') {
    $authId = validateJWT();
    if (!$authId) {
        http_response_code(401);
        echo json_encode(["error" => "Unauthorized"]);
        exit();
    }
    if ($authId != $user_id) {
        http_response_code(403);
        echo json_encode(["error" => "Forbidden"]);
        exit();
    }
    
    $data = json_decode(file_get_contents("php://input"), true);
    if (!$data) $data = $_POST; // Fallback for multipart/form-data if used

    $full_name = !empty($data['full_name']) ? $data['full_name'] : null;
    $bio = !empty($data['bio']) ? $data['bio'] : null;
    $profile_image = !empty($data['profile_image']) ? $data['profile_image'] : null;

    $query = "UPDATE users SET ";
    $params = [];
    if ($full_name) { $query .= "full_name = ?, "; $params[] = $full_name; }
    if ($bio) { $query .= "bio = ?, "; $params[] = $bio; }
    if ($profile_image) { $query .= "profile_image = ?, "; $params[] = $profile_image; }
    
    $query = rtrim($query, ", ");
    $query .= " WHERE id = ?";
    $params[] = $authId;
    
    $stmt = $conn->prepare($query);
    if ($stmt->execute($params)) {
        http_response_code(200);
        echo json_encode(["message" => "Profile updated successfully"]);
    } else {
        http_response_code(500);
        echo json_encode(["error" => "Unable to update profile"]);
    }
}
?>
