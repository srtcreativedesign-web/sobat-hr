<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Console/Commands/UpdateThpRetroactively.php';
$content = file_get_contents($file);

// Replace payroll_fnbs with payroll_fnb
$content = str_replace("DB::table('payroll_fnbs')", "DB::table('payroll_fnb')", $content);
$content = str_replace("records in payroll_fnbs", "records in payroll_fnb", $content);

// Add logic to add thp column to payroll_fnb if missing
$search = "\$this->info('Starting retroactive THP update...');";
$replace = <<<EOT
\$this->info('Starting retroactive THP update...');

        // Ensure payroll_fnb has thp column (it was missed in previous migration due to typo)
        if (\Illuminate\Support\Facades\Schema::hasTable('payroll_fnb') && !\Illuminate\Support\Facades\Schema::hasColumn('payroll_fnb', 'thp')) {
            \Illuminate\Support\Facades\Schema::table('payroll_fnb', function (\Illuminate\Database\Schema\Blueprint \$table) {
                \$table->decimal('thp', 15, 2)->default(0)->after('net_salary');
            });
            \$this->info('Added missing thp column to payroll_fnb.');
        }
EOT;

$content = str_replace($search, $replace, $content);
file_put_contents($file, $content);
echo "Artisan command patched.";
