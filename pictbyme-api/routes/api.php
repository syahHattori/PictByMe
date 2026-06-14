<?php
use App\Http\Controllers\Api\CategoryController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BoardController;
use App\Http\Controllers\Api\PinController;
use App\Http\Controllers\Api\PurchaseController;
use App\Http\Controllers\Api\PaymentController;

/*
|--------------------------------------------------------------------------
| Public Routes
|--------------------------------------------------------------------------
*/

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::get('/categories', [CategoryController::class, 'index']);
Route::get('/pins', [PinController::class, 'index']);

Route::middleware('auth:sanctum')->group(function () {

    Route::get('/pins/mine', [PinController::class, 'mine']);

    Route::get('/profile', [AuthController::class, 'profile']);
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/boards', [BoardController::class, 'index']);
    Route::get('/boards/{id}', [BoardController::class, 'show']);
    Route::post('/boards', [BoardController::class, 'store']);
    Route::post('/boards/{id}/pins', [BoardController::class, 'savePin']);
    Route::delete('/boards/{id}', [BoardController::class, 'destroy']);

    Route::post('/pins', [PinController::class, 'store']);
    Route::post('/pins/upload', [PinController::class, 'upload']);
    Route::put('/pins/{id}', [PinController::class, 'update']);
    Route::delete('/pins/{id}', [PinController::class, 'destroy']);
    Route::post('/pins/{id}/purchase', [PurchaseController::class, 'store']);

    Route::post('/topup', [PaymentController::class, 'generateQr']);
});

Route::get('/pins/{id}', [PinController::class, 'show']);