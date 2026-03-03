<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;
use App\Models\Employee;
use App\Models\Attendance;
use App\Models\Announcement;

class CleanupOrphanedFiles extends Command
{
    protected $signature = 'cleanup:files';
    protected $description = 'Remove files in storage that are no longer referenced in the database';

    public function handle()
    {
        $this->info('Starting file cleanup...');

        // 1. Cleanup Avatars
        $this->cleanupFolder('avatars', Employee::pluck('photo_path')->filter()->toArray());

        // 2. Cleanup Attendance Photos
        $attendancePhotos = Attendance::pluck('photo_path')
            ->concat(Attendance::pluck('checkout_photo_path'))
            ->filter()
            ->toArray();
        $this->cleanupFolder('attendance_photos', $attendancePhotos);

        // 3. Cleanup Announcement Images
        $this->cleanupFolder('announcements', Announcement::pluck('image_path')->filter()->toArray());

        $this->info('Cleanup completed!');
    }

    private function cleanupFolder($folder, $referencedFiles)
    {
        $allFiles = Storage::disk('public')->files($folder);
        $count = 0;

        foreach ($allFiles as $file) {
            if (!in_array($file, $referencedFiles)) {
                Storage::disk('public')->delete($file);
                $count++;
            }
        }

        $this->line("Cleaned up {$count} orphaned files from '{$folder}'.");
    }
}
