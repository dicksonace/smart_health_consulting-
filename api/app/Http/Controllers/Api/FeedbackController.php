<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use App\Models\Doctor;
use App\Models\Feedback;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FeedbackController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $patient = $request->user()->patient;

        if (! $patient) {
            return response()->json(['message' => 'Patient profile not found.'], 404);
        }

        $validated = $request->validate([
            'appointment_id' => ['required', 'exists:appointments,id'],
            'rating' => ['required', 'integer', 'min:1', 'max:5'],
            'comment' => ['nullable', 'string'],
        ]);

        $appointment = Appointment::findOrFail($validated['appointment_id']);

        if ($appointment->patient_id !== $patient->id) {
            return response()->json(['message' => 'Forbidden.'], 403);
        }

        if ($appointment->status !== 'completed') {
            return response()->json(['message' => 'Can only leave feedback for completed appointments.'], 422);
        }

        if ($appointment->feedback) {
            return response()->json(['message' => 'Feedback already submitted for this appointment.'], 422);
        }

        $feedback = DB::transaction(function () use ($validated, $appointment) {
            $feedback = Feedback::create([
                'appointment_id' => $appointment->id,
                'rating' => $validated['rating'],
                'comment' => $validated['comment'] ?? null,
            ]);

            $avgRating = Feedback::query()
                ->join('appointments', 'feedback.appointment_id', '=', 'appointments.id')
                ->where('appointments.doctor_id', $appointment->doctor_id)
                ->avg('feedback.rating');

            Doctor::whereKey($appointment->doctor_id)->update([
                'rating_avg' => round((float) $avgRating, 2),
            ]);

            return $feedback;
        });

        return response()->json($feedback, 201);
    }
}
