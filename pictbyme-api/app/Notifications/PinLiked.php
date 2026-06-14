<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use Illuminate\Notifications\Messages\BroadcastMessage;
use Illuminate\Notifications\Messages\DatabaseMessage;

class PinLiked extends Notification
{
    use Queueable;

    protected $fromUser;
    protected $pin;

    public function __construct($fromUser, $pin)
    {
        $this->fromUser = $fromUser;
        $this->pin = $pin;
    }

    public function via($notifiable)
    {
        return ['database', 'broadcast'];
    }

    public function toArray($notifiable)
    {
        return [
            'type' => 'pin_liked',
            'message' => $this->fromUser->username . ' liked your pin',
            'from_user' => [
                'id' => $this->fromUser->id,
                'username' => $this->fromUser->username,
                'profile_picture' => $this->fromUser->profile_picture ?? null,
            ],
            'pin_id' => $this->pin->id,
            'pin_title' => $this->pin->title,
            'created_at' => now(),
        ];
    }

    public function toBroadcast($notifiable)
    {
        return new BroadcastMessage($this->toArray($notifiable));
    }
}
