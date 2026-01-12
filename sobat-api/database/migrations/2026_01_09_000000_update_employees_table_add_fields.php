<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class UpdateEmployeesTableAddFields extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        // Add columns only if they don't already exist to avoid duplicate column errors
        if (!Schema::hasColumn('employees', 'place_of_birth')) {
            Schema::table('employees', function (Blueprint $table) {
                $table->string('place_of_birth')->nullable()->after('join_date');
            });
        }

        if (!Schema::hasColumn('employees', 'ktp_address')) {
            Schema::table('employees', function (Blueprint $table) {
                $table->text('ktp_address')->nullable()->after('address');
            });
        }

        if (!Schema::hasColumn('employees', 'current_address')) {
            Schema::table('employees', function (Blueprint $table) {
                $table->text('current_address')->nullable()->after('ktp_address');
            });
        }

        if (!Schema::hasColumn('employees', 'gender')) {
            Schema::table('employees', function (Blueprint $table) {
                $table->string('gender')->nullable()->after('current_address');
            });
        }

        if (!Schema::hasColumn('employees', 'religion')) {
            Schema::table('employees', function (Blueprint $table) {
                $table->string('religion')->nullable()->after('gender');
            });
        }

        if (!Schema::hasColumn('employees', 'marital_status')) {
            Schema::table('employees', function (Blueprint $table) {
                $table->string('marital_status')->nullable()->after('religion');
            });
        }

        if (!Schema::hasColumn('employees', 'ptkp_status')) {
            Schema::table('employees', function (Blueprint $table) {
                $table->string('ptkp_status')->nullable()->after('marital_status');
            });
        }

        if (!Schema::hasColumn('employees', 'nik')) {
            Schema::table('employees', function (Blueprint $table) {
                $table->string('nik')->nullable()->after('ptkp_status');
            });
        }

        if (!Schema::hasColumn('employees', 'npwp')) {
            Schema::table('employees', function (Blueprint $table) {
                $table->string('npwp')->nullable()->after('nik');
            });
        }

        if (!Schema::hasColumn('employees', 'bank_account_number')) {
            Schema::table('employees', function (Blueprint $table) {
                $table->string('bank_account_number')->nullable()->after('npwp');
            });
        }

        if (!Schema::hasColumn('employees', 'bank_account_name')) {
            Schema::table('employees', function (Blueprint $table) {
                $table->string('bank_account_name')->nullable()->after('bank_account_number');
            });
        }

        if (!Schema::hasColumn('employees', 'father_name')) {
            Schema::table('employees', function (Blueprint $table) {
                $table->string('father_name')->nullable()->after('bank_account_name');
            });
        }

        if (!Schema::hasColumn('employees', 'mother_name')) {
            Schema::table('employees', function (Blueprint $table) {
                $table->string('mother_name')->nullable()->after('father_name');
            });
        }

        if (!Schema::hasColumn('employees', 'spouse_name')) {
            Schema::table('employees', function (Blueprint $table) {
                $table->string('spouse_name')->nullable()->after('mother_name');
            });
        }

        if (!Schema::hasColumn('employees', 'family_contact_number')) {
            Schema::table('employees', function (Blueprint $table) {
                $table->string('family_contact_number')->nullable()->after('spouse_name');
            });
        }

        if (!Schema::hasColumn('employees', 'education')) {
            Schema::table('employees', function (Blueprint $table) {
                $table->string('education')->nullable()->after('family_contact_number');
            });
        }

        if (!Schema::hasColumn('employees', 'supervisor_name')) {
            Schema::table('employees', function (Blueprint $table) {
                $table->string('supervisor_name')->nullable()->after('education');
            });
        }

        if (!Schema::hasColumn('employees', 'supervisor_position')) {
            Schema::table('employees', function (Blueprint $table) {
                $table->string('supervisor_position')->nullable()->after('supervisor_name');
            });
        }

        if (!Schema::hasColumn('employees', 'photo_path')) {
            Schema::table('employees', function (Blueprint $table) {
                $table->string('photo_path')->nullable()->after('supervisor_position');
            });
        }
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        // Drop columns only if they exist
        $columns = [
            'place_of_birth',
            'ktp_address',
            'current_address',
            'gender',
            'religion',
            'marital_status',
            'ptkp_status',
            'nik',
            'npwp',
            'bank_account_number',
            'bank_account_name',
            'father_name',
            'mother_name',
            'spouse_name',
            'family_contact_number',
            'education',
            'supervisor_name',
            'supervisor_position',
            'photo_path',
        ];

        foreach ($columns as $col) {
            if (Schema::hasColumn('employees', $col)) {
                Schema::table('employees', function (Blueprint $table) use ($col) {
                    $table->dropColumn($col);
                });
            }
        }
    }
}
