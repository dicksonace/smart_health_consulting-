<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class PushNotificationService
{
    public static function send(User $user, string $title, string $body, array $data = []): void
    {
        if (! $user->fcm_token) {
            Log::info('push.skipped_no_token', ['user_id' => $user->id, 'title' => $title]);

            return;
        }

        $serverKey = config('services.fcm.server_key');

        if (! $serverKey) {
            Log::info('push.log_only', [
                'user_id' => $user->id,
                'title' => $title,
                'body' => $body,
                'data' => $data,
            ]);

            return;
        }

        Http::withHeaders([
            'Authorization' => "key={$serverKey}",
            'Content-Type' => 'application/json',
        ])->post('https://fcm.googleapis.com/fcm/send', [
            'to' => $user->fcm_token,
            'notification' => [
                'title' => $title,
                'body' => $body,
            ],
            'data' => $data,
        ]);
    }
}
