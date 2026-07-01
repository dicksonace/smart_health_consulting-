<?php

namespace Database\Seeders;

use App\Models\AppNotification;
use App\Models\Appointment;
use App\Models\ConsultationRecord;
use App\Models\Doctor;
use App\Models\DoctorAvailability;
use App\Models\Message;
use App\Models\Patient;
use App\Models\Prescription;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $password = Hash::make('password');

        $admin = User::create([
            'name' => 'Admin User',
            'email' => 'admin@health.test',
            'password' => $password,
            'phone' => '+15550000001',
            'role' => 'admin',
        ]);

        $patientUsers = [
            [
                'name' => 'Alice Johnson',
                'email' => 'alice@health.test',
                'phone' => '+15550000010',
                'profile' => [
                    'date_of_birth' => '1990-05-15',
                    'gender' => 'female',
                    'blood_group' => 'A+',
                    'allergies' => 'Penicillin',
                    'medical_summary' => 'Seasonal allergies, no chronic conditions.',
                ],
            ],
            [
                'name' => 'Bob Smith',
                'email' => 'bob@health.test',
                'phone' => '+15550000011',
                'profile' => [
                    'date_of_birth' => '1985-11-22',
                    'gender' => 'male',
                    'blood_group' => 'O-',
                    'allergies' => null,
                    'medical_summary' => 'Hypertension managed with medication.',
                ],
            ],
        ];

        $patients = collect($patientUsers)->map(function ($data) use ($password) {
            $user = User::create([
                'name' => $data['name'],
                'email' => $data['email'],
                'password' => $password,
                'phone' => $data['phone'],
                'role' => 'patient',
            ]);

            $patient = Patient::create([
                'user_id' => $user->id,
                ...$data['profile'],
            ]);

            return $patient;
        });

        $doctorData = [
            [
                'name' => 'Dr. Sarah Chen',
                'email' => 'sarah.chen@health.test',
                'phone' => '+15550000020',
                'specialty' => 'General Practice',
                'qualifications' => 'MD, MBBS',
                'years_experience' => 12,
                'consultation_fee' => 75.00,
                'bio' => 'Experienced general practitioner focused on preventive care.',
                'is_verified' => true,
                'rating_avg' => 4.50,
            ],
            [
                'name' => 'Dr. James Wilson',
                'email' => 'james.wilson@health.test',
                'phone' => '+15550000021',
                'specialty' => 'Dermatology',
                'qualifications' => 'MD, Dermatology Board Certified',
                'years_experience' => 8,
                'consultation_fee' => 120.00,
                'bio' => 'Specialist in skin conditions and cosmetic dermatology.',
                'is_verified' => true,
                'rating_avg' => 4.80,
            ],
            [
                'name' => 'Dr. Emily Park',
                'email' => 'emily.park@health.test',
                'phone' => '+15550000022',
                'specialty' => 'Cardiology',
                'qualifications' => 'MD, FACC',
                'years_experience' => 15,
                'consultation_fee' => 150.00,
                'bio' => 'Cardiologist specializing in preventive heart health.',
                'is_verified' => false,
                'rating_avg' => 0,
            ],
        ];

        $doctors = collect($doctorData)->map(function ($data) use ($password) {
            $user = User::create([
                'name' => $data['name'],
                'email' => $data['email'],
                'password' => $password,
                'phone' => $data['phone'],
                'role' => 'doctor',
            ]);

            return Doctor::create([
                'user_id' => $user->id,
                'specialty' => $data['specialty'],
                'qualifications' => $data['qualifications'],
                'years_experience' => $data['years_experience'],
                'consultation_fee' => $data['consultation_fee'],
                'bio' => $data['bio'],
                'is_verified' => $data['is_verified'],
                'rating_avg' => $data['rating_avg'],
            ]);
        });

        $slots = [];
        foreach ($doctors->take(2) as $doctor) {
            for ($day = 1; $day <= 5; $day++) {
                $date = now()->addDays($day)->toDateString();
                $slots[] = DoctorAvailability::create([
                    'doctor_id' => $doctor->id,
                    'date' => $date,
                    'start_time' => '09:00',
                    'end_time' => '09:30',
                    'status' => 'available',
                ]);
                $slots[] = DoctorAvailability::create([
                    'doctor_id' => $doctor->id,
                    'date' => $date,
                    'start_time' => '10:00',
                    'end_time' => '10:30',
                    'status' => 'available',
                ]);
            }
        }

        $bookedSlot = $slots[0];
        $bookedSlot->update(['status' => 'booked']);

        $appointment1 = Appointment::create([
            'patient_id' => $patients[0]->id,
            'doctor_id' => $doctors[0]->id,
            'availability_id' => $bookedSlot->id,
            'scheduled_at' => $bookedSlot->date->format('Y-m-d').' 09:00:00',
            'type' => 'video',
            'status' => 'completed',
            'reason' => 'Annual checkup',
            'urgency' => 'low',
        ]);

        $futureSlot = $slots[2];
        $futureSlot->update(['status' => 'booked']);

        Appointment::create([
            'patient_id' => $patients[1]->id,
            'doctor_id' => $doctors[1]->id,
            'availability_id' => $futureSlot->id,
            'scheduled_at' => $futureSlot->date->format('Y-m-d').' 09:00:00',
            'type' => 'in_person',
            'status' => 'confirmed',
            'reason' => 'Persistent rash on arms',
            'urgency' => 'medium',
        ]);

        $record = ConsultationRecord::create([
            'appointment_id' => $appointment1->id,
            'diagnosis' => 'Healthy adult, mild seasonal allergies',
            'notes' => 'Patient reports occasional sneezing in spring. Vitals normal.',
            'recommendations' => 'Continue antihistamines as needed. Follow up in 12 months.',
        ]);

        Prescription::create([
            'consultation_record_id' => $record->id,
            'medicine_name' => 'Cetirizine',
            'dosage' => '10mg once daily',
            'duration' => '30 days',
            'instructions' => 'Take in the evening if symptoms occur.',
        ]);

        Message::create([
            'sender_id' => $patients[0]->user_id,
            'receiver_id' => $doctors[0]->user_id,
            'body' => 'Hi Dr. Chen, I wanted to follow up on my last visit.',
            'read_at' => now(),
        ]);

        Message::create([
            'sender_id' => $doctors[0]->user_id,
            'receiver_id' => $patients[0]->user_id,
            'body' => 'Hello Alice, your results look good. Let me know if symptoms persist.',
            'read_at' => null,
        ]);

        Message::create([
            'sender_id' => $patients[1]->user_id,
            'receiver_id' => $doctors[1]->user_id,
            'body' => 'Dr. Wilson, the rash has spread slightly since our booking.',
        ]);

        AppNotification::create([
            'user_id' => $doctors[0]->user_id,
            'type' => 'appointment_reminder',
            'title' => 'Upcoming Appointment',
            'body' => 'You have an appointment with Alice Johnson tomorrow at 9:00 AM.',
        ]);

        AppNotification::create([
            'user_id' => $patients[0]->user_id,
            'type' => 'new_message',
            'title' => 'New Message',
            'body' => 'Dr. Chen sent you a message.',
        ]);

        unset($admin);
    }
}
