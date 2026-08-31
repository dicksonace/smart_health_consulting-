<?php

namespace App\Console\Commands;

use App\Models\Doctor;
use App\Models\DoctorAvailability;
use Illuminate\Console\Command;

class RefreshDoctorAvailability extends Command
{
    protected $signature = 'doctors:refresh-availability {--days=14 : Number of days ahead to ensure slots for}';

    protected $description = 'Create morning/afternoon availability slots for verified doctors (skips existing slots)';

    public function handle(): int
    {
        $days = max(1, (int) $this->option('days'));
        $created = 0;

        $doctors = Doctor::query()
            ->where('is_verified', true)
            ->where('is_suspended', false)
            ->get();

        foreach ($doctors as $doctor) {
            for ($offset = 0; $offset < $days; $offset++) {
                $date = now()->addDays($offset)->toDateString();

                foreach ([['09:00', '09:30'], ['10:00', '10:30'], ['14:00', '14:30'], ['15:00', '15:30']] as [$start, $end]) {
                    $exists = DoctorAvailability::query()
                        ->where('doctor_id', $doctor->id)
                        ->whereDate('date', $date)
                        ->where('start_time', $start)
                        ->exists();

                    if ($exists) {
                        continue;
                    }

                    DoctorAvailability::create([
                        'doctor_id' => $doctor->id,
                        'date' => $date,
                        'start_time' => $start,
                        'end_time' => $end,
                        'status' => 'available',
                    ]);
                    $created++;
                }
            }
        }

        $this->info("Created {$created} availability slot(s) for {$doctors->count()} doctor(s).");

        return self::SUCCESS;
    }
}
