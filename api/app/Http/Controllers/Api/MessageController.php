<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\Message;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

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

        $conversations = $partnerIds->map(function ($partnerId) use ($userId) {
            $partner = User::select('id', 'name', 'email', 'role')->find($partnerId);

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
        })->sortByDesc(fn ($c) => $c['last_message']?->created_at)->values();

        return response()->json($conversations);
    }

    public function index(Request $request, User $user): JsonResponse
    {
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

        return response()->json($messages);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'receiver_id' => ['required', 'exists:users,id'],
            'body' => ['required', 'string'],
            'attachment_path' => ['nullable', 'string', 'max:500'],
        ]);

        $sender = $request->user();

        if ((int) $validated['receiver_id'] === $sender->id) {
            return response()->json(['message' => 'Cannot send a message to yourself.'], 422);
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

        $message->load(['sender:id,name', 'receiver:id,name']);

        return response()->json($message, 201);
    }
}
