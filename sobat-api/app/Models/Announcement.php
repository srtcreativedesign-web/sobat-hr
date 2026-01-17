<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Announcement extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'content',
        'category',
        'attachment_url',
        'is_published',
    ];

    protected $casts = [
        'is_published' => 'boolean',
    ];
}
