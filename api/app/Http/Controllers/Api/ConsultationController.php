<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\StoreConsultationRequest;
use App\Models\Appointment;
use App\Models\ConsultationRecord;
use App\Models\Prescription;
use App\Services\AuditLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class ConsultationController extends Controller
{
    public function store(StoreConsultationRequest $request): JsonResponse
    {
        $doctor = $request->user()->doctor;

        if (! $doctor) {
            return response()->json(['message' => 'Doctor profile not found.'], 404);
        }

        $validated = $request->validated();
        $appointment = Appointment::findOrFail($validated['appointment_id']);

        if ($appointment->doctor_id !== $doctor->id) {
            return response()->json(['message' => 'Forbidden.'], 403);
        }

        if ($appointment->consultationRecord) {
            return response()->json(['message' => 'Consultation record already exists for this appointment.'], 422);
        }

        $record = DB::transaction(function () use ($validated, $appointment) {
            $record = ConsultationRecord::create([
                'appointment_id' => $appointment->id,
                'diagnosis' => $validated['diagnosis'] ?? null,
                'notes' => $validated['notes'] ?? null,
                'recommendations' => $validated['recommendations'] ?? null,
            ]);

            foreach ($validated['prescriptions'] ?? [] as $rx) {
                Prescription::create([
                    'consultation_record_id' => $record->id,
                    'medicine_name' => $rx['medicine_name'],
                    'dosage' => $rx['dosage'],
                    'duration' => $rx['duration'],
                    'instructions' => $rx['instructions'] ?? null,
                ]);
            }

            $appointment->update(['status' => 'completed']);

            return $record;
        });

        AuditLogger::log($request->user(), 'consultation.created', ConsultationRecord::class, $record->id, [
            'appointment_id' => $appointment->id,
            'patient_id' => $appointment->patient_id,
        ]);

        $record->load('prescriptions');

        return response()->json($record, 201);
    }
}
