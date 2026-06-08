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
        Schema::create('board_pin', function (Blueprint $table) {
            $table->id();

            $table->foreignId('board_id')
                  ->constrained()
                  ->onDelete('cascade');

            $table->foreignId('pin_id')
                  ->constrained()
                  ->onDelete('cascade');

            $table->timestamps();

            $table->unique(['board_id', 'pin_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('board_pin');
    }
};

