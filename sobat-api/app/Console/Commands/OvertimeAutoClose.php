<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\RequestModel;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class OvertimeAutoClose extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'overtime:auto-close';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Automatically close SPL overtime tickets that exceed the 4-hour limit';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $requests = RequestModel::where('type', 'overtime')
            ->where('status', 'spl_open')
            ->with('overtimeDetail')
            ->get();

        $count = 0;
        $now = now()->timezone('Asia/Jakarta');

        foreach ($requests as $request) {
            $detail = $request->overtimeDetail;
            if (!$detail || !$detail->date || !$detail->start_time) continue;

            $startTime = Carbon::parse($detail->date->format('Y-m-d') . ' ' . $detail->start_time, 'Asia/Jakarta');
            $limitTime = clone $startTime;
            $limitTime->addHours(4);

            if ($now->greaterThanOrEqualTo($limitTime)) {
                // Auto close
                $request->update([
                    'status' => 'pending_final',
                    'amount' => 4, // 4 hours
                ]);

                $detail->update([
                    'end_time' => $limitTime->format('H:i:s'),
                    'duration' => 240,
                ]);

                Log::info("OvertimeAutoClose: Request ID {$request->id} auto-closed after 4 hours.");
                $count++;
            }
        }

        $this->info("Auto-closed {$count} overtime tickets.");
    }
}
