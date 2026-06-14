<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Pin;
use App\Models\Like;
use App\Notifications\PinLiked;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Notification;

class PinController extends Controller
{
    public function index()
    {
        $query = Pin::with(['user','category'])->latest();

        // optional filter: ?paid=1 to return only paid pins
        if (request()->query('paid')) {
            $query->where('price_coin', '>', 0);
        }

        $pins = $query->get();

        return response()->json([
            'success' => true,
            'data' => $pins
        ]);
    }

    public function show($id)
    {
        $pin = Pin::with([
            'user',
            'category',
            'boards'
        ])->findOrFail($id);

        // likes count and whether current user liked
        $likesCount = \App\Models\Like::where('pin_id', $pin->id)->count();
        $liked = false;
        if (auth()->check()) {
            $liked = \App\Models\Like::where('pin_id', $pin->id)->where('user_id', auth()->id())->exists();
        }

        $payload = $pin->toArray();
        $payload['likes_count'] = $likesCount;
        $payload['liked'] = $liked;

        return response()->json([
            'success' => true,
            'data' => $payload
        ]);
    }

    public function upload(Request $request)
    {
        // Collect diagnostic data early to help when PHP drops the upload
        $allFiles = $request->allFiles();
        $hasFile = $request->hasFile('file');
        $contentLength = $request->headers->get('content-length');

        $info = [
            'has_file_flag' => $hasFile,
            'all_files' => $allFiles,
            'php_files' => isset($_FILES) ? $_FILES : null,
            'content_length' => $contentLength,
            'upload_max_filesize_ini' => ini_get('upload_max_filesize'),
            'post_max_size_ini' => ini_get('post_max_size'),
        ];

        Log::info('UPLOAD TEST', $info);

        // If PHP dropped the file (no file present), give a clearer error
        if (!$hasFile) {
            return response()->json([
                'success' => false,
                'message' => 'No file found in request. PHP may have rejected the upload (check upload_max_filesize/post_max_size).',
                'errors' => ['file' => ['The file failed to upload.']],
                'info' => $info,
            ], 422);
        }

        // Now validate the incoming file (20MB limit in kilobytes)
        $request->validate([
            'file' => 'required|file|max:20480'
        ]);

        $file = $request->file('file');

        if (!$file || !$file->isValid()) {
            Log::warning('Upload attempt with invalid file after hasFile=true', $info);
            return response()->json([
                'success' => false,
                'message' => 'No valid uploaded file found.',
                'errors' => ['file' => ['The file failed to upload.']],
                'info' => $info,
            ], 422);
        }

        $info['original_name'] = $file->getClientOriginalName();
        $info['size'] = $file->getSize();
        $info['mime'] = $file->getClientMimeType();

        try {
            // Ensure public disk exists; attempt to store
            $path = $file->store('pins', 'public');

            if (!$path) {
                Log::error('Failed to store uploaded file', $info);
                return response()->json([
                    'success' => false,
                    'message' => 'The file failed to upload.',
                    'errors' => ['file' => ['The file failed to upload.']],
                    'info' => $info,
                ], 422);
            }

            $url = url('/image/' . basename($path));

            Log::info('File uploaded', array_merge($info, ['path' => $path, 'url' => $url]));

            return response()->json([
                'success' => true,
                'file_url' => $url,
                'path' => $path,
                'info' => $info,
            ]);
        } catch (\Throwable $e) {
            Log::error('Pin upload failed exception', ['exception' => $e, 'info' => $info]);
            return response()->json([
                'success' => false,
                'message' => 'The file failed to upload.',
                'errors' => ['file' => ['The file failed to upload.']],
                'error' => $e->getMessage(),
                'info' => $info,
            ], 422);
        }
    }
    public function store(Request $request)
    {
        $request->validate([
            'category_id' => 'required|exists:categories,id',
            'title' => 'required|max:255',
            'description' => 'nullable',
            'file_url' => 'required',
            'type' => 'required|in:image,video',
            'price_coin' => 'nullable|integer',
            'is_premium' => 'boolean'
        ]);

        $pin = Pin::create([
            'user_id' => $request->user()->id,
            'category_id' => $request->category_id,
            'title' => $request->title,
            'description' => $request->description,
            'file_url' => $request->file_url,
            'type' => $request->type,
            'price_coin' => $request->price_coin ?? 0,
            'is_premium' => $request->is_premium ?? false,
            'views' => 0
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Pin berhasil dibuat',
            'data' => $pin
        ], 201);
    }

    /**
     * Return pins belonging to the authenticated user.
     */
    public function mine(Request $request)
    {
        $user = $request->user();

        $pins = Pin::with(['user','category'])
            ->where('user_id', $user->id)
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'data' => $pins
        ]);
    }

    /**
     * Update a pin owned by the authenticated user.
     */
    public function update(Request $request, $id)
    {
        $pin = Pin::findOrFail($id);

        // ensure ownership
        if ($request->user()->id !== $pin->user_id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $request->validate([
            'category_id' => 'required|exists:categories,id',
            'title' => 'required|max:255',
            'description' => 'nullable',
            'price_coin' => 'nullable|integer',
            'is_premium' => 'boolean'
        ]);

        $pin->update([
            'category_id' => $request->category_id,
            'title' => $request->title,
            'description' => $request->description,
            'price_coin' => $request->price_coin ?? $pin->price_coin,
            'is_premium' => $request->is_premium ?? $pin->is_premium,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Pin updated',
            'data' => $pin
        ]);
    }

    /**
     * Delete a pin owned by the authenticated user.
     */
    public function destroy(Request $request, $id)
    {
        $pin = Pin::findOrFail($id);

        if ($request->user()->id !== $pin->user_id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        try {
            $pin->delete();
            return response()->json(['success' => true, 'message' => 'Pin deleted']);
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => 'Delete failed', 'error' => $e->getMessage()], 500);
        }
    }

    /**
     * Like a pin (create Like and notify owner).
     */
    public function like(Request $request, $id)
    {
        $user = $request->user();
        $pin = Pin::findOrFail($id);

        // prevent liking own pin
        if ($pin->user_id === $user->id) {
            return response()->json(['success' => false, 'message' => 'Cannot like your own pin'], 400);
        }

        try {
            $like = Like::firstOrCreate([
                'user_id' => $user->id,
                'pin_id' => $pin->id,
            ]);

            // notify owner
            try {
                $owner = $pin->user;
                if ($owner && $owner->id !== $user->id) {
                    Notification::send($owner, new PinLiked($user, $pin));
                }
            } catch (\Throwable $nex) {
                Log::warning('Failed to send PinLiked notification', ['error' => $nex->getMessage()]);
            }

            // return updated like count
            $count = Like::where('pin_id', $pin->id)->count();

            return response()->json(['success' => true, 'liked' => true, 'likes_count' => $count]);
        } catch (\Throwable $e) {
            Log::error('Failed to like pin', ['exception' => $e]);
            return response()->json(['success' => false, 'message' => 'Failed to like'], 500);
        }
    }

    public function unlike(Request $request, $id)
    {
        $user = $request->user();
        $pin = Pin::findOrFail($id);

        try {
            $deleted = Like::where('user_id', $user->id)->where('pin_id', $pin->id)->delete();
            $count = Like::where('pin_id', $pin->id)->count();
            return response()->json(['success' => true, 'liked' => false, 'likes_count' => $count]);
        } catch (\Throwable $e) {
            Log::error('Failed to unlike pin', ['exception' => $e]);
            return response()->json(['success' => false, 'message' => 'Failed to unlike'], 500);
        }
    }
}

