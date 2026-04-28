<?php
$files = glob('/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/database/migrations/*_add_thp_to_multiple_payrolls_table.php');
if (empty($files)) {
    die("Migration not found.");
}
$file = $files[0];

$content = <<<EOT
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        \$tables = [
            'payroll_fnbs',
            'payrolls_mm',
            'payrolls_ref',
            'payrolls_wrapping',
            'payrolls_hans',
            'payroll_cellullers',
            'payrolls_money_changer'
        ];

        foreach (\$tables as \$tableName) {
            if (Schema::hasTable(\$tableName)) {
                Schema::table(\$tableName, function (Blueprint \$table) {
                    // Add THP column, defaulting to 0
                    \$table->decimal('thp', 15, 2)->default(0)->after('net_salary');
                });
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        \$tables = [
            'payroll_fnbs',
            'payrolls_mm',
            'payrolls_ref',
            'payrolls_wrapping',
            'payrolls_hans',
            'payroll_cellullers',
            'payrolls_money_changer'
        ];

        foreach (\$tables as \$tableName) {
            if (Schema::hasTable(\$tableName) && Schema::hasColumn(\$tableName, 'thp')) {
                Schema::table(\$tableName, function (Blueprint \$table) {
                    \$table->dropColumn('thp');
                });
            }
        }
    }
};
EOT;

file_put_contents($file, $content);
echo "Migration patched.";
