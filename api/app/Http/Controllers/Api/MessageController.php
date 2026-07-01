<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\StoreMessageRequest;
use App\Models\AppNotification;
use App\Models\Message;
use App\Models\User;
use App\Services\AuditLogger;
use App\Services\PushNotificationService;
use App\Services\RealtimeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;

class MessageController extends Controller
{
    public function conversations(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        $partnerIds = Message::query()
            ->where('sender_id', $userId)
            ->orWhere('receiver_id', $userId)
            ->get(['sender_id', 'receiver_id'])
            ->flatMap(fn ($m) => [$m->sender_id, $m->receiver_id])
            ->unique()
            ->filter(fn ($id) => $id !== $userId)
            ->values();

        $conversations = $partnerIds->map(function ($partnerId) use ($userId, $request) {
            $partner = User::select('id', 'name', 'email', 'role')->find($partnerId);

            if (! $partner || ! Gate::forUser($request->user())->allows('view-message-thread', $partner)) {
                return null;
            }

            $lastMessage = Message::query()
                ->where(function ($q) use ($userId, $partnerId) {
                    $q->where('sender_id', $userId)->where('receiver_id', $partnerId);
                })
                ->orWhere(function ($q) use ($userId, $partnerId) {
                    $q->where('sender_id', $partnerId)->where('receiver_id', $userId);
                })
                ->latest()
                ->first();

            $unreadCount = Message::query()
                ->where('sender_id', $partnerId)
                ->where('receiver_id', $userId)
                ->whereNull('read_at')
                ->count();

            return [
                'partner' => $partner,
                'last_message' => $lastMessage,
                'unread_count' => $unreadCount,
            ];
        })->filter()->sortByDesc(fn ($c) => $c['last_message']?->created_at)->values();

        return response()->json($conversations);
    }

    public function index(Request $request, User $user): JsonResponse
    {
        if (! Gate::forUser($request->user())->allows('view-message-thread', $user)) {
            return response()->json(['message' => 'Forbidden.'], 403);
        }

        $authUser = $request->user();

        $messages = Message::query()
            ->where(function ($q) use ($authUser, $user) {
                $q->where('sender_id', $authUser->id)->where('receiver_id', $user->id);
            })
            ->orWhere(function ($q) use ($authUser, $user) {
                $q->where('sender_id', $user->id)->where('receiver_id', $authUser->id);
            })
            ->with(['sender:id,name', 'receiver:id,name'])
            ->orderBy('created_at')
            ->paginate(50);

        Message::query()
            ->where('sender_id', $user->id)
            ->where('receiver_id', $authUser->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        AuditLogger::log($authUser, 'message.thread_viewed', User::class, $user->id);

        return response()->json($messages);
    }

    public function store(StoreMessageRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $sender = $request->user();
        $receiver = User::findOrFail($validated['receiver_id']);

        if (! Gate::forUser($sender)->allows('send-message', $receiver)) {
            return response()->json([
                'message' => 'You can only message doctors or patients you have an appointment with.',
            ], 403);
        }

        $message = DB::transaction(function () use ($validated, $sender) {
            $message = Message::create([
                'sender_id' => $sender->id,
                'receiver_id' => $validated['receiver_id'],
                'body' => $validated['body'],
                'attachment_path' => $validated['attachment_path'] ?? null,
            ]);

            AppNotification::create([
                'user_id' => $validated['receiver_id'],
                'type' => 'new_message',
                'title' => 'New Message',
                'body' => substr($validated['body'], 0, 100),
            ]);

            return $message;
        });

        AuditLogger::log($sender, 'message.sent', Message::class, $message->id, [
            'receiver_id' => $receiver->id,
        ]);

        RealtimeService::push((int) $validated['receiver_id'], 'new_message', [
            'sender_id' => $sender->id,
            'message_id' => $message->id,
            'partner_id' => $sender->id,
            'body_preview' => substr($validated['body'], 0, 80),
        ]);

        PushNotificationService::send(
            $receiver,
            'New Message',
            substr($validated['body'], 0, 100),
            ['type' => 'new_message', 'sender_id' => (string) $sender->id],
        );

        $message->load(['sender:id,name', 'receiver:id,name']);

        return response()->json($message, 201);
    }
}
