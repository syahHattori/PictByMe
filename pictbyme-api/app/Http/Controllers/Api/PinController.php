<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Pin;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

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

        return response()->json([
            'success' => true,
            'data' => $pin
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

            $url = Storage::disk('public')->url($path);

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
}

