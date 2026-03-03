<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Announcement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class AnnouncementController extends Controller
{
    public function index(Request $request)
    {
        $query = Announcement::latest();

        if ($request->has('category')) {
            $query->where('category', $request->category);
        }

        $announcements = $query->get();

        // Append base URL if path exists
        $announcements->transform(function ($item) {
            if ($item->image_path) {
                $item->image_url = url('storage/' . $item->image_path);
            }
            return $item;
        });

        return response()->json([
            'success' => true,
            'data' => $announcements
        ]);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'image' => 'nullable|image|mimes:jpg,jpeg,png|max:5120', 
            'category' => 'in:news,policy',
            'description' => 'nullable|string',
            'attachment' => 'nullable|file|mimes:pdf,doc,docx,jpg,jpeg,png|max:10240', // 10MB
            'is_active' => 'boolean',
            'is_banner' => 'boolean',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation Error',
                'errors' => $validator->errors()
            ], 422);
        }

        $imagePath = null;
        if ($request->hasFile('image')) {
            $photo = $request->file('image');
            $filename = uniqid() . '_' . time() . '.jpg';
            $path = 'announcements/' . $filename;
            $fullPath = storage_path('app/public/' . $path);

            $this->resizeAndSaveImage($photo->getPathname(), $fullPath, 1024, 75);
            $imagePath = $path;
        }

        $attachmentUrl = null;
        if ($request->hasFile('attachment')) {
            $attachmentUrl = $request->file('attachment')->store('attachments', 'public');
        }

        $announcement = Announcement::create([
            'title' => $request->title,
            'description' => $request->description,
            'image_path' => $imagePath,
            'category' => $request->category ?? 'news',
            'attachment_url' => $attachmentUrl,
            'is_active' => $request->boolean('is_active', true),
            'is_banner' => $request->boolean('is_banner', false),
            'start_date' => $request->start_date,
            'end_date' => $request->end_date,
        ]);

        // Send Push Notification via FCM
        try {
            $fcm = new \App\Services\FcmService();
            $fcm->broadcastNotification(
                "Pengumuman Baru: " . $announcement->title,
                strip_tags(mb_strimwidth($announcement->description, 0, 100, "..."))
            );
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error('Gagal mengirim broadcast FCM: ' . $e->getMessage());
        }

        return response()->json([
            'success' => true,
            'message' => 'Announcement created successfully',
            'data' => $announcement
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $announcement = Announcement::find($id);
        if (!$announcement) {
            return response()->json(['success' => false, 'message' => 'Not found'], 404);
        }

        $validator = Validator::make($request->all(), [
            'title' => 'sometimes|string|max:255',
            'image' => 'nullable|image|mimes:jpg,jpeg,png|max:5120',
            'description' => 'nullable|string',
            'category' => 'sometimes|in:news,policy',
            'attachment' => 'nullable|file|mimes:pdf,doc,docx,jpg,jpeg,png|max:10240',
            'is_active' => 'sometimes|boolean',
            'is_banner' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        if ($request->hasFile('image')) {
            // Delete old image
            if ($announcement->image_path) {
                Storage::disk('public')->delete($announcement->image_path);
            }
            
            $photo = $request->file('image');
            $filename = uniqid() . '_' . time() . '.jpg';
            $path = 'announcements/' . $filename;
            $fullPath = storage_path('app/public/' . $path);

            $this->resizeAndSaveImage($photo->getPathname(), $fullPath, 1024, 75);
            $announcement->image_path = $path;
        }

        if ($request->hasFile('attachment')) {
            // Delete old attachment
            if ($announcement->attachment_url) {
                Storage::disk('public')->delete($announcement->attachment_url);
            }
            $announcement->attachment_url = $request->file('attachment')->store('attachments', 'public');
        }

        $announcement->update($request->except(['image', 'attachment']));

        return response()->json([
            'success' => true,
            'message' => 'Announcement updated',
            'data' => $announcement
        ]);
    }

    public function destroy($id)
    {
        $announcement = Announcement::find($id);
        if (!$announcement) {
            return response()->json(['success' => false, 'message' => 'Not found'], 404);
        }

        if ($announcement->image_path) {
            Storage::disk('public')->delete($announcement->image_path);
        }

        $announcement->delete();

        return response()->json([
            'success' => true,
            'message' => 'Announcement deleted'
        ]);
    }

    public function getActive()
    {
        $now = now()->toDateString();
        // Only fetch items where is_banner is true
        $announcement = Announcement::where('is_active', true)
            ->where('is_banner', true)
            ->where(function ($query) use ($now) {
                $query->whereNull('end_date')
                      ->orWhere('end_date', '>=', $now);
            })
            ->latest()
            ->first();

        // Append base URL if path exists
        if ($announcement && $announcement->image_path) {
            $announcement->image_url = url('storage/' . $announcement->image_path);
        }

        return response()->json([
            'success' => true,
            'data' => $announcement
        ]);
    }

    private function resizeAndSaveImage($sourcePath, $destinationPath, $maxWidth, $quality)
    {
        list($width, $height, $type) = getimagesize($sourcePath);
        
        switch ($type) {
            case IMAGETYPE_JPEG:
                $sourceImage = imagecreatefromjpeg($sourcePath);
                break;
            case IMAGETYPE_PNG:
                $sourceImage = imagecreatefrompng($sourcePath);
                break;
            default:
                copy($sourcePath, $destinationPath);
                return;
        }

        if ($width > $maxWidth) {
            $newWidth = $maxWidth;
            $newHeight = ($height / $width) * $newWidth;
        } else {
            $newWidth = $width;
            $newHeight = $height;
        }

        $newImage = imagecreatetruecolor($newWidth, $newHeight);
        if ($type == IMAGETYPE_PNG) {
            imagealphablending($newImage, false);
            imagesavealpha($newImage, true);
        }

        imagecopyresampled($newImage, $sourceImage, 0, 0, 0, 0, $newWidth, $newHeight, $width, $height);
        $directory = dirname($destinationPath);
        if (!file_exists($directory)) {
            mkdir($directory, 0755, true);
        }

        imagejpeg($newImage, $destinationPath, $quality);
        imagedestroy($sourceImage);
        imagedestroy($newImage);
    }
}
