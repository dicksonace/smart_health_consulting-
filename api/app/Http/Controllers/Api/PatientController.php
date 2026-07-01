<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ConsultationRecord;
use App\Models\Prescription;
use App\Services\AuditLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PatientController extends Controller
{
    public function profile(Request $request): JsonResponse
    {
        $patient = $request->user()->patient;

        if (! $patient) {
            return response()->json(['message' => 'Patient profile not found.'], 404);
        }

        $patient->load('user:id,name,email,phone,role');

        return response()->json($patient);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $patient = $request->user()->patient;

        if (! $patient) {
            return response()->json(['message' => 'Patient profile not found.'], 404);
        }

        $validated = $request->validate([
            'date_of_birth' => ['nullable', 'date'],
            'gender' => ['nullable', 'string', 'max:50'],
            'blood_group' => ['nullable', 'string', 'max:10'],
            'allergies' => ['nullable', 'string'],
            'medical_summary' => ['nullable', 'string'],
            'name' => ['sometimes', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:20'],
        ]);

        if (isset($validated['name']) || array_key_exists('phone', $validated)) {
            $request->user()->update(array_filter([
                'name' => $validated['name'] ?? null,
                'phone' => $validated['phone'] ?? null,
            ], fn ($v) => $v !== null));
        }

        $patient->update(collect($validated)->except(['name', 'phone'])->filter()->all());
        $patient->load('user:id,name,email,phone,role');

        return response()->json($patient);
    }

    public function records(Request $request): JsonResponse
    {
        $patient = $request->user()->patient;

        if (! $patient) {
            return response()->json(['message' => 'Patient profile not found.'], 404);
        }

        $records = ConsultationRecord::query()
            ->whereHas('appointment', fn ($q) => $q->where('patient_id', $patient->id))
            ->with([
                'appointment.doctor.user:id,name',
                'appointment' => fn ($q) => $q->select('id', 'doctor_id', 'patient_id', 'scheduled_at', 'type', 'status'),
                'prescriptions',
            ])
            ->orderByDesc('created_at')
            ->paginate(15);

        AuditLogger::log($request->user(), 'patient.records_viewed', null, null, [
            'patient_id' => $patient->id,
        ]);

        return response()->json($records);
    }

    public function prescriptions(Request $request): JsonResponse
    {
        $patient = $request->user()->patient;

        if (! $patient) {
            return response()->json(['message' => 'Patient profile not found.'], 404);
        }

        $prescriptions = Prescription::query()
            ->whereHas('consultationRecord.appointment', fn ($q) => $q->where('patient_id', $patient->id))
            ->with([
                'consultationRecord.appointment.doctor.user:id,name',
                'consultationRecord:id,appointment_id,diagnosis',
            ])
            ->orderByDesc('created_at')
            ->paginate(15);

        return response()->json($prescriptions);
    }
}
