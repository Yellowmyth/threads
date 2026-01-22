<?php
require_once '../config.php';

$authId = validateJWT();

if (!$authId) {
    http_response_code(401);
    echo json_encode(["error" => "Unauthorized"]);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);
    if (!$data) $data = $_POST; 

    $full_name = !empty($data['full_name']) ? $data['full_name'] : null;
    $bio = !empty($data['bio']) ? $data['bio'] : null;
    $profile_image = !empty($data['profile_image']) ? $data['profile_image'] : null;

    if (!$full_name && !$bio && !$profile_image) {
        http_response_code(400);
        echo json_encode(["error" => "No data provided for update"]);
        exit();
    }

    $query = "UPDATE users SET ";
    $params = [];
    if ($full_name) { $query .= "full_name = ?, "; $params[] = $full_name; }
    if ($bio) { $query .= "bio = ?, "; $params[] = $bio; }
    if ($profile_image) { $query .= "profile_image = ?, "; $params[] = $profile_image; }
    
    $query = rtrim($query, ", ");
    $query .= " WHERE id = ?";
    $params[] = $authId;
    
    try {
        $stmt = $conn->prepare($query);
        if ($stmt->execute($params)) {
            http_response_code(200);
            echo json_encode(["message" => "Profile updated successfully"]);
        } else {
            http_response_code(500);
            echo json_encode(["error" => "Unable to update profile"]);
        }
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(["error" => "Database error: " . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(["error" => "Method not allowed"]);
}
?>
