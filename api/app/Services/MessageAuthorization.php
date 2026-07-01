<?php

namespace App\Services;

use App\Models\Appointment;
use App\Models\User;

class MessageAuthorization
{
    public static function canCommunicate(User $sender, User $receiver): bool
    {
        if ($sender->id === $receiver->id) {
            return false;
        }

        if ($sender->isPatient() && $receiver->isDoctor()) {
            return self::hasAppointmentRelationship($sender, $receiver);
        }

        if ($sender->isDoctor() && $receiver->isPatient()) {
            return self::hasAppointmentRelationship($receiver, $sender);
        }

        return false;
    }

    private static function hasAppointmentRelationship(User $patientUser, User $doctorUser): bool
    {
        $patient = $patientUser->patient;
        $doctor = $doctorUser->doctor;

        if (! $patient || ! $doctor) {
            return false;
        }

        return Appointment::query()
            ->where('patient_id', $patient->id)
            ->where('doctor_id', $doctor->id)
            ->whereIn('status', ['confirmed', 'completed'])
            ->exists();
    }
}
