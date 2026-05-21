<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $mcDivision = DB::table('divisions')->where('name', 'Money Changer')->value('id');

        if ($mcDivision) {
            DB::table('attendances')
                ->where('track_type', 'head_office')
                ->whereIn('employee_id', function ($q) use ($mcDivision) {
                    $q->select('id')->from('employees')->where('division_id', $mcDivision);
                })
                ->update([
                    'track_type' => 'operational',
                    'validation_method' => 'qr_code',
                ]);
        }
    }

    public function down(): void
    {
        $mcDivision = DB::table('divisions')->where('name', 'Money Changer')->value('id');

        if ($mcDivision) {
            DB::table('attendances')
                ->where('track_type', 'operational')
                ->whereIn('employee_id', function ($q) use ($mcDivision) {
                    $q->select('id')->from('employees')->where('division_id', $mcDivision);
                })
                ->update([
                    'track_type' => 'head_office',
                    'validation_method' => 'gps',
                ]);
        }
    }
};
