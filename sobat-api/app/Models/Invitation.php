<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Invitation extends Model
{
    protected $fillable = [
        'email',
        'name',
        'payload',
        'token',
        'status',
        'error_message',
        'expires_at',
        'password_generated_at',
        'password_encrypted',
        'role',
        'organization_id',
    ];

    protected $casts = [
        'payload' => 'array',
        'expires_at' => 'datetime',
        'password_generated_at' => 'datetime',
    ];

    public function organization()
    {
        return $this->belongsTo(Organization::class);
    }
}
