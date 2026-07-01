<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\ForgotPasswordRequest;
use App\Http\Requests\Api\ResetPasswordRequest;
use App\Models\User;
use App\Services\AuditLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;

class PasswordResetController extends Controller
{
    public function forgot(ForgotPasswordRequest $request): JsonResponse
    {
        $email = $request->validated('email');
        $user = User::where('email', $email)->first();

        $response = ['message' => 'If that email address exists, a password reset link has been sent.'];

        if (! $user) {
            return response()->json($response);
        }

        $token = Password::broker()->createToken($user);

        AuditLogger::log($user, 'password.reset_requested', User::class, $user->id, [
            'email' => $email,
        ]);

        if (config('app.debug')) {
            $response['debug_token'] = $token;
            $response['debug_note'] = 'Token included because APP_DEBUG=true. Use POST /api/reset-password.';
        }

        return response()->json($response);
    }

    public function reset(ResetPasswordRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $status = Password::reset(
            [
                'email' => $validated['email'],
                'password' => $validated['password'],
                'password_confirmation' => $validated['password_confirmation'] ?? $validated['password'],
                'token' => $validated['token'],
            ],
            function (User $user, string $password) {
                $user->forceFill([
                    'password' => Hash::make($password),
                    'remember_token' => Str::random(60),
                ])->save();

                $user->tokens()->delete();

                AuditLogger::log($user, 'password.reset_completed', User::class, $user->id);
            }
        );

        if ($status !== Password::PASSWORD_RESET) {
            return response()->json([
                'message' => __($status),
            ], 422);
        }

        return response()->json([
            'message' => 'Password has been reset successfully.',
        ]);
    }
}
