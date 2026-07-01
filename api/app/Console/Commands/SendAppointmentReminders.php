<?php

namespace App\Console\Commands;

use App\Mail\AppointmentReminderMail;
use App\Models\AppNotification;
use App\Models\Appointment;
use App\Services\PushNotificationService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Mail;

class SendAppointmentReminders extends Command
{
    protected $signature = 'appointments:send-reminders';

    protected $description = 'Send 24h and 1h appointment reminders via email, in-app, and push';

    public function handle(): int
    {
        $this->sendWindow(hours: 24, column: 'reminder_24h_sent_at', label: '24 hours');
        $this->sendWindow(hours: 1, column: 'reminder_1h_sent_at', label: '1 hour');

        $this->info('Appointment reminders processed.');

        return self::SUCCESS;
    }

    private function sendWindow(int $hours, string $column, string $label): void
    {
        $from = now()->addHours($hours)->subMinutes(15);
        $to = now()->addHours($hours)->addMinutes(15);

        $appointments = Appointment::query()
            ->where('status', 'confirmed')
            ->whereNull($column)
            ->whereBetween('scheduled_at', [$from, $to])
            ->with(['patient.user', 'doctor.user'])
            ->get();

        foreach ($appointments as $appointment) {
            $patientUser = $appointment->patient?->user;

            if (! $patientUser) {
                continue;
            }

            $title = "Appointment in {$label}";
            $body = "With {$appointment->doctor->user->name} at {$appointment->scheduled_at->format('M j, g:i A')}";

            Mail::to($patientUser->email)->send(new AppointmentReminderMail($appointment, $label));

            AppNotification::create([
                'user_id' => $patientUser->id,
                'type' => 'appointment_reminder',
                'title' => $title,
                'body' => $body,
            ]);

            PushNotificationService::send($patientUser, $title, $body, [
                'type' => 'appointment_reminder',
                'appointment_id' => (string) $appointment->id,
            ]);

            $appointment->update([$column => now()]);
        }

        $this->line("{$label}: {$appointments->count()} reminder(s) sent.");
    }
}
