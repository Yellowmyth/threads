<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, X-User-ID");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database configuration
$host = "localhost";
$db_name = "bere9277_db_naufal";
$username = "bere9277_user_naufal";
$password = "naufal123";
$conn = null;

try {
    $conn = new PDO("mysql:host=" . $host . ";dbname=" . $db_name, $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $conn->exec("set names utf8");
} catch(PDOException $exception) {
    http_response_code(500);
    echo json_encode(["error" => "Connection error: " . $exception->getMessage()]);
    exit();
}

// Auth helper - Simplified for local testing
if (!function_exists('apache_request_headers')) {
    function apache_request_headers() {
        $headers = [];
        foreach ($_SERVER as $key => $value) {
            if (substr($key, 0, 5) == 'HTTP_') {
                $header = str_replace(' ', '-', ucwords(str_replace('_', ' ', strtolower(substr($key, 5)))));
                $headers[$header] = $value;
            }
        }
        return $headers;
    }
}

function validateJWT() {
    $headers = apache_request_headers();
    
    // Check X-User-ID (case insensitive)
    foreach ($headers as $name => $value) {
        if (strtolower($name) === 'x-user-id') {
            return $value;
        }
    }
    
    // Fallback to $_SERVER directly
    if (isset($_SERVER['HTTP_X_USER_ID'])) {
        return $_SERVER['HTTP_X_USER_ID'];
    }
    
    // For GET requests sometimes we might pass it as query param for testing
    if (isset($_GET['user_id'])) {
        return $_GET['user_id'];
    }
    
    return null; 
}

function generateJWT($userId) {
    // Just return the user ID as "token" for simplicity
    return (string)$userId;
}
?>
