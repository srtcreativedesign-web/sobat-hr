<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Http\Client\Response;

class GroqAiService
{
    private string $apiKey;
    private string $baseUrl = 'https://api.groq.com/openai/v1';

    public function __construct()
    {
        $this->apiKey = env('GROQ_API_KEY', '');
    }

    /**
     * Generate personalized payslip message using Groq AI
     */
    public function generatePayslipMessage(array $payrollData): string
    {
        $employeeName = $payrollData['employee_name'];
        $period = $payrollData['period'];
        $basicSalary = number_format($payrollData['basic_salary'], 0, ',', '.');
        $overtime = number_format($payrollData['overtime'] ?? 0, 0, ',', '.');
        $netSalary = number_format($payrollData['net_salary'], 0, ',', '.');
        
        // Calculate Tenure if join_date provided
        $tenureInfo = "";
        if (!empty($payrollData['join_date'])) {
            try {
                $joinDate = \Carbon\Carbon::parse($payrollData['join_date']);
                $now = \Carbon\Carbon::now();
                $diff = $joinDate->diff($now);
                
                $tenureString = [];
                if ($diff->y > 0) $tenureString[] = "{$diff->y} tahun";
                if ($diff->m > 0) $tenureString[] = "{$diff->m} bulan";
                
                if (empty($tenureString)) {
                    $tenure = "kurang dari 1 bulan";
                } else {
                    $tenure = implode(" ", $tenureString);
                }
                
                $tenureInfo = "Lama Bekerja: {$tenure} (sejak {$joinDate->format('d M Y')})";
            } catch (\Exception $e) {
                // Ignore parse error
            }
        }
        
        $prompt = "Kamu adalah asisten HR yang ramah. Buatkan pesan singkat dan personal untuk slip gaji karyawan dengan data berikut:
        
Nama: {$employeeName}
Periode: {$period}
Gaji Pokok: Rp {$basicSalary}
Take Home Pay: Rp {$netSalary}
{$tenureInfo}

Buatkan:
1. Ucapan apresiasi singkat (1-2 kalimat)
2. Sebutkan masa kerja karyawan ({$tenure}) sebagai bentuk apresiasi loyalitas (1 kalimat)
3. harapan perusahaan untuk karyawan (1 kalimat)

Gunakan bahasa Indonesia yang hangat dan profesional. Maksimal 150 kata.";

        try {
            /** @var Response $response */
            $response = Http::timeout(15)
                ->withHeaders([
                    'Authorization' => 'Bearer ' . $this->apiKey,
                    'Content-Type' => 'application/json',
                ])
                ->post($this->baseUrl . '/chat/completions', [
                    'model' => 'llama-3.3-70b-versatile',
                    'messages' => [
                        [
                            'role' => 'user',
                            'content' => $prompt,
                        ],
                    ],
                    'temperature' => 0.7,
                    'max_tokens' => 300,
                ]);

            if ($response->successful()) {
                $data = $response->json();
                if (isset($data['choices'][0]['message']['content'])) {
                    return trim($data['choices'][0]['message']['content']);
                }
            }

            Log::warning('Groq API failed', [
                'status' => $response->status(),
                'body' => $response->body()
            ]);
            return $this->getFallbackMessage($employeeName);

        } catch (\Exception $e) {
            Log::error('Groq AI Service Error', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return $this->getFallbackMessage($employeeName);
        }
    }

    /**
     * Fallback message if AI fails
     */
    private function getFallbackMessage(string $employeeName): string
    {
        return "Terima kasih atas dedikasi dan kerja keras Anda, {$employeeName}. Slip gaji ini mencerminkan kontribusi Anda selama periode ini. Silakan periksa detail pembayaran dan hubungi HR jika ada pertanyaan.";
    }
}
