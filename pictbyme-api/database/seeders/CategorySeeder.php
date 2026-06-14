<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class CategorySeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $categories = [
            ['name' => 'Food', 'slug' => 'food'],
            ['name' => 'Anime', 'slug' => 'anime'],
            ['name' => 'Wallpaper', 'slug' => 'wallpaper'],
            ['name' => 'Nature', 'slug' => 'nature'],
            ['name' => 'Art', 'slug' => 'art'],
            ['name' => 'Photography', 'slug' => 'photography'],
        ];

        foreach ($categories as $c) {
            Category::firstOrCreate(['slug' => $c['slug']], ['name' => $c['name']]);
        }
    }
}
