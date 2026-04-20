<?php

namespace App\Mail;

use App\Models\Ecole;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class SchoolActivatedMail extends Mailable
{
    use Queueable, SerializesModels;

    public $ecole;
    public $codeAdmin;

    /**
     * Create a new message instance.
     *
     * @return void
     */
    public function __construct(Ecole $ecole, string $codeAdmin)
    {
        $this->ecole = $ecole;
        $this->codeAdmin = $codeAdmin;
    }

    /**
     * Build the message.
     *
     * @return $this
     */
    public function build()
    {
        return $this->subject('Votre école a été activée !')
                    ->view('emails.school_activated');
    }
}
