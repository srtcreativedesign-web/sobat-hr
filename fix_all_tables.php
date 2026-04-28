<?php
$file = '/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/app/Console/Commands/UpdateThpRetroactively.php';
$content = file_get_contents($file);

$search = <<<EOT
        // Ensure payroll_fnb has thp column (it was missed in previous migration due to typo)
        if (\Illuminate\Support\Facades\Schema::hasTable('payroll_fnb') && !\Illuminate\Support\Facades\Schema::hasColumn('payroll_fnb', 'thp')) {
            \Illuminate\Support\Facades\Schema::table('payroll_fnb', function (\Illuminate\Database\Schema\Blueprint \$table) {
                \$table->decimal('thp', 15, 2)->default(0)->after('net_salary');
            });
            \$this->info('Added missing thp column to payroll_fnb.');
        }
EOT;

$replace = <<<EOT
        // Auto-add THP column to any table that missed the migration
        \$tables = [
            'payroll_fnb',
            'payrolls_mm',
            'payrolls_ref',
            'payrolls_wrapping',
            'payrolls_hans',
            'payroll_cellullers',
            'payrolls_money_changer'
        ];

        foreach (\$tables as \$tbl) {
            if (\Illuminate\Support\Facades\Schema::hasTable(\$tbl) && !\Illuminate\Support\Facades\Schema::hasColumn(\$tbl, 'thp')) {
                \Illuminate\Support\Facades\Schema::table(\$tbl, function (\Illuminate\Database\Schema\Blueprint \$table) {
                    \$table->decimal('thp', 15, 2)->default(0)->after('net_salary');
                });
                \$this->info("Added missing thp column to {\$tbl}.");
            }
        }
EOT;

$content = str_replace($search, $replace, $content);
file_put_contents($file, $content);
echo "Fixed artisan command to auto-add thp everywhere.\n";
