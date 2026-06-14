<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'username' => 'required|string|max:255|unique:users,username',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|min:6|confirmed'
        ]);

        $user = User::create([
            'name' => $request->name,
            'username' => $request->username,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'coin_balance' => 0
        ]);

        $token = $user->createToken('pictbyme')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Register berhasil',
            'token' => $token,
            'user' => $user
        ], 201);
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required'
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Email atau password salah'
            ], 401);
        }

        $token = $user->createToken('pictbyme')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login berhasil',
            'token' => $token,
            'user' => $user
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->tokens()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logout berhasil'
        ]);
    }

    public function profile(Request $request)
    {
        return response()->json([
            'success' => true,
            'user' => $request->user()
        ]);
    }
public function updateProfile(Request $request)
{
    $user = $request->user();

    $request->validate([
        'name' => 'nullable|string|max:255',
        'username' => 'nullable|string|max:255|unique:users,username,' . $user->id,
        'email' => 'nullable|email|unique:users,email,' . $user->id,
        'profile_picture' => 'nullable|string',
    ]);

    $user->update([
        'name' => $request->name ?? $user->name,
        'username' => $request->username ?? $user->username,
        'email' => $request->email ?? $user->email,
        'profile_picture' => $request->profile_picture ?? $user->profile_picture,
    ]);

    return response()->json([
        'success' => true,
        'message' => 'Profile updated',
        'user' => $user->fresh(),
    ]);
}

public function changePassword(Request $request)
{
    $request->validate([
        'current_password' => 'required',
        'password' => 'required|min:6|confirmed',
    ]);

    $user = $request->user();

    if (!Hash::check(
        $request->current_password,
        $user->password
    )) {
        return response()->json([
            'success' => false,
            'message' => 'Current password salah'
        ], 422);
    }

    $user->update([
        'password' => Hash::make(
            $request->password
        )
    ]);

    return response()->json([
        'success' => true,
        'message' => 'Password berhasil diubah'
    ]);
}
}

