<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use App\Models\Message;
use App\Models\User;
use App\Models\VideoCallSession;
use App\Services\RealtimeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class VideoCallController extends Controller
{
    public function show(Request $request, Appointment $appointment): JsonResponse
    {
        $this->authorize('view', $appointment);
        $this->ensureVideoAppointment($appointment);

        $appointment->loadMissing(['doctor.user:id,name,role', 'patient.user:id,name,role']);

        $scheduledAt = $appointment->scheduled_at;
        $opensAt = $scheduledAt->copy()->subHour();
        $closesAt = $scheduledAt->copy()->addHours(2);
        $now = now();
        $canJoin = $now->gte($opensAt) && $now->lte($closesAt)
            && in_array($appointment->status, ['confirmed', 'completed'], true);

        $user = $request->user();
        $doctorName = $appointment->doctor->user->name ?? 'Doctor';
        $patientName = $appointment->patient->user->name ?? 'Patient';
        $isDoctor = $user->role === 'doctor';
        $peerName = $isDoctor ? $patientName : $doctorName;
        $displayName = $user->name ?? 'Guest';
        $roomName = 'SmartHealth-Appt-'.$appointment->id;

        $joinUrl = sprintf(
            'https://meet.jit.si/%s#userInfo.displayName="%s"&config.prejoinConfig.enabled=false&config.disableDeepLinking=true',
            rawurlencode($roomName),
            rawurlencode($displayName),
        );

        $activeSession = VideoCallSession::query()
            ->where('appointment_id', $appointment->id)
            ->where('status', 'active')
            ->latest('started_at')
            ->first();

        $caller = null;
        $callee = null;
        if ($activeSession) {
            $starter = User::select('id', 'name', 'role')->find($activeSession->started_by);
            if ($starter) {
                $caller = [
                    'id' => $starter->id,
                    'name' => $starter->name,
                    'role' => $starter->role,
                ];
                $calleeUser = $starter->id === ($appointment->patient->user_id ?? null)
                    ? $appointment->doctor->user
                    : $appointment->patient->user;
                $callee = [
                    'id' => $calleeUser?->id,
                    'name' => $calleeUser?->name,
                    'role' => $calleeUser?->role,
                ];
            }
        }

        return response()->json([
            'appointment_id' => $appointment->id,
            'room_name' => $roomName,
            'join_url' => $joinUrl,
            'provider' => 'jitsi',
            'can_join' => $canJoin,
            'opens_at' => $opensAt->toIso8601String(),
            'closes_at' => $closesAt->toIso8601String(),
            'scheduled_at' => $scheduledAt->toIso8601String(),
            'doctor_name' => $doctorName,
            'patient_name' => $patientName,
            'peer_name' => $peerName,
            'display_name' => $displayName,
            'my_role' => $user->role,
            'active_session_id' => $activeSession?->id,
            'caller' => $caller,
            'callee' => $callee,
            'direction_label' => $caller && $callee
                ? $caller['name'].' called '.$callee['name']
                : null,
        ]);
    }

    public function start(Request $request, Appointment $appointment): JsonResponse
    {
        $this->authorize('view', $appointment);
        $this->ensureVideoAppointment($appointment);

        $appointment->loadMissing(['doctor.user:id,name,role', 'patient.user:id,name,role']);

        $existing = VideoCallSession::query()
            ->where('appointment_id', $appointment->id)
            ->where('status', 'active')
            ->latest('started_at')
            ->first();

        if ($existing) {
            $existing->loadMissing('starter:id,name,role');

            return response()->json([
                'session' => $existing,
                'message' => 'Call already in progress.',
                'joined_existing' => true,
                'direction_label' => $this->directionLabel($appointment, (int) $existing->started_by),
            ]);
        }

        $user = $request->user();
        [$callerName, $calleeName, $calleeRole] = $this->callerCallee($appointment, $user);

        $session = DB::transaction(function () use ($appointment, $user, $callerName, $calleeName, $calleeRole) {
            $session = VideoCallSession::create([
                'appointment_id' => $appointment->id,
                'started_by' => $user->id,
                'started_at' => now(),
                'status' => 'active',
            ]);

            $body = $callerName.' called '.$calleeName;

            $this->createCallMessage(
                appointment: $appointment,
                senderId: $user->id,
                type: 'call_started',
                body: $body,
                metadata: [
                    'appointment_id' => $appointment->id,
                    'session_id' => $session->id,
                    'caller_id' => $user->id,
                    'caller_name' => $callerName,
                    'caller_role' => $user->role,
                    'callee_name' => $calleeName,
                    'callee_role' => $calleeRole,
                    'direction_label' => $body,
                ],
            );

            return $session;
        });

        return response()->json([
            'session' => $session,
            'message' => 'Call started.',
            'joined_existing' => false,
            'direction_label' => $callerName.' called '.$calleeName,
        ], 201);
    }

    public function end(Request $request, Appointment $appointment): JsonResponse
    {
        $this->authorize('view', $appointment);
        $this->ensureVideoAppointment($appointment);

        $appointment->loadMissing(['doctor.user:id,name,role', 'patient.user:id,name,role']);

        $validated = $request->validate([
            'session_id' => ['nullable', 'integer'],
            'reason' => ['nullable', 'string', 'max:50'],
        ]);

        $sessionQuery = VideoCallSession::query()
            ->where('appointment_id', $appointment->id)
            ->where('status', 'active');

        if (! empty($validated['session_id'])) {
            $sessionQuery->where('id', $validated['session_id']);
        }

        $session = $sessionQuery->latest('started_at')->first();

        if (! $session) {
            return response()->json([
                'message' => 'No active call session found.',
                'already_ended' => true,
            ]);
        }

        $user = $request->user();
        $endedAt = now();
        $duration = max(0, (int) $session->started_at->diffInSeconds($endedAt));
        $reason = $validated['reason'] ?? 'hangup';
        $direction = $this->directionLabel($appointment, (int) $session->started_by);

        DB::transaction(function () use ($session, $user, $endedAt, $duration, $appointment, $reason, $direction) {
            $session->update([
                'ended_by' => $user->id,
                'ended_at' => $endedAt,
                'duration_seconds' => $duration,
                'status' => 'ended',
            ]);

            $starter = User::select('id', 'name', 'role')->find($session->started_by);
            [$callerName, $calleeName, $calleeRole] = $this->callerCallee(
                $appointment,
                $starter ?? $user,
            );

            $body = sprintf(
                '%s · %s · Ended by %s',
                $direction,
                $this->formatDuration($duration),
                $user->name,
            );

            $this->createCallMessage(
                appointment: $appointment,
                senderId: $user->id,
                type: 'call_ended',
                body: $body,
                metadata: [
                    'appointment_id' => $appointment->id,
                    'session_id' => $session->id,
                    'duration_seconds' => $duration,
                    'ended_by_name' => $user->name,
                    'ended_by_role' => $user->role,
                    'reason' => $reason,
                    'caller_name' => $callerName,
                    'caller_role' => $starter?->role ?? $user->role,
                    'callee_name' => $calleeName,
                    'callee_role' => $calleeRole,
                    'direction_label' => $direction,
                ],
            );
        });

        return response()->json([
            'session' => $session->fresh(),
            'message' => 'Call ended.',
            'direction_label' => $direction,
        ]);
    }

    private function ensureVideoAppointment(Appointment $appointment): void
    {
        if ($appointment->type !== 'video') {
            abort(422, 'This appointment is not a video consultation.');
        }

        if (! in_array($appointment->status, ['confirmed', 'completed'], true)) {
            abort(422, 'Video room is not available for this appointment status.');
        }
    }

    /**
     * @return array{0: string, 1: string, 2: string}
     */
    private function callerCallee(Appointment $appointment, User $caller): array
    {
        $patient = $appointment->patient?->user;
        $doctor = $appointment->doctor?->user;

        if ($caller->id === ($patient?->id)) {
            return [
                $patient?->name ?? 'Patient',
                $doctor?->name ?? 'Doctor',
                $doctor?->role ?? 'doctor',
            ];
        }

        return [
            $doctor?->name ?? $caller->name,
            $patient?->name ?? 'Patient',
            $patient?->role ?? 'patient',
        ];
    }

    private function directionLabel(Appointment $appointment, int $startedBy): string
    {
        $starter = User::select('id', 'name', 'role')->find($startedBy);
        if (! $starter) {
            return 'Video call';
        }

        [$callerName, $calleeName] = $this->callerCallee($appointment, $starter);

        return $callerName.' called '.$calleeName;
    }

    private function createCallMessage(
        Appointment $appointment,
        int $senderId,
        string $type,
        string $body,
        array $metadata,
    ): void {
        $patientUserId = $appointment->patient?->user_id;
        $doctorUserId = $appointment->doctor?->user_id;

        if (! $patientUserId || ! $doctorUserId) {
            return;
        }

        $receiverId = $senderId === $patientUserId ? $doctorUserId : $patientUserId;

        $message = Message::create([
            'sender_id' => $senderId,
            'receiver_id' => $receiverId,
            'body' => $body,
            'message_type' => $type,
            'metadata' => $metadata,
        ]);

        RealtimeService::push($receiverId, 'new_message', [
            'sender_id' => $senderId,
            'message_id' => $message->id,
            'partner_id' => $senderId,
            'body_preview' => $body,
            'message_type' => $type,
        ]);
    }

    private function formatDuration(int $seconds): string
    {
        if ($seconds < 60) {
            return $seconds.'s';
        }

        $minutes = intdiv($seconds, 60);
        $remain = $seconds % 60;

        if ($minutes < 60) {
            return $remain > 0 ? "{$minutes}m {$remain}s" : "{$minutes}m";
        }

        $hours = intdiv($minutes, 60);
        $mins = $minutes % 60;

        return $mins > 0 ? "{$hours}h {$mins}m" : "{$hours}h";
    }
}
