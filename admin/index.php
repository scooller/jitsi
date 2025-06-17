<?php

/**
 * Jitsi Meet Admin Panel
 * Simple web interface for managing Jitsi Meet users and settings
 */

// Configuration
// Load password from .env file
$env_file = '../.env';
$ADMIN_PASSWORD = 'Scooller2025_Kagura8968_Admin'; // Fallback password
if (file_exists($env_file)) {
    $env_content = file_get_contents($env_file);
    if (preg_match('/^ADMIN_WEB_PASSWORD=(.*)$/m', $env_content, $matches)) {
        $ADMIN_PASSWORD = trim($matches[1]);
    }
}
$DOCKER_COMPOSE_PATH = '/opt/jitsi-meet';
$LOG_FILE = '/opt/jitsi-meet/logs/admin.log';

// Start session
session_start();

// Authentication check
if (!isset($_SESSION['admin_logged_in']) && !isset($_POST['login'])) {
    showLoginForm();
    exit;
}

// Handle login
if (isset($_POST['login'])) {
    if ($_POST['password'] === $ADMIN_PASSWORD) {
        $_SESSION['admin_logged_in'] = true;
        logAction("Admin login successful from " . $_SERVER['REMOTE_ADDR']);
    } else {
        logAction("Failed login attempt from " . $_SERVER['REMOTE_ADDR']);
        showLoginForm("Invalid password");
        exit;
    }
}

// Handle logout
if (isset($_GET['logout'])) {
    session_destroy();
    logAction("Admin logout from " . $_SERVER['REMOTE_ADDR']);
    header("Location: " . $_SERVER['PHP_SELF']);
    exit;
}

// Handle actions
if (isset($_POST['action'])) {
    handleAction($_POST['action'], $_POST);
}

// Get system status
$status = getSystemStatus();
$users = getUsers();

?>
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Jitsi Meet Admin Panel</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #f5f5f5;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }

        .header {
            background: #1976d2;
            color: white;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
        }

        .header h1 {
            margin-bottom: 10px;
        }

        .header .logout {
            float: right;
            color: white;
            text-decoration: none;
            background: rgba(255, 255, 255, 0.2);
            padding: 8px 16px;
            border-radius: 4px;
        }

        .card {
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
            margin-bottom: 20px;
        }

        .card-header {
            background: #f8f9fa;
            padding: 16px;
            border-bottom: 1px solid #dee2e6;
            font-weight: bold;
        }

        .card-body {
            padding: 20px;
        }

        .status-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }

        .status-item {
            text-align: center;
            padding: 20px;
            border-radius: 8px;
        }

        .status-online {
            background: #d4edda;
            color: #155724;
        }

        .status-offline {
            background: #f8d7da;
            color: #721c24;
        }

        .form-group {
            margin-bottom: 15px;
        }

        .form-group label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
        }

        .form-group input,
        .form-group select {
            width: 100%;
            padding: 8px 12px;
            border: 1px solid #ddd;
            border-radius: 4px;
        }

        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
        }

        .btn-primary {
            background: #007bff;
            color: white;
        }

        .btn-danger {
            background: #dc3545;
            color: white;
        }

        .btn-success {
            background: #28a745;
            color: white;
        }

        .btn-warning {
            background: #ffc107;
            color: #212529;
        }

        .users-table {
            width: 100%;
            border-collapse: collapse;
        }

        .users-table th,
        .users-table td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #dee2e6;
        }

        .users-table th {
            background: #f8f9fa;
        }

        .alert {
            padding: 15px;
            border-radius: 4px;
            margin-bottom: 20px;
        }

        .alert-success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }

        .alert-danger {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }

        .login-form {
            max-width: 400px;
            margin: 100px auto;
            background: white;
            padding: 40px;
            border-radius: 8px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
    </style>
</head>

<body>

    <?php if (!isset($_SESSION['admin_logged_in'])): ?>
        <!-- This will not show as we handle login above -->
    <?php else: ?>

        <div class="container">
            <div class="header">
                <h1>🎥 Jitsi Meet Admin Panel</h1>
                <p>Manage your video conferencing system</p>
                <a href="?logout=1" class="logout">Logout</a>
                <div style="clear: both;"></div>
            </div>

            <!-- System Status -->
            <div class="card">
                <div class="card-header">System Status</div>
                <div class="card-body">
                    <div class="status-grid">
                        <div class="status-item <?php echo $status['web'] ? 'status-online' : 'status-offline'; ?>">
                            <h3>Web Service</h3>
                            <p><?php echo $status['web'] ? 'Online' : 'Offline'; ?></p>
                        </div>
                        <div class="status-item <?php echo $status['prosody'] ? 'status-online' : 'status-offline'; ?>">
                            <h3>Prosody (XMPP)</h3>
                            <p><?php echo $status['prosody'] ? 'Online' : 'Offline'; ?></p>
                        </div>
                        <div class="status-item <?php echo $status['jvb'] ? 'status-online' : 'status-offline'; ?>">
                            <h3>Videobridge</h3>
                            <p><?php echo $status['jvb'] ? 'Online' : 'Offline'; ?></p>
                        </div>
                        <div class="status-item <?php echo $status['jicofo'] ? 'status-online' : 'status-offline'; ?>">
                            <h3>Focus</h3>
                            <p><?php echo $status['jicofo'] ? 'Online' : 'Offline'; ?></p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Quick Actions -->
            <div class="card">
                <div class="card-header">Quick Actions</div>
                <div class="card-body">
                    <form method="post" style="display: inline-block; margin-right: 10px;">
                        <input type="hidden" name="action" value="enable_auth">
                        <button type="submit" class="btn btn-warning">🔒 Enable Authentication (Private Mode)</button>
                    </form>

                    <form method="post" style="display: inline-block; margin-right: 10px;">
                        <input type="hidden" name="action" value="disable_auth">
                        <button type="submit" class="btn btn-success">🌐 Disable Authentication (Public Mode)</button>
                    </form>

                    <form method="post" style="display: inline-block;">
                        <input type="hidden" name="action" value="restart_services">
                        <button type="submit" class="btn btn-primary">🔄 Restart Services</button>
                    </form>
                </div>
            </div>

            <!-- Create User -->
            <div class="card">
                <div class="card-header">Create New User</div>
                <div class="card-body">
                    <form method="post">
                        <input type="hidden" name="action" value="create_user">
                        <div style="display: grid; grid-template-columns: 1fr 1fr auto; gap: 15px; align-items: end;">
                            <div class="form-group">
                                <label>Username</label>
                                <input type="text" name="username" required>
                            </div>
                            <div class="form-group">
                                <label>Password</label>
                                <input type="password" name="password" required>
                            </div>
                            <div class="form-group">
                                <button type="submit" class="btn btn-primary">👤 Create User</button>
                            </div>
                        </div>
                    </form>
                </div>
            </div>

            <!-- User Management -->
            <div class="card">
                <div class="card-header">Registered Users</div>
                <div class="card-body">
                    <?php if (empty($users)): ?>
                        <p>No users registered. Authentication is probably disabled.</p>
                    <?php else: ?>
                        <table class="users-table">
                            <thead>
                                <tr>
                                    <th>Username</th>
                                    <th>Domain</th>
                                    <th>Status</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php foreach ($users as $user): ?>
                                    <tr>
                                        <td><?php echo htmlspecialchars($user['username']); ?></td>
                                        <td><?php echo htmlspecialchars($user['domain']); ?></td>
                                        <td><span style="color: green;">Active</span></td>
                                        <td>
                                            <form method="post" style="display: inline;">
                                                <input type="hidden" name="action" value="delete_user">
                                                <input type="hidden" name="username" value="<?php echo htmlspecialchars($user['username']); ?>">
                                                <button type="submit" class="btn btn-danger" onclick="return confirm('Delete user?')">🗑️ Delete</button>
                                            </form>
                                        </td>
                                    </tr>
                                <?php endforeach; ?>
                            </tbody>
                        </table>
                    <?php endif; ?>
                </div>
            </div>

        </div>

    <?php endif; ?>

</body>

</html>

<?php

function showLoginForm($error = '')
{
?>
    <!DOCTYPE html>
    <html>

    <head>
        <title>Jitsi Admin Login</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                background: #f5f5f5;
            }

            .login-form {
                max-width: 400px;
                margin: 100px auto;
                background: white;
                padding: 40px;
                border-radius: 8px;
                box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            }

            .form-group {
                margin-bottom: 20px;
            }

            .form-group label {
                display: block;
                margin-bottom: 5px;
                font-weight: bold;
            }

            .form-group input {
                width: 100%;
                padding: 12px;
                border: 1px solid #ddd;
                border-radius: 4px;
            }

            .btn {
                width: 100%;
                padding: 12px;
                background: #007bff;
                color: white;
                border: none;
                border-radius: 4px;
                cursor: pointer;
            }

            .error {
                color: red;
                margin-bottom: 15px;
            }
        </style>
    </head>

    <body>
        <div class="login-form">
            <h2>🎥 Jitsi Meet Admin</h2>
            <?php if ($error): ?>
                <p class="error"><?php echo htmlspecialchars($error); ?></p>
            <?php endif; ?>
            <form method="post">
                <div class="form-group">
                    <label>Admin Password</label>
                    <input type="password" name="password" required>
                </div>
                <button type="submit" name="login" class="btn">Login</button>
            </form>
        </div>
    </body>

    </html>
<?php
}

function getSystemStatus()
{
    $status = [
        'web' => false,
        'prosody' => false,
        'jvb' => false,
        'jicofo' => false
    ];

    // Check if containers are running
    $output = shell_exec('docker-compose ps 2>/dev/null');
    if ($output) {
        $status['web'] = strpos($output, 'jitsi-web') !== false && strpos($output, 'Up') !== false;
        $status['prosody'] = strpos($output, 'prosody') !== false && strpos($output, 'Up') !== false;
        $status['jvb'] = strpos($output, 'jvb') !== false && strpos($output, 'Up') !== false;
        $status['jicofo'] = strpos($output, 'jicofo') !== false && strpos($output, 'Up') !== false;
    }

    return $status;
}

function getUsers()
{
    $users = [];

    // Alternative method to get users since mod_listusers is not available
    $output = shell_exec('docker exec jitsi-prosody ls -la /config/data/auth%2emeet%2ejitsi/accounts/ 2>/dev/null | grep "\.dat$"');

    if ($output) {
        $lines = explode("\n", trim($output));
        foreach ($lines as $line) {
            if (preg_match('/(\w+)\.dat$/', $line, $matches)) {
                $username = $matches[1];
                // Skip system users
                if ($username !== 'focus' && $username !== 'jvb') {
                    $users[] = [
                        'username' => $username,
                        'domain' => 'auth.meet.jitsi'
                    ];
                }
            }
        }
    }

    return $users;
}

function handleAction($action, $data)
{
    switch ($action) {
        case 'create_user':
            $username = $data['username'];
            $password = $data['password'];
            $result = shell_exec("docker exec jitsi-prosody prosodyctl --config /config/prosody.cfg.lua register '$username' 'auth.meet.jitsi' '$password' 2>&1");
            logAction("Created user: $username");
            break;

        case 'delete_user':
            $username = $data['username'];
            $result = shell_exec("docker exec jitsi-prosody prosodyctl --config /config/prosody.cfg.lua unregister '$username' 'auth.meet.jitsi' 2>&1");
            logAction("Deleted user: $username");
            break;

        case 'enable_auth':
            updateEnvFile('ENABLE_AUTH', '1');
            updateEnvFile('ENABLE_GUESTS', '0');
            logAction("Enabled authentication");
            break;

        case 'disable_auth':
            updateEnvFile('ENABLE_AUTH', '0');
            updateEnvFile('ENABLE_GUESTS', '1');
            logAction("Disabled authentication");
            break;

        case 'restart_services':
            shell_exec('docker-compose restart 2>&1');
            logAction("Restarted services");
            break;
    }

    // Redirect to prevent form resubmission
    header("Location: " . $_SERVER['PHP_SELF']);
    exit;
}

function updateEnvFile($key, $value)
{
    $envFile = '.env';
    if (file_exists($envFile)) {
        $content = file_get_contents($envFile);
        $content = preg_replace("/^$key=.*$/m", "$key=$value", $content);
        file_put_contents($envFile, $content);
    }
}

function logAction($message)
{
    global $LOG_FILE;
    $timestamp = date('Y-m-d H:i:s');
    $ip = $_SERVER['REMOTE_ADDR'];
    $logMessage = "[$timestamp] [$ip] $message\n";
    file_put_contents($LOG_FILE, $logMessage, FILE_APPEND | LOCK_EX);
}

?>