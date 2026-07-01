<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('realtime_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->cascadeOnDelete();
            $table->foreignId('doctor_id')->nullable()->constrained()->cascadeOnDelete();
            $table->string('type');
            $table->json('data')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
            $table->index(['doctor_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('realtime_events');
    }
};
