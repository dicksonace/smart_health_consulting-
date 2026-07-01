<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class StoreConsultationRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->isDoctor() ?? false;
    }

    public function rules(): array
    {
        return [
            'appointment_id' => ['required', 'exists:appointments,id'],
            'diagnosis' => ['nullable', 'string'],
            'notes' => ['nullable', 'string'],
            'recommendations' => ['nullable', 'string'],
            'prescriptions' => ['nullable', 'array'],
            'prescriptions.*.medicine_name' => ['required_with:prescriptions', 'string', 'max:255'],
            'prescriptions.*.dosage' => ['required_with:prescriptions', 'string', 'max:255'],
            'prescriptions.*.duration' => ['required_with:prescriptions', 'string', 'max:255'],
            'prescriptions.*.instructions' => ['nullable', 'string'],
        ];
    }
}
