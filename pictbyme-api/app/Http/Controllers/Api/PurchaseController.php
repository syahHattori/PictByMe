<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Pin;
use App\Models\Purchase;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;

class PurchaseController extends Controller
{
    public function store(Request $request, $pinId)
    {
        // Use DB transaction + row locking to prevent race conditions / double-spend
        return DB::transaction(function () use ($request, $pinId) {
            $user = $request->user();

            $pin = Pin::findOrFail($pinId);

            $price = (int) ($pin->price_coin ?? 0);

            if ($price <= 0) {
                return response()->json(['success' => false, 'message' => 'This pin is not for sale'], 400);
            }

            // Lock buyer row for update
            $buyer = User::where('id', $user->id)->lockForUpdate()->first();

            if (!$buyer || ($buyer->coin_balance ?? 0) < $price) {
                return response()->json(['success' => false, 'message' => 'Insufficient coin balance'], 402);
            }

            // Optionally lock pin row (not strictly necessary if pin isn't being updated here)
            // $lockedPin = Pin::where('id', $pin->id)->lockForUpdate()->first();

            // Deduct buyer
            $buyer->coin_balance = $buyer->coin_balance - $price;
            $buyer->save();

            // Credit seller if applicable
            if ($pin->user_id && $pin->user_id !== $buyer->id) {
                $seller = User::where('id', $pin->user_id)->lockForUpdate()->first();
                if ($seller) {
                    $seller->coin_balance = ($seller->coin_balance ?? 0) + $price;
                    $seller->save();
                }
            }

            // create purchase record
            $purchase = Purchase::create([
                'buyer_id' => $buyer->id,
                'pin_id' => $pin->id,
                'price_coin' => $price,
            ]);

            return response()->json(['success' => true, 'message' => 'Purchase successful', 'data' => ['purchase' => $purchase, 'balance' => $buyer->coin_balance]]);
        });
    }
}
