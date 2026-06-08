<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class PaymentController extends Controller
{
    public function generateQr(Request $request)
    {
        $request->validate([
            'amount' => 'required|numeric|min:100'
        ]);

        $response = Http::post(
            'https://onopay.web.id/api/v1/payment/qr/generate',
            [
                'phone_number' => '082274395901',
                'amount' => $request->amount,
                'description' => 'Top Up PictByMe Coin',
                'qr_mode' => 'single_use'
            ]
        );

        return response()->json([
            'laravel_success' => true,
            'onopay_status' => $response->status(),
            'onopay_response' => $response->json(),
        ]);
    }
}
