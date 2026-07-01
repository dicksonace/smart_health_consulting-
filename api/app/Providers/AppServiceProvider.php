<?php

namespace App\Providers;

use App\Models\Appointment;
use App\Policies\AppointmentPolicy;
use App\Policies\MessagePolicy;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * @var array<class-string, class-string>
     */
    protected $policies = [
        Appointment::class => AppointmentPolicy::class,
    ];

    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        RateLimiter::for('auth', fn ($request) => Limit::perMinute(10)->by($request->ip()));
        RateLimiter::for('symptom-check', fn ($request) => Limit::perMinute(30)->by($request->ip()));

        Gate::policy(Appointment::class, AppointmentPolicy::class);

        Gate::define('view-message-thread', [MessagePolicy::class, 'viewThread']);
        Gate::define('send-message', [MessagePolicy::class, 'send']);
    }
}
