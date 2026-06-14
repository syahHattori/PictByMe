k<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use Illuminate\Notifications\Messages\BroadcastMessage;

class PinLikedNotification extends Notification
{
    use Queueable;

    protected $user;
    protected $pin;

    public function __construct($user, $pin)
    {
        $this->user = $user;
        $this->pin = $pin;
    }

    public function via($notifiable)
    {
        return [
            'database',
            'broadcast'
        ];
    }

    public function toArray($notifiable)
    {
        return [
            'type' => 'pin_liked',
            'message' => $this->user->username . ' liked your pin',
            'pin_id' => $this->pin->id,
            'user_id' => $this->user->id,
            'username' => $this->user->username,
        ];
    }

    public function toBroadcast($notifiable)
    {
        return new BroadcastMessage(
            $this->toArray($notifiable)
        );
    }
}
