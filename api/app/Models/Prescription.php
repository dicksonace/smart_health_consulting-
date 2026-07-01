<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Prescription extends Model
{
    protected $fillable = [
        'consultation_record_id',
        'medicine_name',
        'dosage',
        'duration',
        'instructions',
    ];

    public function consultationRecord(): BelongsTo
    {
        return $this->belongsTo(ConsultationRecord::class);
    }
}
