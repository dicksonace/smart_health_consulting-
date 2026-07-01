<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\RealtimeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RealtimeController extends Controller
{
    public function poll(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'since' => ['nullable', 'date'],
            'doctor_id' => ['nullable', 'integer', 'exists:doctors,id'],
        ]);

        $since = isset($validated['since'])
            ? \Carbon\Carbon::parse($validated['since'])->toDateTimeString()
            : null;

        $events = RealtimeService::poll(
            $request->user()->id,
            $since,
            $validated['doctor_id'] ?? null,
        );

        return response()->json([
            'events' => $events,
            'server_time' => now()->toIso8601String(),
        ]);
    }
}
