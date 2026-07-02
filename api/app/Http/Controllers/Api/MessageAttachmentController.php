<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MessageAttachmentController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'file' => ['required', 'file', 'mimes:jpeg,jpg,png,gif,webp', 'max:5120'],
        ]);

        $file = $validated['file'];
        $path = $file->store('message-attachments', 'public');
        $baseUrl = rtrim($request->getSchemeAndHttpHost(), '/');

        return response()->json([
            'path' => $path,
            'url' => $baseUrl.'/storage/'.$path,
            'mime_type' => $file->getMimeType(),
            'original_name' => $file->getClientOriginalName(),
        ], 201);
    }
}
