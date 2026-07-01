<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\Appointment;
use App\Models\DoctorAvailability;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class AppointmentController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $query = Appointment::query()
            ->with([
                'patient.user:id,name,email,phone',
                'doctor.user:id,name,email,phone',
                'availability',
            ])
            ->orderByDesc('scheduled_at');

        if ($user->isPatient() && $user->patient) {
            $query->where('patient_id', $user->patient->id);
        } elseif ($user->isDoctor() && $user->doctor) {
            $query->where('doctor_id', $user->doctor->id);
        } elseif ($user->isAdmin()) {
            // Admin sees all appointments but without sensitive consultation notes
        } else {
            return response()->json(['message' => 'Profile not found.'], 404);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }

        return response()->json($query->paginate(15));
    }

    public function store(Request $request): JsonResponse
    {
        $patient = $request->user()->patient;

        if (! $patient) {
            return response()->json(['message' => 'Patient profile not found.'], 404);
        }

        $validated = $request->validate([
            'doctor_id' => ['required', 'exists:doctors,id'],
            'availability_id' => ['required', 'exists:doctor_availability,id'],
            'type' => ['required', Rule::in(['in_person', 'video', 'chat'])],
            'reason' => ['nullable', 'string'],
            'urgency' => ['nullable', Rule::in(['low', 'medium', 'high', 'emergency'])],
        ]);

        try {
            $appointment = DB::transaction(function () use ($validated, $patient) {
                $slot = DoctorAvailability::query()
                    ->whereKey($validated['availability_id'])
                    ->where('doctor_id', $validated['doctor_id'])
                    ->lockForUpdate()
                    ->first();

                if (! $slot || $slot->status !== 'available') {
                    throw new \RuntimeException('This time slot is no longer available.');
                }

                $scheduledAt = $slot->date->format('Y-m-d').' '.$slot->start_time;

                $appointment = Appointment::create([
                    'patient_id' => $patient->id,
                    'doctor_id' => $validated['doctor_id'],
                    'availability_id' => $slot->id,
                    'scheduled_at' => $scheduledAt,
                    'type' => $validated['type'],
                    'status' => 'confirmed',
                    'reason' => $validated['reason'] ?? null,
                    'urgency' => $validated['urgency'] ?? null,
                ]);

                $slot->update(['status' => 'booked']);

                $doctorUser = $appointment->doctor->user;
                AppNotification::create([
                    'user_id' => $doctorUser->id,
                    'type' => 'appointment_booked',
                    'title' => 'New Appointment',
                    'body' => "New {$validated['type']} appointment booked for {$scheduledAt}.",
                ]);

                return $appointment;
            });
        } catch (\RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        $appointment->load([
            'patient.user:id,name,email,phone',
            'doctor.user:id,name,email,phone',
            'availability',
        ]);

        return response()->json($appointment, 201);
    }

    public function update(Request $request, Appointment $appointment): JsonResponse
    {
        $user = $request->user();

        if (! $this->canManageAppointment($user, $appointment)) {
            return response()->json(['message' => 'Forbidden.'], 403);
        }

        if ($appointment->status === 'cancelled') {
            return response()->json(['message' => 'Cannot reschedule a cancelled appointment.'], 422);
        }

        $validated = $request->validate([
            'availability_id' => ['required', 'exists:doctor_availability,id'],
            'type' => ['sometimes', Rule::in(['in_person', 'video', 'chat'])],
        ]);

        try {
            $appointment = DB::transaction(function () use ($validated, $appointment) {
                $newSlot = DoctorAvailability::query()
                    ->whereKey($validated['availability_id'])
                    ->where('doctor_id', $appointment->doctor_id)
                    ->lockForUpdate()
                    ->first();

                if (! $newSlot || $newSlot->status !== 'available') {
                    throw new \RuntimeException('The selected time slot is not available.');
                }

                if ($appointment->availability_id) {
                    DoctorAvailability::whereKey($appointment->availability_id)
                        ->update(['status' => 'available']);
                }

                $scheduledAt = $newSlot->date->format('Y-m-d').' '.$newSlot->start_time;

                $appointment->update([
                    'availability_id' => $newSlot->id,
                    'scheduled_at' => $scheduledAt,
                    'type' => $validated['type'] ?? $appointment->type,
                ]);

                $newSlot->update(['status' => 'booked']);

                return $appointment->fresh();
            });
        } catch (\RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        $appointment->load([
            'patient.user:id,name,email,phone',
            'doctor.user:id,name,email,phone',
            'availability',
        ]);

        return response()->json($appointment);
    }

    public function destroy(Request $request, Appointment $appointment): JsonResponse
    {
        $user = $request->user();

        if (! $this->canManageAppointment($user, $appointment)) {
            return response()->json(['message' => 'Forbidden.'], 403);
        }

        if ($appointment->status === 'cancelled') {
            return response()->json(['message' => 'Appointment is already cancelled.'], 422);
        }

        DB::transaction(function () use ($appointment) {
            $appointment->update(['status' => 'cancelled']);

            if ($appointment->availability_id) {
                DoctorAvailability::whereKey($appointment->availability_id)
                    ->update(['status' => 'available']);
            }
        });

        return response()->json(['message' => 'Appointment cancelled successfully.']);
    }

    private function canManageAppointment($user, Appointment $appointment): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        if ($user->isPatient() && $user->patient?->id === $appointment->patient_id) {
            return true;
        }

        if ($user->isDoctor() && $user->doctor?->id === $appointment->doctor_id) {
            return true;
        }

        return false;
    }
}
