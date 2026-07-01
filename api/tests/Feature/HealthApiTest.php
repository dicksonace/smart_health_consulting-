<?php

namespace Tests\Feature;

use App\Models\Doctor;
use App\Models\DoctorAvailability;
use App\Models\Patient;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class HealthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_health_endpoint_returns_ok(): void
    {
        $this->getJson('/api/health')
            ->assertOk()
            ->assertJsonStructure(['status', 'app']);
    }

    public function test_patient_can_login_and_fetch_profile(): void
    {
        $user = User::factory()->create([
            'email' => 'patient@test.com',
            'password' => 'password',
            'role' => 'patient',
        ]);

        Patient::create(['user_id' => $user->id]);

        $login = $this->postJson('/api/login', [
            'email' => 'patient@test.com',
            'password' => 'password',
        ]);

        $login->assertOk()->assertJsonStructure(['token', 'user']);

        $token = $login->json('token');

        $this->withToken($token)
            ->getJson('/api/patient/profile')
            ->assertOk()
            ->assertJsonPath('user.email', 'patient@test.com');
    }

    public function test_public_doctors_list_returns_verified_doctors_only(): void
    {
        $doctorUser = User::factory()->create(['role' => 'doctor']);
        Doctor::create([
            'user_id' => $doctorUser->id,
            'specialty' => 'General Practice',
            'consultation_fee' => 100,
            'is_verified' => true,
        ]);

        $unverifiedUser = User::factory()->create(['role' => 'doctor']);
        Doctor::create([
            'user_id' => $unverifiedUser->id,
            'specialty' => 'Cardiology',
            'consultation_fee' => 200,
            'is_verified' => false,
        ]);

        $response = $this->getJson('/api/doctors');

        $response->assertOk();
        $this->assertCount(1, $response->json('data'));
    }

    public function test_patient_can_book_available_slot_without_double_booking(): void
    {
        $patientUser = User::factory()->create(['role' => 'patient']);
        $patient = Patient::create(['user_id' => $patientUser->id]);

        $doctorUser = User::factory()->create(['role' => 'doctor']);
        $doctor = Doctor::create([
            'user_id' => $doctorUser->id,
            'specialty' => 'Dermatology',
            'consultation_fee' => 150,
            'is_verified' => true,
        ]);

        $slot = DoctorAvailability::create([
            'doctor_id' => $doctor->id,
            'date' => now()->addDay()->toDateString(),
            'start_time' => '09:00',
            'end_time' => '09:30',
            'status' => 'available',
        ]);

        $token = $patientUser->createToken('test')->plainTextToken;

        $this->withToken($token)->postJson('/api/appointments', [
            'doctor_id' => $doctor->id,
            'availability_id' => $slot->id,
            'type' => 'video',
            'reason' => 'Skin check',
        ])->assertCreated();

        $slot->refresh();
        $this->assertSame('booked', $slot->status);

        $otherPatient = User::factory()->create(['role' => 'patient']);
        Patient::create(['user_id' => $otherPatient->id]);
        $otherToken = $otherPatient->createToken('test')->plainTextToken;

        $this->withToken($otherToken)->postJson('/api/appointments', [
            'doctor_id' => $doctor->id,
            'availability_id' => $slot->id,
            'type' => 'video',
        ])->assertStatus(422);
    }

    public function test_symptom_checker_suggests_dermatology_for_rash(): void
    {
        $this->postJson('/api/symptom-check', [
            'symptoms' => ['skin rash on arms'],
        ])
            ->assertOk()
            ->assertJsonPath('specialty', 'Dermatology');
    }

    public function test_admin_can_view_stats(): void
    {
        $admin = User::factory()->create([
            'role' => 'admin',
            'password' => 'password',
        ]);

        $token = $admin->createToken('test')->plainTextToken;

        $this->withToken($token)
            ->getJson('/api/admin/stats')
            ->assertOk()
            ->assertJsonStructure(['users', 'appointments', 'doctors', 'patients', 'feedback']);
    }
}
