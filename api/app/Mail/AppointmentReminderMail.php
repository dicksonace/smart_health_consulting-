<?php

namespace App\Mail;

use App\Models\Appointment;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class AppointmentReminderMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public Appointment $appointment,
        public string $windowLabel,
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: "Appointment reminder — {$this->windowLabel}",
        );
    }

    public function content(): Content
    {
        $appointment = $this->appointment->loadMissing(['doctor.user', 'patient.user']);

        return new Content(
            htmlString: view('emails.appointment-reminder', [
                'appointment' => $appointment,
                'windowLabel' => $this->windowLabel,
            ])->render(),
        );
    }
}
