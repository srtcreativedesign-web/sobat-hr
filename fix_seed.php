<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/database/seeders/EmployeeSeeder.php';
$content = file_get_contents($file);
$content = str_replace("'user_id'", "'organization_id' => \$defaultOrg->id,\n                    'user_id'", $content);
file_put_contents($file, $content);
