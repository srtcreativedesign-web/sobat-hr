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
    protected $description = 'Automatically cancel SPL overtime tickets if not started within 2 hours of schedule';

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
            $cancelTime = $startTime->copy()->addHours(2);

            if ($now->greaterThanOrEqualTo($cancelTime)) {
                $request->update(['status' => 'cancelled']);
                Log::info("OvertimeOpenTicket: Request ID {$request->id} cancelled automatically because employee did not start it within 2 hours.");
                $count++;
            }
        }

        $this->info("Cancelled {$count} missed overtime tickets.");
    }
}
