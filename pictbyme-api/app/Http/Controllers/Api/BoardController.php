<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Board;
use Illuminate\Http\Request;

class BoardController extends Controller
{
    public function index(Request $request)
    {
        $boards = Board::where(
            'user_id',
            $request->user()->id
        )
        ->latest()
        ->get();

        return response()->json([
            'success' => true,
            'data' => $boards
        ]);
    }

    public function show(Request $request, $id)
    {
        $board = Board::with('pins')
            ->where(
                'user_id',
                $request->user()->id
            )
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $board
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'title' => 'required|max:255',
            'description' => 'nullable',
            'is_private' => 'boolean'
        ]);

        $board = Board::create([
            'user_id' => $request->user()->id,
            'title' => $request->title,
            'description' => $request->description,
            'is_private' => $request->is_private ?? false
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Board berhasil dibuat',
            'data' => $board
        ], 201);
    }

    public function savePin(
        Request $request,
        $id
    ) {
        $request->validate([
            'pin_id' => 'required|exists:pins,id'
        ]);

        $board = Board::where(
            'user_id',
            $request->user()->id
        )->findOrFail($id);

        $board->pins()->syncWithoutDetaching([
            $request->pin_id
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Pin berhasil disimpan ke board'
        ]);
    }

    public function destroy(
        Request $request,
        $id
    ) {
        $board = Board::where(
            'user_id',
            $request->user()->id
        )->findOrFail($id);

        $board->delete();

        return response()->json([
            'success' => true,
            'message' => 'Board berhasil dihapus'
        ]);
    }
}
