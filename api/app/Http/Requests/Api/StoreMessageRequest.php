<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Validator;

class StoreMessageRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            'receiver_id' => ['required', 'exists:users,id'],
            'body' => ['nullable', 'string', 'max:5000'],
            'attachment_path' => ['nullable', 'string', 'max:500', 'starts_with:message-attachments/'],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator) {
            $body = trim((string) $this->input('body', ''));
            $attachmentPath = $this->input('attachment_path');

            if ($body === '' && empty($attachmentPath)) {
                $validator->errors()->add('body', 'A message body or attachment is required.');
            }

            if ($attachmentPath && ! Storage::disk('public')->exists($attachmentPath)) {
                $validator->errors()->add('attachment_path', 'The attachment could not be found.');
            }
        });
    }
}
