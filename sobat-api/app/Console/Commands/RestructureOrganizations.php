<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Organization;
use Illuminate\Support\Facades\DB;

class RestructureOrganizations extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'org:restructure';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Restructure organization hierarchy to new Holding structure';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('Starting Organization Restructure...');

        DB::beginTransaction();

        try {
            // 1. Create Top Level Directors
            $dirUtama = Organization::firstOrCreate(
                ['name' => 'Direktur Utama'],
                ['code' => 'CEO', 'type' => 'headquarters']
            );

            $dirOps = Organization::firstOrCreate(
                ['name' => 'Direktur Operasional'],
                [
                    'code' => 'COO',
                    'type' => 'headquarters',
                    'parent_id' => $dirUtama->id
                ]
            );

            // "Direktur Keuangan" also created under Dir Utama as per request text structure
            // "direktur utama, membawahi direktur operasional dan direktur keuangan"
            $dirKeuangan = Organization::firstOrCreate(
                ['name' => 'Direktur Keuangan'],
                [
                    'code' => 'CFO',
                    'type' => 'headquarters',
                    'parent_id' => $dirUtama->id
                ]
            );

            // 2. Create Holding Group under Dir Ops
            $holdingGroup = Organization::firstOrCreate(
                ['name' => 'Holding Group'], // Distinct name to avoid confusion with "Holding" division
                [
                    'code' => 'HOLDING_GRP',
                    'type' => 'headquarters', // or branch?
                    'parent_id' => $dirOps->id
                ]
            );

            // 3. Create Holdings I - IV
            $holding1 = Organization::firstOrCreate(['name' => 'Holding I'], ['code' => 'H1', 'type' => 'branch', 'parent_id' => $holdingGroup->id]);
            $holding2 = Organization::firstOrCreate(['name' => 'Holding II'], ['code' => 'H2', 'type' => 'branch', 'parent_id' => $holdingGroup->id]);
            $holding3 = Organization::firstOrCreate(['name' => 'Holding III'], ['code' => 'H3', 'type' => 'branch', 'parent_id' => $holdingGroup->id]);
            $holding4 = Organization::firstOrCreate(['name' => 'Holding IV'], ['code' => 'H4', 'type' => 'branch', 'parent_id' => $holdingGroup->id]);

            $this->info('Created Structure: Dir Utama -> Dir Ops -> Holding Group -> Holdings I-IV');

            // 4. Move Specific Divisions

            // HCM Group -> Holding II
            // Include: HR, TnD (Training), IT Development
            $hcmDivisions = ['HR', 'TnD', 'IT Development', 'Human Capital'];
            foreach ($hcmDivisions as $name) {
                $div = Organization::where('name', 'LIKE', "%$name%")->get();
                foreach ($div as $d) {
                    $d->update(['parent_id' => $holding2->id]);
                    $this->info("Moved {$d->name} to Holding II");
                }
            }

            // Finance Group -> Holding III
            // Include: FAT, Finance, Accounting
            $financeDivisions = ['FAT', 'Finance', 'Accounting', 'Tax', 'Keuangan'];
            foreach ($financeDivisions as $name) {
                // Exclude "Direktur Keuangan" from this move preventing loop (though name checks alleviate this)
                $div = Organization::where('name', 'LIKE', "%$name%")
                    ->where('id', '!=', $dirKeuangan->id)
                    ->get();
                foreach ($div as $d) {
                    $d->update(['parent_id' => $holding3->id]);
                    $this->info("Moved {$d->name} to Holding III");
                }
            }

            // 5. Move All Other Operational Divisions -> Holding I
            // Get all organizations that are NOT:
            // - The new structure nodes we just created
            // - Already moved to H2 or H3
            // - The 'Holding' division legacy node itself (maybe rename or delete it?)

            // Let's grab everything that is a Child of NULL (old roots) or Child of old Holding
            // And is NOT in our new structure list.

            $structureIds = [
                $dirUtama->id,
                $dirOps->id,
                $dirKeuangan->id,
                $holdingGroup->id,
                $holding1->id,
                $holding2->id,
                $holding3->id,
                $holding4->id
            ];

            $orphans = Organization::whereNotIn('id', $structureIds)
                ->whereNotIn('parent_id', [$holding2->id, $holding3->id]) // Not already moved
                ->get();

            foreach ($orphans as $orphan) {
                // Skip if it's the legacy "Holding" division that might have been a root, 
                // we might want to just incorporate it or delete it. 
                // If the user had a division named "Holding", it likely represents the group. 
                // Let's assume actual working divisions are what we want.

                if ($orphan->name === 'Holding') {
                    // Maybe skip or delete? Let's skip and let user clean up manually
                    continue;
                }

                $orphan->update(['parent_id' => $holding1->id]);
                $this->info("Moved {$orphan->name} to Holding I");
            }

            DB::commit();
            $this->info('Organization Restructure Completed Successfully.');

        } catch (\Exception $e) {
            DB::rollBack();
            $this->error('Restructure Failed: ' . $e->getMessage());
        }
    }
}
