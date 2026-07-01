<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Doctor extends Model
{
    protected $fillable = [
        'user_id',
        'specialty',
        'qualifications',
        'years_experience',
        'consultation_fee',
        'bio',
        'is_verified',
        'is_suspended',
        'rating_avg',
    ];

    protected function casts(): array
    {
        return [
            'consultation_fee' => 'decimal:2',
            'is_verified' => 'boolean',
            'is_suspended' => 'boolean',
            'rating_avg' => 'decimal:2',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function availability(): HasMany
    {
        return $this->hasMany(DoctorAvailability::class);
    }

    public function appointments(): HasMany
    {
        return $this->hasMany(Appointment::class);
    }
}
