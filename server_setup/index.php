<?php
// Project configuration
$projectId = 'itiraf-f9cc6';
$collection = 'confessions';

// Get ID from URL parameter (e.g., ?id=123)
$id = isset($_GET['id']) ? $_GET['id'] : '';

// Function to fetch confession from Firestore
function getConfession($projectId, $collection, $id) {
    if (empty($id)) return null;
    
    $url = "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collection/$id";
    
    // Initialize cURL
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false); // Optional: if certificates fail
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode == 200) {
        return json_decode($response, true);
    }
    return null;
}

// Default values
$title = "KONUBU";
$description = "Anonim konuşmalar, itiraflar ve daha fazlası.";
$image = "https://konubu.app/assets/social_preview.png"; // Replace with your default image
$appScheme = "konubu://c/" . $id;
$playStore = "https://play.google.com/store/apps/details?id=com.dgn.konubu";
$appStore = "https://apps.apple.com/app/id6471926685";

// Fetch data if ID exists
$data = getConfession($projectId, $collection, $id);

if ($data && isset($data['fields'])) {
    $fields = $data['fields'];
    
    // Extract content
    $content = isset($fields['content']['stringValue']) ? $fields['content']['stringValue'] : '';
    
    // Truncate description
    if (strlen($content) > 150) {
        $description = mb_substr($content, 0, 147, "UTF-8") . '...';
    } else {
        $description = $content;
    }
    
    // Set title
    $isAnonymous = isset($fields['isAnonymous']['booleanValue']) ? $fields['isAnonymous']['booleanValue'] : false;
    $title = $isAnonymous ? "Anonim Bir İtiraf" : "Biri Konu Açtı!";
}
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><?php echo htmlspecialchars($title); ?> | KONUBU</title>
    
    <!-- Open Graph / Facebook / WhatsApp -->
    <meta property="og:type" content="website">
    <meta property="og:url" content="https://konubu.app/c/<?php echo htmlspecialchars($id); ?>">
    <meta property="og:title" content="<?php echo htmlspecialchars($title); ?>">
    <meta property="og:description" content="<?php echo htmlspecialchars($description); ?>">
    <meta property="og:image" content="<?php echo htmlspecialchars($image); ?>">

    <!-- Twitter -->
    <meta property="twitter:card" content="summary_large_image">
    <meta property="twitter:title" content="<?php echo htmlspecialchars($title); ?>">
    <meta property="twitter:description" content="<?php echo htmlspecialchars($description); ?>">
    <meta property="twitter:image" content="<?php echo htmlspecialchars($image); ?>">

    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background-color: #f5f5f5;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100vh;
            margin: 0;
            text-align: center;
            padding: 20px;
        }
        .card {
            background: white;
            padding: 30px;
            border-radius: 20px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            max-width: 90%;
            width: 400px;
        }
        .btn {
            display: block;
            width: 100%;
            padding: 15px 0;
            margin-bottom: 10px;
            border-radius: 12px;
            text-decoration: none;
            font-weight: bold;
            color: white;
            background-color: #FF5722;
        }
        .btn-secondary { background-color: #333; }
    </style>
</head>
<body>
    <div class="card">
        <h1>Konuyu Uygulamada Gör</h1>
        <p>"<?php echo htmlspecialchars($description); ?>"</p>

        <a href="<?php echo $appScheme; ?>" class="btn">Uygulamada Aç</a>
        <a href="<?php echo $playStore; ?>" id="android-link" class="btn btn-secondary">Google Play</a>
        <a href="<?php echo $appStore; ?>" id="ios-link" class="btn btn-secondary">App Store</a>
    </div>

    <script>
        window.onload = function() {
            var userAgent = navigator.userAgent || navigator.vendor || window.opera;
            
            // Try explicit deep link
            window.location.href = "<?php echo $appScheme; ?>";
            
            // Fallback logic could be added here
        };
    </script>
</body>
</html>
