<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Board extends Model
{
    protected $fillable = [
        'user_id',
        'title',
        'description',
        'is_private'
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function pins()
    {
        return $this->belongsToMany(
            Pin::class,
            'board_pin',
            'board_id',
            'pin_id'
        );
    }
}

