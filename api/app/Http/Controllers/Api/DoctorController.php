<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Doctor;
use App\Models\DoctorAvailability;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class DoctorController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Doctor::query()
            ->with('user:id,name,email,phone')
            ->where('is_verified', true)
            ->where('is_suspended', false);

        if ($request->filled('specialty')) {
            $query->where('specialty', 'like', '%'.$request->string('specialty').'%');
        }

        if ($request->filled('min_rating')) {
            $query->where('rating_avg', '>=', $request->float('min_rating'));
        }

        if ($request->filled('search')) {
            $search = $request->string('search');
            $query->where(function ($q) use ($search) {
                $q->where('specialty', 'like', "%{$search}%")
                    ->orWhereHas('user', fn ($u) => $u->where('name', 'like', "%{$search}%"));
            });
        }

        $doctors = $query->orderByDesc('rating_avg')->paginate(15);

        return response()->json($doctors);
    }

    public function show(Doctor $doctor): JsonResponse
    {
        if (! $doctor->is_verified || $doctor->is_suspended) {
            return response()->json(['message' => 'Doctor not found.'], 404);
        }

        $doctor->load([
            'user:id,name,email,phone',
            'availability' => fn ($q) => $q->where('status', 'available')
                ->where('date', '>=', now()->toDateString())
                ->orderBy('date')
                ->orderBy('start_time'),
        ]);

        return response()->json($doctor);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $doctor = $request->user()->doctor;

        if (! $doctor) {
            return response()->json(['message' => 'Doctor profile not found.'], 404);
        }

        $validated = $request->validate([
            'specialty' => ['sometimes', 'string', 'max:255'],
            'qualifications' => ['nullable', 'string'],
            'years_experience' => ['nullable', 'integer', 'min:0'],
            'consultation_fee' => ['sometimes', 'numeric', 'min:0'],
            'bio' => ['nullable', 'string'],
            'name' => ['sometimes', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:20'],
        ]);

        if (isset($validated['name']) || array_key_exists('phone', $validated)) {
            $request->user()->update(array_filter([
                'name' => $validated['name'] ?? null,
                'phone' => $validated['phone'] ?? null,
            ], fn ($v) => $v !== null));
        }

        $doctor->update(collect($validated)->except(['name', 'phone'])->filter()->all());
        $doctor->load('user:id,name,email,phone');

        return response()->json($doctor);
    }

    public function availabilityIndex(Request $request): JsonResponse
    {
        $doctor = $request->user()->doctor;

        if (! $doctor) {
            return response()->json(['message' => 'Doctor profile not found.'], 404);
        }

        $slots = $doctor->availability()
            ->when($request->filled('date'), fn ($q) => $q->whereDate('date', $request->date('date')))
            ->when($request->filled('status'), fn ($q) => $q->where('status', $request->string('status')))
            ->orderBy('date')
            ->orderBy('start_time')
            ->get();

        return response()->json($slots);
    }

    public function availabilityStore(Request $request): JsonResponse
    {
        $doctor = $request->user()->doctor;

        if (! $doctor) {
            return response()->json(['message' => 'Doctor profile not found.'], 404);
        }

        $validated = $request->validate([
            'date' => ['required', 'date', 'after_or_equal:today'],
            'start_time' => ['required', 'date_format:H:i'],
            'end_time' => ['required', 'date_format:H:i', 'after:start_time'],
            'status' => ['sometimes', Rule::in(['available', 'blocked'])],
        ]);

        $slot = $doctor->availability()->create([
            'date' => $validated['date'],
            'start_time' => $validated['start_time'],
            'end_time' => $validated['end_time'],
            'status' => $validated['status'] ?? 'available',
        ]);

        return response()->json($slot, 201);
    }

    public function availabilityUpdate(Request $request, DoctorAvailability $availability): JsonResponse
    {
        $doctor = $request->user()->doctor;

        if (! $doctor || $availability->doctor_id !== $doctor->id) {
            return response()->json(['message' => 'Forbidden.'], 403);
        }

        if ($availability->status === 'booked') {
            return response()->json(['message' => 'Cannot modify a booked slot.'], 422);
        }

        $validated = $request->validate([
            'date' => ['sometimes', 'date', 'after_or_equal:today'],
            'start_time' => ['sometimes', 'date_format:H:i'],
            'end_time' => ['sometimes', 'date_format:H:i'],
            'status' => ['sometimes', Rule::in(['available', 'blocked'])],
        ]);

        $availability->update($validated);

        return response()->json($availability);
    }

    public function availabilityDestroy(Request $request, DoctorAvailability $availability): JsonResponse
    {
        $doctor = $request->user()->doctor;

        if (! $doctor || $availability->doctor_id !== $doctor->id) {
            return response()->json(['message' => 'Forbidden.'], 403);
        }

        if ($availability->status === 'booked') {
            return response()->json(['message' => 'Cannot delete a booked slot.'], 422);
        }

        $availability->delete();

        return response()->json(['message' => 'Availability slot deleted.']);
    }
}
