<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'phone' => ['nullable', 'string', 'max:20'],
            'role' => ['required', Rule::in(['patient', 'doctor'])],
            'specialty' => ['required_if:role,doctor', 'string', 'max:255'],
            'consultation_fee' => ['required_if:role,doctor', 'numeric', 'min:0'],
            'qualifications' => ['nullable', 'string'],
            'years_experience' => ['nullable', 'integer', 'min:0'],
            'bio' => ['nullable', 'string'],
            'date_of_birth' => ['nullable', 'date'],
            'gender' => ['nullable', 'string', 'max:50'],
            'blood_group' => ['nullable', 'string', 'max:10'],
            'allergies' => ['nullable', 'string'],
            'medical_summary' => ['nullable', 'string'],
        ];
    }
}
