<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VideoCallController extends Controller
{
    public function show(Request $request, Appointment $appointment): JsonResponse
    {
        $this->authorize('view', $appointment);

        if ($appointment->type !== 'video') {
            return response()->json(['message' => 'This appointment is not a video consultation.'], 422);
        }

        if (! in_array($appointment->status, ['confirmed', 'completed'], true)) {
            return response()->json(['message' => 'Video room is not available for this appointment status.'], 422);
        }

        $scheduledAt = $appointment->scheduled_at;
        $opensAt = $scheduledAt->copy()->subMinutes(5);
        $closesAt = $scheduledAt->copy()->addHour();
        $now = now();

        $roomName = 'SmartHealth-Appt-'.$appointment->id;

        return response()->json([
            'appointment_id' => $appointment->id,
            'room_name' => $roomName,
            'join_url' => 'https://meet.jit.si/'.$roomName,
            'provider' => 'jitsi',
            'can_join' => $now->gte($opensAt) && $now->lte($closesAt),
            'opens_at' => $opensAt->toIso8601String(),
            'closes_at' => $closesAt->toIso8601String(),
            'scheduled_at' => $scheduledAt->toIso8601String(),
            'doctor_name' => $appointment->doctor->user->name ?? null,
            'patient_name' => $appointment->patient->user->name ?? null,
        ]);
    }
}
