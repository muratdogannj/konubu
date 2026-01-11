<?php
// Project configuration
$projectId = 'itiraf-f9cc6';
$collection = 'confessions';

// Get ID from URL parameter (e.g., ?id=123)
$id = isset($_GET['id']) ? $_GET['id'] : '';

// Function to fetch confession from Firestore
function getConfession($projectId, $collection, $id)
{
    if (empty($id))
        return null;

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
$fullDescription = "Anonim konuşmalar, itiraflar ve daha fazlası.";
$description = $fullDescription;
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
    $fullDescription = $content;

    // Calculate 50% length
    $len = mb_strlen($content, "UTF-8");
    $visibleLen = max(10, ceil($len / 2));

    // Truncate logic
    $description = mb_substr($content, 0, $visibleLen, "UTF-8") . '...';

    // Set title
    $isAnonymous = isset($fields['isAnonymous']['booleanValue']) ? $fields['isAnonymous']['booleanValue'] : false;
    $title = $isAnonymous ? "Anonim Bir Konu" : "Biri Konu Açtı!";
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
            background-color: #f0f2f5;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            margin: 0;
            padding: 20px;
            box-sizing: border-box;
        }

        .container {
            width: 100%;
            max-width: 480px;
            display: flex;
            flex-direction: column;
            align-items: center;
        }

        .logo {
            width: 80px;
            height: 80px;
            margin-bottom: 20px;
            border-radius: 20px;
            box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
        }

        .card {
            background: white;
            padding: 30px;
            border-radius: 24px;
            box-shadow: 0 8px 30px rgba(0, 0, 0, 0.12);
            width: 100%;
            text-align: center;
            margin-bottom: 20px;
            position: relative;
            overflow: hidden;
        }

        h1 {
            font-size: 20px;
            color: #1a1a1a;
            margin-top: 0;
            margin-bottom: 16px;
        }

        .content-box {
            font-size: 16px;
            line-height: 1.5;
            color: #4a4a4a;
            margin-bottom: 24px;
            position: relative;
            text-align: left;
        }

        .blur-overlay {
            position: absolute;
            bottom: 0;
            left: 0;
            right: 0;
            height: 60px;
            background: linear-gradient(to bottom, rgba(255, 255, 255, 0), rgba(255, 255, 255, 1));
            display: flex;
            align-items: flex-end;
            justify-content: center;
        }

        .blurred-text {
            color: transparent;
            text-shadow: 0 0 8px rgba(0, 0, 0, 0.5);
            user-select: none;
        }

        .btn {
            display: block;
            width: 100%;
            padding: 16px 0;
            margin-bottom: 12px;
            border-radius: 16px;
            text-decoration: none;
            font-weight: 700;
            font-size: 16px;
            color: white;
            background: linear-gradient(135deg, #FF5722 0%, #F4511E 100%);
            box-shadow: 0 4px 15px rgba(244, 81, 30, 0.3);
            transition: transform 0.2s;
        }

        .btn:active {
            transform: scale(0.98);
        }

        .btn-secondary {
            background: #2d2d2d;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
            font-size: 14px;
            padding: 14px 0;
        }

        .footer {
            font-size: 12px;
            color: #888;
            margin-top: 20px;
        }
    </style>
</head>

<body>
    <div class="container">
        <!-- Logo -->
        <img src="https://konubu.app/assets/images/logo.png" alt="KONUBU" class="logo"
            onerror="this.style.display='none'">

        <div class="card">
            <h1>
                <?php echo htmlspecialchars($title); ?>
            </h1>

            <div class="content-box">
                "<?php echo nl2br(htmlspecialchars($description)); ?>"
                <div class="blur-overlay"></div>
            </div>
            <a href="#" onclick="openAppOrStore(); return false;" class="btn">Devamını Uygulamada Oku</a>
        </div>

        <div class="footer">
            KONUBU &copy; <?php echo date("Y"); ?>
        </div>
    </div>

    <script>
        var appScheme = "<?php echo $appScheme; ?>";
        var playStore = "<?php echo $playStore; ?>";
        var appStore = "<?php echo $appStore; ?>";

        function getMobileOperatingSystem() {
            var userAgent = navigator.userAgent || navigator.vendor || window.opera;

            // Windows Phone must come first because its UA also contains "Android"
            if (/windows phone/i.test(userAgent)) {
                return "Windows Phone";
            }

            if (/android/i.test(userAgent)) {
                return "Android";
            }

            // iOS detection from: http://stackoverflow.com/a/9039885/177710
            if (/iPad|iPhone|iPod/.test(userAgent) && !window.MSStream) {
                return "iOS";
            }

            return "unknown";
        }

        function openAppOrStore() {
            var os = getMobileOperatingSystem();
            var fallbackLink = playStore; // Default to Play Store if unknown

            if (os === "iOS") {
                fallbackLink = appStore;
            } else if (os === "Android") {
                fallbackLink = playStore;
            }

            // Attempt to open App
            window.location.href = appScheme;

            // Fallback to Store after timeout
            setTimeout(function () {
                // Only redirect if the user is still on the page (app didn't open)
                window.location.href = fallbackLink;
            }, 1000);
        }

        window.onload = function () {
            // Optional: Auto-redirect on load? 
            // The user said "bastığında" (when pressed), so maybe manual is better.
            // But usually auto-redirect is preferred for deep links.
            // Let's keep auto-redirect for smooth UX, but the button ensures manual control.

            // Uncomment below to auto-redirect immediately
            // openAppOrStore();
        };
    </script>
</body>

</html>