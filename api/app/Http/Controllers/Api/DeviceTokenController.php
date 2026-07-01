<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\AuditLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeviceTokenController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'fcm_token' => ['required', 'string', 'max:500'],
        ]);

        $user = $request->user();
        $user->update(['fcm_token' => $validated['fcm_token']]);

        AuditLogger::log($user, 'device.token_registered');

        return response()->json(['message' => 'Device token saved.']);
    }

    public function destroy(Request $request): JsonResponse
    {
        $request->user()->update(['fcm_token' => null]);

        return response()->json(['message' => 'Device token removed.']);
    }
}
