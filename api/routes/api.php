<?php

use App\Http\Controllers\Api\AdminController;
use App\Http\Controllers\Api\AppointmentController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ConsultationController;
use App\Http\Controllers\Api\DoctorController;
use App\Http\Controllers\Api\FeedbackController;
use App\Http\Controllers\Api\MessageController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\PatientController;
use App\Http\Controllers\Api\SymptomCheckerController;
use Illuminate\Support\Facades\Route;

Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'app' => config('app.name'),
    ]);
});

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/symptom-check', [SymptomCheckerController::class, 'store']);

Route::get('/doctors', [DoctorController::class, 'index']);
Route::get('/doctors/{doctor}', [DoctorController::class, 'show']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', [AuthController::class, 'user']);

    Route::middleware('role:patient')->prefix('patient')->group(function () {
        Route::get('/profile', [PatientController::class, 'profile']);
        Route::patch('/profile', [PatientController::class, 'updateProfile']);
        Route::get('/records', [PatientController::class, 'records']);
        Route::get('/prescriptions', [PatientController::class, 'prescriptions']);
    });

    Route::middleware('role:doctor')->prefix('doctor')->group(function () {
        Route::get('/profile', fn () => response()->json(request()->user()->doctor?->load('user:id,name,email,phone')));
        Route::patch('/profile', [DoctorController::class, 'updateProfile']);
        Route::get('/availability', [DoctorController::class, 'availabilityIndex']);
        Route::post('/availability', [DoctorController::class, 'availabilityStore']);
        Route::patch('/availability/{availability}', [DoctorController::class, 'availabilityUpdate']);
        Route::delete('/availability/{availability}', [DoctorController::class, 'availabilityDestroy']);
    });

    Route::get('/appointments', [AppointmentController::class, 'index']);
    Route::post('/appointments', [AppointmentController::class, 'store'])->middleware('role:patient');
    Route::patch('/appointments/{appointment}', [AppointmentController::class, 'update']);
    Route::delete('/appointments/{appointment}', [AppointmentController::class, 'destroy']);

    Route::middleware('role:doctor')->post('/consultations', [ConsultationController::class, 'store']);

    Route::get('/conversations', [MessageController::class, 'conversations']);
    Route::get('/messages/{user}', [MessageController::class, 'index']);
    Route::post('/messages', [MessageController::class, 'store']);

    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::patch('/notifications/{notification}/read', [NotificationController::class, 'markRead']);

    Route::post('/feedback', [FeedbackController::class, 'store'])->middleware('role:patient');

    Route::middleware('role:admin')->prefix('admin')->group(function () {
        Route::get('/stats', [AdminController::class, 'stats']);
        Route::get('/doctors', [AdminController::class, 'doctors']);
        Route::patch('/doctors/{doctor}/verify', [AdminController::class, 'verifyDoctor']);
    });
});
