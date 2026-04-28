<?php
$files = glob('/Applications/XAMPP/xamppfiles/htdocs/sobat-hr/sobat-api/database/migrations/*_add_status_to_payroll_maximums_table.php');
if (empty($files)) {
    die("Migration not found.");
}
$file = $files[0];
$content = file_get_contents($file);

$upSearch = <<<EOT
    public function up(): void
    {
        Schema::table('payroll_maximums', function (Blueprint \$table) {
            //
        });
    }
EOT;
$upReplace = <<<EOT
    public function up(): void
    {
        Schema::table('payroll_maximums', function (Blueprint \$table) {
            \$table->string('status')->default('draft')->after('employee_id');
            \$table->text('notes')->nullable();
            \$table->foreignId('approved_by')->nullable()->constrained('users');
            \$table->text('approval_signature')->nullable();
            \$table->string('signer_name')->nullable();
        });
    }
EOT;
$content = str_replace($upSearch, $upReplace, $content);

$downSearch = <<<EOT
    public function down(): void
    {
        Schema::table('payroll_maximums', function (Blueprint \$table) {
            //
        });
    }
EOT;
$downReplace = <<<EOT
    public function down(): void
    {
        Schema::table('payroll_maximums', function (Blueprint \$table) {
            \$table->dropForeign(['approved_by']);
            \$table->dropColumn(['status', 'notes', 'approved_by', 'approval_signature', 'signer_name']);
        });
    }
EOT;
$content = str_replace($downSearch, $downReplace, $content);

file_put_contents($file, $content);
echo "Migration patched.";
