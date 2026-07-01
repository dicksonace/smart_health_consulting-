<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Appointment;
use App\Models\Doctor;
use App\Models\Feedback;
use App\Models\Patient;
use App\Models\User;
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
                'verified' => Doctor::where('is_verified', true)->count(),
                'pending_verification' => Doctor::where('is_verified', false)->count(),
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

        if ($request->filled('specialty')) {
            $query->where('specialty', 'like', '%'.$request->string('specialty').'%');
        }

        return response()->json($query->paginate(15));
    }

    public function verifyDoctor(Doctor $doctor): JsonResponse
    {
        $doctor->update(['is_verified' => true]);
        $doctor->load('user:id,name,email,phone');

        return response()->json([
            'message' => 'Doctor verified successfully.',
            'doctor' => $doctor,
        ]);
    }
}
