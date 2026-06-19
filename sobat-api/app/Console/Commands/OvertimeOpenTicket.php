<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\RequestModel;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class OvertimeOpenTicket extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'overtime:open-ticket';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Automatically open SPL overtime tickets when their start time is reached';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $requests = RequestModel::where('type', 'overtime')
            ->where('status', 'spl_approved')
            ->with('overtimeDetail')
            ->get();

        $count = 0;
        $now = now()->timezone('Asia/Jakarta');

        foreach ($requests as $request) {
            $detail = $request->overtimeDetail;
            if (!$detail || !$detail->date || !$detail->start_time) continue;

            $startTime = Carbon::parse($detail->date->format('Y-m-d') . ' ' . $detail->start_time, 'Asia/Jakarta');

            if ($now->greaterThanOrEqualTo($startTime)) {
                $request->update(['status' => 'spl_open']);
                Log::info("OvertimeOpenTicket: Request ID {$request->id} opened automatically.");
                $count++;
            }
        }

        $this->info("Opened {$count} overtime tickets.");
    }
}
