<?php

namespace App\Services;

use App\Models\RealtimeEvent;

class RealtimeService
{
    public static function push(int $userId, string $type, array $data = []): void
    {
        RealtimeEvent::create([
            'user_id' => $userId,
            'type' => $type,
            'data' => $data,
        ]);
    }

    public static function pushForDoctor(int $doctorId, string $type, array $data = []): void
    {
        RealtimeEvent::create([
            'doctor_id' => $doctorId,
            'type' => $type,
            'data' => $data,
        ]);
    }

    /**
     * @return array<int, array{id: string, type: string, data: array, at: string}>
     */
    public static function poll(int $userId, ?string $since = null, ?int $doctorId = null): array
    {
        $userEvents = RealtimeEvent::query()
            ->where('user_id', $userId)
            ->when($since, fn ($q) => $q->where('created_at', '>', $since))
            ->orderBy('created_at')
            ->limit(50)
            ->get();

        $doctorEvents = collect();

        if ($doctorId !== null) {
            $doctorEvents = RealtimeEvent::query()
                ->where('doctor_id', $doctorId)
                ->when($since, fn ($q) => $q->where('created_at', '>', $since))
                ->orderBy('created_at')
                ->limit(50)
                ->get();
        }

        return $userEvents->merge($doctorEvents)
            ->sortBy('created_at')
            ->values()
            ->map(fn (RealtimeEvent $event) => [
                'id' => (string) $event->id,
                'type' => $event->type,
                'data' => $event->data ?? [],
                'at' => $event->created_at->toIso8601String(),
            ])
            ->all();
    }
}
