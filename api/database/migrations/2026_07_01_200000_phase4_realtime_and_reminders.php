<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('fcm_token')->nullable()->after('role');
        });

        Schema::table('appointments', function (Blueprint $table) {
            $table->timestamp('reminder_24h_sent_at')->nullable()->after('urgency');
            $table->timestamp('reminder_1h_sent_at')->nullable()->after('reminder_24h_sent_at');
        });
    }

    public function down(): void
    {
        Schema::table('appointments', function (Blueprint $table) {
            $table->dropColumn(['reminder_24h_sent_at', 'reminder_1h_sent_at']);
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('fcm_token');
        });
    }
};
