<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class UpdateThpRetroactively extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'payroll:update-thp';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Retroactively calculates and updates the THP column for all existing payroll records across all divisions.';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('Starting retroactive THP update...');

        // Auto-add THP column to any table that missed the migration
        $tables = [
            'payroll_fnb',
            'payrolls_mm',
            'payrolls_ref',
            'payrolls_wrapping',
            'payrolls_hans',
            'payroll_cellullers',
            'payrolls_money_changer'
        ];

        foreach ($tables as $tbl) {
            if (\Illuminate\Support\Facades\Schema::hasTable($tbl) && !\Illuminate\Support\Facades\Schema::hasColumn($tbl, 'thp')) {
                \Illuminate\Support\Facades\Schema::table($tbl, function (\Illuminate\Database\Schema\Blueprint $table) {
                    $table->decimal('thp', 15, 2)->default(0)->after('net_salary');
                });
                $this->info("Added missing thp column to {$tbl}.");
            }
        }

        // 1. FnB (THP = net_salary + ewa_amount)
        $fnbCount = DB::table('payroll_fnb')->update([
            'thp' => DB::raw('net_salary + ewa_amount')
        ]);
        $this->info("Updated $fnbCount records in payroll_fnb.");

        // 2. Minimarket (THP = net_salary + (ewa_amount > 0 ? ewa_amount : deduction_loan))
        $mmCount = DB::table('payrolls_mm')->update([
            'thp' => DB::raw('net_salary + IF(ewa_amount > 0, ewa_amount, deduction_loan)')
        ]);
        $this->info("Updated $mmCount records in payrolls_mm.");

        // 3. Reflexiology
        $refCount = DB::table('payrolls_ref')->update([
            'thp' => DB::raw('net_salary + ewa_amount')
        ]);
        $this->info("Updated $refCount records in payrolls_ref.");

        // 4. Wrapping
        $wrappingCount = DB::table('payrolls_wrapping')->update([
            'thp' => DB::raw('net_salary + ewa_amount')
        ]);
        $this->info("Updated $wrappingCount records in payrolls_wrapping.");

        // 5. Hans (THP = net_salary + (ewa_amount > 0 ? ewa_amount : deduction_loan))
        $hansCount = DB::table('payrolls_hans')->update([
            'thp' => DB::raw('net_salary + IF(ewa_amount > 0, ewa_amount, deduction_loan)')
        ]);
        $this->info("Updated $hansCount records in payrolls_hans.");

        // 6. Cellular (THP = final_payment + ewa_amount)
        $cellularCount = DB::table('payroll_cellullers')->update([
            'thp' => DB::raw('final_payment + ewa_amount')
        ]);
        $this->info("Updated $cellularCount records in payroll_cellullers.");

        // 7. Money Changer
        $mcCount = DB::table('payrolls_money_changer')->update([
            'thp' => DB::raw('net_salary + ewa_amount')
        ]);
        $this->info("Updated $mcCount records in payrolls_money_changer.");

        $this->info('THP update completed successfully!');
    }
}
