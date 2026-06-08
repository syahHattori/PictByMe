<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});
Route::get('/test-cors', function () {
    return response()->json([
        'ok' => true,
    ]);
});
