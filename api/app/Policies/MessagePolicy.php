<?php

namespace App\Policies;

use App\Models\User;
use App\Services\MessageAuthorization;

class MessagePolicy
{
    public function viewThread(User $user, User $partner): bool
    {
        return MessageAuthorization::canCommunicate($user, $partner)
            || MessageAuthorization::canCommunicate($partner, $user);
    }

    public function send(User $user, User $receiver): bool
    {
        return MessageAuthorization::canCommunicate($user, $receiver);
    }
}
