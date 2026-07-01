<?php

namespace App\Policies;

use App\Models\Appointment;
use App\Models\User;

class AppointmentPolicy
{
    public function view(User $user, Appointment $appointment): bool
    {
        return $this->canManage($user, $appointment);
    }

    public function update(User $user, Appointment $appointment): bool
    {
        return $this->canManage($user, $appointment);
    }

    public function delete(User $user, Appointment $appointment): bool
    {
        return $this->canManage($user, $appointment);
    }

    private function canManage(User $user, Appointment $appointment): bool
    {
        if ($user->isAdmin()) {
            return true;
        }

        if ($user->isPatient() && $user->patient?->id === $appointment->patient_id) {
            return true;
        }

        if ($user->isDoctor() && $user->doctor?->id === $appointment->doctor_id) {
            return true;
        }

        return false;
    }
}
