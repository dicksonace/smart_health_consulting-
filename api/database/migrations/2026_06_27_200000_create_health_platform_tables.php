<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('phone')->nullable()->after('password');
            $table->enum('role', ['patient', 'doctor', 'admin'])->default('patient')->after('phone');
        });

        Schema::create('patients', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->date('date_of_birth')->nullable();
            $table->string('gender')->nullable();
            $table->string('blood_group')->nullable();
            $table->text('allergies')->nullable();
            $table->text('medical_summary')->nullable();
            $table->timestamps();
        });

        Schema::create('doctors', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('specialty');
            $table->text('qualifications')->nullable();
            $table->unsignedInteger('years_experience')->nullable();
            $table->decimal('consultation_fee', 10, 2);
            $table->text('bio')->nullable();
            $table->boolean('is_verified')->default(false);
            $table->decimal('rating_avg', 3, 2)->default(0);
            $table->timestamps();
        });

        Schema::create('doctor_availability', function (Blueprint $table) {
            $table->id();
            $table->foreignId('doctor_id')->constrained()->cascadeOnDelete();
            $table->date('date');
            $table->time('start_time');
            $table->time('end_time');
            $table->enum('status', ['available', 'booked', 'blocked'])->default('available');
            $table->timestamps();

            $table->unique(['doctor_id', 'date', 'start_time']);
        });

        Schema::create('appointments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained()->cascadeOnDelete();
            $table->foreignId('doctor_id')->constrained()->cascadeOnDelete();
            $table->foreignId('availability_id')->nullable()->constrained('doctor_availability')->nullOnDelete();
            $table->dateTime('scheduled_at');
            $table->enum('type', ['in_person', 'video', 'chat']);
            $table->enum('status', ['confirmed', 'completed', 'cancelled', 'no_show'])->default('confirmed');
            $table->text('reason')->nullable();
            $table->enum('urgency', ['low', 'medium', 'high', 'emergency'])->nullable();
            $table->timestamps();
        });

        Schema::create('consultation_records', function (Blueprint $table) {
            $table->id();
            $table->foreignId('appointment_id')->unique()->constrained()->cascadeOnDelete();
            $table->text('diagnosis')->nullable();
            $table->text('notes')->nullable();
            $table->text('recommendations')->nullable();
            $table->timestamps();
        });

        Schema::create('prescriptions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('consultation_record_id')->constrained()->cascadeOnDelete();
            $table->string('medicine_name');
            $table->string('dosage');
            $table->string('duration');
            $table->text('instructions')->nullable();
            $table->timestamps();
        });

        Schema::create('messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('sender_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('receiver_id')->constrained('users')->cascadeOnDelete();
            $table->text('body');
            $table->string('attachment_path')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->timestamps();
        });

        Schema::create('symptom_checker_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('patient_id')->constrained()->cascadeOnDelete();
            $table->json('symptoms');
            $table->string('suggested_specialty')->nullable();
            $table->enum('urgency', ['low', 'medium', 'high', 'emergency']);
            $table->timestamps();
        });

        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('type');
            $table->string('title');
            $table->text('body');
            $table->timestamp('read_at')->nullable();
            $table->timestamps();
        });

        Schema::create('feedback', function (Blueprint $table) {
            $table->id();
            $table->foreignId('appointment_id')->unique()->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('rating');
            $table->text('comment')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('feedback');
        Schema::dropIfExists('notifications');
        Schema::dropIfExists('symptom_checker_logs');
        Schema::dropIfExists('messages');
        Schema::dropIfExists('prescriptions');
        Schema::dropIfExists('consultation_records');
        Schema::dropIfExists('appointments');
        Schema::dropIfExists('doctor_availability');
        Schema::dropIfExists('doctors');
        Schema::dropIfExists('patients');

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['phone', 'role']);
        });
    }
};
