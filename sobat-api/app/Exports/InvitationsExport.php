<?php

namespace App\Exports;

use App\Models\Invitation;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use App\Traits\ExcelSanitizer;

class InvitationsExport implements FromCollection, WithHeadings, WithMapping
{
    use ExcelSanitizer;

    public function collection()
    {
        return Invitation::where('status', 'pending')
            ->orderBy('created_at', 'desc')
            ->get();
    }

    public function headings(): array
    {
        return [
            'Name',
            'Email',
            'Activation Link',
        ];
    }

    public function map($invitation): array
    {
        // Hardcoded frontend URL based on user environment
        $frontendUrl = env('FRONTEND_URL', 'http://localhost:3000');
        $link = "{$frontendUrl}/register?token={$invitation->token}";

        return $this->sanitizeArray([
            $invitation->name,
            $invitation->email,
            $link,
        ]);
    }
}
