<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Pin extends Model

{

    protected $fillable = [

        'user_id',

        'category_id',

        'title',

        'description',

        'file_url',

        'type',

        'price_coin',

        'is_premium',

        'views'

    ];

    public function user()

    {

        return $this->belongsTo(User::class);

    }

    public function category()

    {

        return $this->belongsTo(Category::class);

    }

    public function boards()

    {

        return $this->belongsToMany(

            Board::class,

            'board_pin',

            'pin_id',

            'board_id'

        );

    }

}
