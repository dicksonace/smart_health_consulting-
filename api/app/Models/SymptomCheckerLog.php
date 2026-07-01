<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SymptomCheckerLog extends Model
{
    protected $fillable = [
        'patient_id',
        'symptoms',
        'suggested_specialty',
        'urgency',
    ];

    protected function casts(): array
    {
        return [
            'symptoms' => 'array',
        ];
    }

    public function patient(): BelongsTo
    {
        return $this->belongsTo(Patient::class);
    }
}
