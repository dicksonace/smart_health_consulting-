<?php

namespace Tests\Feature;

use App\Models\Appointment;
use App\Models\AuditLog;
use App\Models\Doctor;
use App\Models\DoctorAvailability;
use App\Models\Patient;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Tests\TestCase;

class HealthApiSecurityTest extends TestCase
{
    use RefreshDatabase;

    private function createPatient(): array
    {
        $user = User::factory()->create(['role' => 'patient', 'password' => 'password']);
        $patient = Patient::create(['user_id' => $user->id]);

        return [$user, $patient];
    }

    private function createDoctor(bool $verified = true, bool $suspended = false): array
    {
        $user = User::factory()->create(['role' => 'doctor', 'password' => 'password']);
        $doctor = Doctor::create([
            'user_id' => $user->id,
            'specialty' => 'General Practice',
            'consultation_fee' => 100,
            'is_verified' => $verified,
            'is_suspended' => $suspended,
        ]);

        return [$user, $doctor];
    }

    public function test_admin_cannot_access_patient_records(): void
    {
        $admin = User::factory()->create(['role' => 'admin', 'password' => 'password']);
        $token = $admin->createToken('test')->plainTextToken;

        $this->withToken($token)
            ->getJson('/api/patient/records')
            ->assertForbidden();
    }

    public function test_patient_cannot_access_admin_stats(): void
    {
        [$user] = $this->createPatient();
        $token = $user->createToken('test')->plainTextToken;

        $this->withToken($token)
            ->getJson('/api/admin/stats')
            ->assertForbidden();
    }

    public function test_suspended_doctor_not_in_public_list(): void
    {
        $this->createDoctor(verified: true, suspended: true);
        [$user, $doctor] = $this->createDoctor(verified: true);

        $response = $this->getJson('/api/doctors');

        $response->assertOk();
        $this->assertCount(1, $response->json('data'));
        $this->assertSame($doctor->id, $response->json('data.0.id'));
    }

    public function test_patient_cannot_book_unverified_doctor(): void
    {
        [$patientUser, $patient] = $this->createPatient();
        [$doctorUser, $doctor] = $this->createDoctor(verified: false);

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
        ])->assertStatus(422);
    }

    public function test_patient_cannot_book_suspended_doctor(): void
    {
        [$patientUser] = $this->createPatient();
        [$doctorUser, $doctor] = $this->createDoctor(verified: true, suspended: true);

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
        ])->assertStatus(422);
    }

    public function test_cancel_appointment_frees_slot(): void
    {
        [$patientUser, $patient] = $this->createPatient();
        [$doctorUser, $doctor] = $this->createDoctor();

        $slot = DoctorAvailability::create([
            'doctor_id' => $doctor->id,
            'date' => now()->addDay()->toDateString(),
            'start_time' => '09:00',
            'end_time' => '09:30',
            'status' => 'available',
        ]);

        $token = $patientUser->createToken('test')->plainTextToken;

        $booked = $this->withToken($token)->postJson('/api/appointments', [
            'doctor_id' => $doctor->id,
            'availability_id' => $slot->id,
            'type' => 'video',
        ])->assertCreated()->json();

        $this->withToken($token)
            ->deleteJson('/api/appointments/'.$booked['id'])
            ->assertOk();

        $slot->refresh();
        $this->assertSame('available', $slot->status);
    }

    public function test_patient_cannot_cancel_another_patients_appointment(): void
    {
        [$patientUser, $patient] = $this->createPatient();
        [$otherUser, $otherPatient] = $this->createPatient();
        [$doctorUser, $doctor] = $this->createDoctor();

        $appointment = Appointment::create([
            'patient_id' => $otherPatient->id,
            'doctor_id' => $doctor->id,
            'scheduled_at' => now()->addDay(),
            'type' => 'video',
            'status' => 'confirmed',
        ]);

        $token = $patientUser->createToken('test')->plainTextToken;

        $this->withToken($token)
            ->deleteJson('/api/appointments/'.$appointment->id)
            ->assertForbidden();
    }

    public function test_doctor_can_complete_consultation_for_own_appointment(): void
    {
        [$patientUser, $patient] = $this->createPatient();
        [$doctorUser, $doctor] = $this->createDoctor();

        $appointment = Appointment::create([
            'patient_id' => $patient->id,
            'doctor_id' => $doctor->id,
            'scheduled_at' => now()->addDay(),
            'type' => 'video',
            'status' => 'confirmed',
        ]);

        $token = $doctorUser->createToken('test')->plainTextToken;

        $this->withToken($token)->postJson('/api/consultations', [
            'appointment_id' => $appointment->id,
            'diagnosis' => 'Healthy',
            'notes' => 'No issues',
            'prescriptions' => [
                ['medicine_name' => 'Vitamin C', 'dosage' => '1 daily', 'duration' => '30 days'],
            ],
        ])->assertCreated();

        $appointment->refresh();
        $this->assertSame('completed', $appointment->status);
    }

    public function test_doctor_cannot_complete_consultation_for_other_doctors_appointment(): void
    {
        [$patientUser, $patient] = $this->createPatient();
        [$doctorUser, $doctor] = $this->createDoctor();
        [$otherDoctorUser, $otherDoctor] = $this->createDoctor();

        $appointment = Appointment::create([
            'patient_id' => $patient->id,
            'doctor_id' => $otherDoctor->id,
            'scheduled_at' => now()->addDay(),
            'type' => 'video',
            'status' => 'confirmed',
        ]);

        $token = $doctorUser->createToken('test')->plainTextToken;

        $this->withToken($token)->postJson('/api/consultations', [
            'appointment_id' => $appointment->id,
            'diagnosis' => 'Test',
        ])->assertForbidden();
    }

    public function test_patient_can_message_doctor_with_appointment(): void
    {
        [$patientUser, $patient] = $this->createPatient();
        [$doctorUser, $doctor] = $this->createDoctor();

        Appointment::create([
            'patient_id' => $patient->id,
            'doctor_id' => $doctor->id,
            'scheduled_at' => now()->addDay(),
            'type' => 'video',
            'status' => 'confirmed',
        ]);

        $token = $patientUser->createToken('test')->plainTextToken;

        $this->withToken($token)->postJson('/api/messages', [
            'receiver_id' => $doctorUser->id,
            'body' => 'Hello doctor',
        ])->assertCreated();
    }

    public function test_patient_can_send_message_with_image_attachment(): void
    {
        [$patientUser, $patient] = $this->createPatient();
        [$doctorUser, $doctor] = $this->createDoctor();

        Appointment::create([
            'patient_id' => $patient->id,
            'doctor_id' => $doctor->id,
            'scheduled_at' => now()->addDay(),
            'type' => 'video',
            'status' => 'confirmed',
        ]);

        $token = $patientUser->createToken('test')->plainTextToken;

        $upload = $this->withToken($token)->post('/api/message-attachments', [
            'file' => \Illuminate\Http\UploadedFile::fake()->image('scan.jpg'),
        ])->assertCreated();

        $path = $upload->json('path');
        $this->assertStringStartsWith('message-attachments/', $path);

        $this->withToken($token)->postJson('/api/messages', [
            'receiver_id' => $doctorUser->id,
            'attachment_path' => $path,
        ])->assertCreated()
            ->assertJsonPath('attachment_path', $path);
    }

    public function test_patient_cannot_message_doctor_without_appointment(): void
    {
        [$patientUser] = $this->createPatient();
        [$doctorUser] = $this->createDoctor();

        $token = $patientUser->createToken('test')->plainTextToken;

        $this->withToken($token)->postJson('/api/messages', [
            'receiver_id' => $doctorUser->id,
            'body' => 'Hello',
        ])->assertForbidden();
    }

    public function test_patient_cannot_message_another_patient(): void
    {
        [$patientUser, $patient] = $this->createPatient();
        [$otherUser] = $this->createPatient();
        [, $doctor] = $this->createDoctor();

        Appointment::create([
            'patient_id' => $patient->id,
            'doctor_id' => $doctor->id,
            'scheduled_at' => now()->addDay(),
            'type' => 'video',
            'status' => 'confirmed',
        ]);

        $token = $patientUser->createToken('test')->plainTextToken;

        $this->withToken($token)->postJson('/api/messages', [
            'receiver_id' => $otherUser->id,
            'body' => 'Hi',
        ])->assertForbidden();
    }

    public function test_login_creates_audit_log(): void
    {
        $user = User::factory()->create([
            'email' => 'audit@test.com',
            'password' => 'password',
            'role' => 'patient',
        ]);
        Patient::create(['user_id' => $user->id]);

        $this->postJson('/api/login', [
            'email' => 'audit@test.com',
            'password' => 'password',
        ])->assertOk();

        $this->assertDatabaseHas('audit_logs', [
            'user_id' => $user->id,
            'action' => 'auth.login',
        ]);
    }

    public function test_admin_can_suspend_and_reactivate_doctor(): void
    {
        $admin = User::factory()->create(['role' => 'admin', 'password' => 'password']);
        [$doctorUser, $doctor] = $this->createDoctor();
        $token = $admin->createToken('test')->plainTextToken;

        $this->withToken($token)
            ->patchJson("/api/admin/doctors/{$doctor->id}/suspend")
            ->assertOk();

        $doctor->refresh();
        $this->assertTrue($doctor->is_suspended);
        $this->assertFalse($doctor->is_verified);

        $this->withToken($token)
            ->patchJson("/api/admin/doctors/{$doctor->id}/reactivate")
            ->assertOk();

        $doctor->refresh();
        $this->assertFalse($doctor->is_suspended);
    }

    public function test_admin_can_view_audit_logs(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        AuditLog::create([
            'user_id' => $admin->id,
            'action' => 'test.action',
        ]);

        $token = $admin->createToken('test')->plainTextToken;

        $this->withToken($token)
            ->getJson('/api/admin/audit-logs')
            ->assertOk()
            ->assertJsonStructure(['data']);
    }

    public function test_password_can_be_reset_with_valid_token(): void
    {
        $user = User::factory()->create([
            'email' => 'reset@test.com',
            'password' => 'oldpassword',
            'role' => 'patient',
        ]);
        Patient::create(['user_id' => $user->id]);

        $token = Password::broker()->createToken($user);

        $this->postJson('/api/reset-password', [
            'email' => 'reset@test.com',
            'token' => $token,
            'password' => 'newpassword123',
            'password_confirmation' => 'newpassword123',
        ])->assertOk();

        $user->refresh();
        $this->assertTrue(Hash::check('newpassword123', $user->password));
    }

    public function test_forgot_password_returns_generic_message_for_unknown_email(): void
    {
        $this->postJson('/api/forgot-password', [
            'email' => 'nobody@test.com',
        ])
            ->assertOk()
            ->assertJsonPath('message', 'If that email address exists, a password reset link has been sent.');
    }
}
