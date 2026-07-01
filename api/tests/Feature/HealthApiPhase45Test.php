<?php

namespace Tests\Feature;

use App\Models\Appointment;
use App\Models\Doctor;
use App\Models\DoctorAvailability;
use App\Models\Patient;
use App\Models\User;
use App\Services\RealtimeService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Tests\TestCase;

class HealthApiPhase45Test extends TestCase
{
    use RefreshDatabase;

    public function test_realtime_poll_returns_events_for_authenticated_user(): void
    {
        $doctorUser = User::factory()->create(['role' => 'doctor']);
        Doctor::create([
            'user_id' => $doctorUser->id,
            'specialty' => 'General Practice',
            'consultation_fee' => 100,
            'is_verified' => true,
        ]);

        RealtimeService::push($doctorUser->id, 'new_message', [
            'sender_id' => 99,
            'body_preview' => 'Hello doctor',
        ]);

        $events = $this->actingAs($doctorUser, 'sanctum')
            ->getJson('/api/realtime/poll')
            ->assertOk()
            ->json('events');

        $this->assertNotEmpty($events);
        $this->assertSame('new_message', $events[0]['type']);
    }

    public function test_message_send_creates_realtime_event(): void
    {
        $patient = User::factory()->create(['role' => 'patient']);
        $patientModel = Patient::create(['user_id' => $patient->id]);
        $doctorUser = User::factory()->create(['role' => 'doctor']);
        $doctor = Doctor::create([
            'user_id' => $doctorUser->id,
            'specialty' => 'General Practice',
            'consultation_fee' => 100,
            'is_verified' => true,
        ]);

        Appointment::create([
            'patient_id' => $patientModel->id,
            'doctor_id' => $doctor->id,
            'scheduled_at' => now()->addDay(),
            'type' => 'chat',
            'status' => 'confirmed',
        ]);

        $this->actingAs($patient, 'sanctum')
            ->postJson('/api/messages', [
                'receiver_id' => $doctorUser->id,
                'body' => 'Hello doctor',
            ])
            ->assertCreated();

        $this->assertDatabaseHas('realtime_events', [
            'user_id' => $doctorUser->id,
            'type' => 'new_message',
        ]);
    }

    public function test_booking_emits_slot_booked_event_for_doctor_feed(): void
    {
        $patient = User::factory()->create(['role' => 'patient']);
        Patient::create(['user_id' => $patient->id]);
        $doctorUser = User::factory()->create(['role' => 'doctor']);
        $doctor = Doctor::create([
            'user_id' => $doctorUser->id,
            'specialty' => 'Dermatology',
            'consultation_fee' => 100,
            'is_verified' => true,
        ]);

        $slot = DoctorAvailability::create([
            'doctor_id' => $doctor->id,
            'date' => now()->addDay()->toDateString(),
            'start_time' => '10:00',
            'end_time' => '10:30',
            'status' => 'available',
        ]);

        $this->withToken($patient->createToken('test')->plainTextToken)->postJson('/api/appointments', [
            'doctor_id' => $doctor->id,
            'availability_id' => $slot->id,
            'type' => 'video',
        ])->assertCreated();

        $events = RealtimeService::poll($doctorUser->id, doctorId: $doctor->id);
        $types = array_column($events, 'type');

        $this->assertContains('slot_booked', $types);
    }

    public function test_video_room_endpoint_returns_jitsi_url(): void
    {
        $patient = User::factory()->create(['role' => 'patient']);
        $patientModel = Patient::create(['user_id' => $patient->id]);
        $doctorUser = User::factory()->create(['role' => 'doctor']);
        $doctor = Doctor::create([
            'user_id' => $doctorUser->id,
            'specialty' => 'General Practice',
            'consultation_fee' => 100,
            'is_verified' => true,
        ]);

        $appointment = Appointment::create([
            'patient_id' => $patientModel->id,
            'doctor_id' => $doctor->id,
            'scheduled_at' => now()->addMinutes(3),
            'type' => 'video',
            'status' => 'confirmed',
        ]);

        $this->withToken($patient->createToken('test')->plainTextToken)
            ->getJson("/api/appointments/{$appointment->id}/video-room")
            ->assertOk()
            ->assertJsonPath('provider', 'jitsi')
            ->assertJsonPath('can_join', true)
            ->assertJsonStructure(['join_url', 'room_name', 'opens_at']);
    }

    public function test_symptom_checker_includes_disclaimer_and_actions(): void
    {
        $this->postJson('/api/symptom-check', [
            'symptoms' => ['chest pain', 'severe'],
        ])
            ->assertOk()
            ->assertJsonStructure(['specialty', 'urgency', 'disclaimer', 'suggested_actions'])
            ->assertJsonPath('urgency', 'emergency');
    }

    public function test_device_token_can_be_registered(): void
    {
        $user = User::factory()->create(['role' => 'patient']);
        Patient::create(['user_id' => $user->id]);

        $this->withToken($user->createToken('test')->plainTextToken)
            ->postJson('/api/device-token', ['fcm_token' => 'test-fcm-token-123'])
            ->assertOk();

        $this->assertSame('test-fcm-token-123', $user->fresh()->fcm_token);
    }

    public function test_reminder_command_sends_for_upcoming_appointment(): void
    {
        $patient = User::factory()->create(['role' => 'patient', 'email' => 'reminder@test.com']);
        $patientModel = Patient::create(['user_id' => $patient->id]);
        $doctorUser = User::factory()->create(['role' => 'doctor']);
        $doctor = Doctor::create([
            'user_id' => $doctorUser->id,
            'specialty' => 'General Practice',
            'consultation_fee' => 100,
            'is_verified' => true,
        ]);

        Appointment::create([
            'patient_id' => $patientModel->id,
            'doctor_id' => $doctor->id,
            'scheduled_at' => now()->addHours(24),
            'type' => 'video',
            'status' => 'confirmed',
        ]);

        Artisan::call('appointments:send-reminders');

        $this->assertDatabaseHas('notifications', [
            'user_id' => $patient->id,
            'type' => 'appointment_reminder',
        ]);
    }
}
