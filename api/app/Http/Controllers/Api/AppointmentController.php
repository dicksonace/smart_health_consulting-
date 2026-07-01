<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\StoreAppointmentRequest;
use App\Models\AppNotification;
use App\Models\Appointment;
use App\Models\Doctor;
use App\Models\DoctorAvailability;
use App\Services\AuditLogger;
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

    public function store(StoreAppointmentRequest $request): JsonResponse
    {
        $patient = $request->user()->patient;

        if (! $patient) {
            return response()->json(['message' => 'Patient profile not found.'], 404);
        }

        $validated = $request->validated();

        $doctor = Doctor::find($validated['doctor_id']);

        if (! $doctor || ! $doctor->is_verified || $doctor->is_suspended) {
            return response()->json(['message' => 'This doctor is not available for booking.'], 422);
        }

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

        AuditLogger::log($request->user(), 'appointment.created', Appointment::class, $appointment->id, [
            'doctor_id' => $appointment->doctor_id,
            'scheduled_at' => $appointment->scheduled_at,
        ]);

        $appointment->load([
            'patient.user:id,name,email,phone',
            'doctor.user:id,name,email,phone',
            'availability',
        ]);

        return response()->json($appointment, 201);
    }

    public function update(Request $request, Appointment $appointment): JsonResponse
    {
        $this->authorize('update', $appointment);

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

        AuditLogger::log($request->user(), 'appointment.rescheduled', Appointment::class, $appointment->id);

        $appointment->load([
            'patient.user:id,name,email,phone',
            'doctor.user:id,name,email,phone',
            'availability',
        ]);

        return response()->json($appointment);
    }

    public function destroy(Request $request, Appointment $appointment): JsonResponse
    {
        $this->authorize('delete', $appointment);

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

        AuditLogger::log($request->user(), 'appointment.cancelled', Appointment::class, $appointment->id);

        return response()->json(['message' => 'Appointment cancelled successfully.']);
    }
}
