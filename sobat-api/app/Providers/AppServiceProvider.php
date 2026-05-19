<?php

namespace App\Providers;

use App\Models\Payroll;
use App\Models\PayrollCelluller;
use App\Models\PayrollFnb;
use App\Models\PayrollHans;
use App\Models\PayrollMaximum;
use App\Models\PayrollMm;
use App\Models\PayrollMoneyChanger;
use App\Models\PayrollRef;
use App\Models\PayrollTungtau;
use App\Models\PayrollWrapping;
use App\Observers\PayrollObserver;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Global API Rate Limiter (Increased to 120/min for SPA polling)
        \Illuminate\Support\Facades\RateLimiter::for('api', function (\Illuminate\Http\Request $request) {
            return \Illuminate\Cache\RateLimiting\Limit::perMinute(120)->by($request->user()?->id ?: $request->ip());
        });

        // Strict Login Limiter (5 attempts per minute)
        \Illuminate\Support\Facades\RateLimiter::for('login', function (\Illuminate\Http\Request $request) {
            return \Illuminate\Cache\RateLimiting\Limit::perMinute(5)->by($request->ip());
        });

        // Strict PIN Verification Limiter (5 attempts per minute)
        \Illuminate\Support\Facades\RateLimiter::for('pin', function (\Illuminate\Http\Request $request) {
            return \Illuminate\Cache\RateLimiting\Limit::perMinute(5)->by($request->user()?->id ?: $request->ip());
        });

        // Payroll observers — send FCM push when payroll is approved
        $payrollModels = [
            Payroll::class,
            PayrollFnb::class,
            PayrollMm::class,
            PayrollRef::class,
            PayrollCelluller::class,
            PayrollHans::class,
            PayrollWrapping::class,
            PayrollMoneyChanger::class,
            PayrollMaximum::class,
            PayrollTungtau::class,
        ];

        foreach ($payrollModels as $model) {
            $model::observe(PayrollObserver::class);
        }
    }
}
