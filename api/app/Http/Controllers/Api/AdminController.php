<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use App\Models\AuditLog;
use App\Models\Doctor;
use App\Models\Feedback;
use App\Models\Patient;
use App\Models\User;
use App\Services\AuditLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminController extends Controller
{
    public function stats(): JsonResponse
    {
        $appointmentStats = Appointment::query()
            ->selectRaw('status, count(*) as count')
            ->groupBy('status')
            ->pluck('count', 'status');

        return response()->json([
            'users' => [
                'total' => User::count(),
                'patients' => User::where('role', 'patient')->count(),
                'doctors' => User::where('role', 'doctor')->count(),
                'admins' => User::where('role', 'admin')->count(),
            ],
            'appointments' => [
                'total' => Appointment::count(),
                'by_status' => $appointmentStats,
            ],
            'doctors' => [
                'total' => Doctor::count(),
                'verified' => Doctor::where('is_verified', true)->where('is_suspended', false)->count(),
                'pending_verification' => Doctor::where('is_verified', false)->where('is_suspended', false)->count(),
                'suspended' => Doctor::where('is_suspended', true)->count(),
            ],
            'patients' => Patient::count(),
            'feedback' => [
                'total' => Feedback::count(),
                'average_rating' => round((float) Feedback::avg('rating'), 2),
            ],
        ]);
    }

    public function doctors(Request $request): JsonResponse
    {
        $query = Doctor::query()
            ->with('user:id,name,email,phone')
            ->orderByDesc('created_at');

        if ($request->has('is_verified')) {
            $query->where('is_verified', $request->boolean('is_verified'));
        }

        if ($request->has('is_suspended')) {
            $query->where('is_suspended', $request->boolean('is_suspended'));
        }

        if ($request->filled('specialty')) {
            $query->where('specialty', 'like', '%'.$request->string('specialty').'%');
        }

        return response()->json($query->paginate(15));
    }

    public function verifyDoctor(Request $request, Doctor $doctor): JsonResponse
    {
        if ($doctor->is_suspended) {
            return response()->json(['message' => 'Cannot verify a suspended doctor. Reactivate first.'], 422);
        }

        $doctor->update(['is_verified' => true]);
        $doctor->load('user:id,name,email,phone');

        AuditLogger::log($request->user(), 'doctor.verified', Doctor::class, $doctor->id);

        return response()->json([
            'message' => 'Doctor verified successfully.',
            'doctor' => $doctor,
        ]);
    }

    public function suspendDoctor(Request $request, Doctor $doctor): JsonResponse
    {
        $doctor->update([
            'is_suspended' => true,
            'is_verified' => false,
        ]);
        $doctor->load('user:id,name,email,phone');

        AuditLogger::log($request->user(), 'doctor.suspended', Doctor::class, $doctor->id);

        return response()->json([
            'message' => 'Doctor suspended successfully.',
            'doctor' => $doctor,
        ]);
    }

    public function reactivateDoctor(Request $request, Doctor $doctor): JsonResponse
    {
        $doctor->update(['is_suspended' => false]);
        $doctor->load('user:id,name,email,phone');

        AuditLogger::log($request->user(), 'doctor.reactivated', Doctor::class, $doctor->id);

        return response()->json([
            'message' => 'Doctor reactivated successfully.',
            'doctor' => $doctor,
        ]);
    }

    public function auditLogs(Request $request): JsonResponse
    {
        $query = AuditLog::query()
            ->with('user:id,name,email,role')
            ->orderByDesc('created_at');

        if ($request->filled('action')) {
            $query->where('action', $request->string('action'));
        }

        if ($request->filled('user_id')) {
            $query->where('user_id', $request->integer('user_id'));
        }

        return response()->json($query->paginate(25));
    }
}
