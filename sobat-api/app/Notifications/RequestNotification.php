<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class RequestNotification extends Notification
{
    use Queueable;

    protected $requestModel;
    protected $status;

    /**
     * Create a new notification instance.
     */
    public function __construct($requestModel, $status)
    {
        $this->requestModel = $requestModel;
        $this->status = $status;
    }

    /**
     * Get the notification's delivery channels.
     *
     * @return array<int, string>
     */
    public function via(object $notifiable): array
    {
        return ['database'];
    }

    /**
     * Get the array representation of the notification.
     *
     * @return array<string, mixed>
     */
    public function toArray(object $notifiable): array
    {
        $statusLabel = $this->status == 'approved' ? 'Disetujui' : 'Ditolak';
        $typeLabel = ucfirst($this->requestModel->type); // e.g., Leave -> Leave (or mapping if needed)
        
        // Map type to Indonesian if possible
        $typeMap = [
            'leave' => 'Cuti',
            'overtime' => 'Lembur',
            'reimbursement' => 'Reimbursement',
            'resignation' => 'Resign'
        ];
        $typeIndo = $typeMap[$this->requestModel->type] ?? $typeLabel;

        return [
            'id' => $this->requestModel->id,
            'type' => 'request',
            'title' => "Pengajuan $typeIndo $statusLabel",
            'message' => "Pengajuan $typeIndo Anda untuk tanggal " . $this->requestModel->start_date->format('d M Y') . " telah $statusLabel.",
            'status' => $this->status,
        ];
    }
}
