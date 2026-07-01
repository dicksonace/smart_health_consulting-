<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\LoginRequest;
use App\Http\Requests\Api\RegisterRequest;
use App\Models\Doctor;
use App\Models\Patient;
use App\Models\User;
use App\Services\AuditLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(RegisterRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $user = DB::transaction(function () use ($validated) {
            $user = User::create([
                'name' => $validated['name'],
                'email' => $validated['email'],
                'password' => $validated['password'],
                'phone' => $validated['phone'] ?? null,
                'role' => $validated['role'],
            ]);

            if ($validated['role'] === 'patient') {
                Patient::create([
                    'user_id' => $user->id,
                    'date_of_birth' => $validated['date_of_birth'] ?? null,
                    'gender' => $validated['gender'] ?? null,
                    'blood_group' => $validated['blood_group'] ?? null,
                    'allergies' => $validated['allergies'] ?? null,
                    'medical_summary' => $validated['medical_summary'] ?? null,
                ]);
            } else {
                Doctor::create([
                    'user_id' => $user->id,
                    'specialty' => $validated['specialty'],
                    'consultation_fee' => $validated['consultation_fee'],
                    'qualifications' => $validated['qualifications'] ?? null,
                    'years_experience' => $validated['years_experience'] ?? null,
                    'bio' => $validated['bio'] ?? null,
                ]);
            }

            return $user;
        });

        $token = $user->createToken('auth-token')->plainTextToken;

        AuditLogger::log($user, 'auth.register', User::class, $user->id, [
            'role' => $user->role,
        ]);

        return response()->json([
            'user' => $this->formatUser($user->fresh(['patient', 'doctor'])),
            'token' => $token,
        ], 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $credentials = $request->validated();

        if (! Auth::attempt($credentials)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        /** @var User $user */
        $user = Auth::user();
        $token = $user->createToken('auth-token')->plainTextToken;

        AuditLogger::log($user, 'auth.login', User::class, $user->id);

        return response()->json([
            'user' => $this->formatUser($user->load(['patient', 'doctor'])),
            'token' => $token,
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $user = $request->user();
        AuditLogger::log($user, 'auth.logout', User::class, $user->id);
        $user->currentAccessToken()->delete();

        return response()->json(['message' => 'Logged out successfully.']);
    }

    public function user(Request $request): JsonResponse
    {
        $user = $request->user()->load(['patient', 'doctor']);

        return response()->json($this->formatUser($user));
    }

    private function formatUser(User $user): array
    {
        $data = [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'role' => $user->role,
            'created_at' => $user->created_at,
        ];

        if ($user->relationLoaded('patient') && $user->patient) {
            $data['patient'] = $user->patient;
        }

        if ($user->relationLoaded('doctor') && $user->doctor) {
            $data['doctor'] = $user->doctor;
        }

        return $data;
    }
}
