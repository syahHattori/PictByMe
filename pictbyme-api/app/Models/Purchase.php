<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Purchase extends Model
{
    protected $fillable = [
        'buyer_id',
        'pin_id',
        'price_coin',
    ];

    public function buyer()
    {
        return $this->belongsTo(User::class, 'buyer_id');
    }

    public function pin()
    {
        return $this->belongsTo(Pin::class);
    }
}
