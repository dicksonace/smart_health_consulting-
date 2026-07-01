<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreAppointmentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->isPatient() ?? false;
    }

    public function rules(): array
    {
        return [
            'doctor_id' => ['required', 'exists:doctors,id'],
            'availability_id' => ['required', 'exists:doctor_availability,id'],
            'type' => ['required', Rule::in(['in_person', 'video', 'chat'])],
            'reason' => ['nullable', 'string'],
            'urgency' => ['nullable', Rule::in(['low', 'medium', 'high', 'emergency'])],
        ];
    }
}
