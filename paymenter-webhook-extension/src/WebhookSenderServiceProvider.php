<?php

namespace App\Extensions\Custom\WebhookSender;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Event;
use App\Events\Invoice\Updated as InvoiceUpdated;
use App\Events\Order\Created as OrderCreated;
use App\Events\Order\Updated as OrderUpdated;

class WebhookSenderServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap services.
     */
    public function boot(): void
    {
        // Listen to Invoice Updated event
        Event::listen(InvoiceUpdated::class, function (InvoiceUpdated $event) {
            $invoice = $event->invoice;
            
            // Only send webhook when invoice is paid
            if ($invoice->status === 'paid') {
                $this->sendWebhook('invoice.paid', [
                    'event' => 'invoice.paid',
                    'invoice_id' => $invoice->id,
                    'order_id' => $invoice->order_id,
                    'user_id' => $invoice->user_id,
                    'amount' => $invoice->total,
                    'currency' => $invoice->currency ?? 'USD',
                    'status' => $invoice->status,
                    'paid_at' => $invoice->updated_at->toIso8601String(),
                    'metadata' => [
                        'invoice_number' => $invoice->invoice_number ?? null,
                        'user_email' => $invoice->user->email ?? null,
                    ]
                ]);
            }
        });

        // Listen to Order Created event
        Event::listen(OrderCreated::class, function (OrderCreated $event) {
            $order = $event->order;
            
            $this->sendWebhook('order.created', [
                'event' => 'order.created',
                'order_id' => $order->id,
                'user_id' => $order->user_id,
                'product_id' => $order->product_id,
                'status' => $order->status,
                'created_at' => $order->created_at->toIso8601String(),
                'metadata' => [
                    'product_name' => $order->product->name ?? null,
                    'user_email' => $order->user->email ?? null,
                ]
            ]);
        });

        // Listen to Order Updated event
        Event::listen(OrderUpdated::class, function (OrderUpdated $event) {
            $order = $event->order;
            
            // Send webhook on status changes
            $this->sendWebhook('order.updated', [
                'event' => 'order.updated',
                'order_id' => $order->id,
                'user_id' => $order->user_id,
                'product_id' => $order->product_id,
                'status' => $order->status,
                'updated_at' => $order->updated_at->toIso8601String(),
                'metadata' => [
                    'product_name' => $order->product->name ?? null,
                    'user_email' => $order->user->email ?? null,
                ]
            ]);
        });
    }

    /**
     * Send webhook to ActivePieces
     */
    private function sendWebhook(string $eventType, array $data): void
    {
        try {
            $webhookUrl = env('ACTIVEPIECES_WEBHOOK_URL');
            $webhookSecret = env('WEBHOOK_SECRET');

            if (empty($webhookUrl)) {
                \Log::warning('ACTIVEPIECES_WEBHOOK_URL is not configured');
                return;
            }

            // Add timestamp and signature
            $timestamp = time();
            $data['timestamp'] = $timestamp;
            
            // Create HMAC signature for security
            if (!empty($webhookSecret)) {
                $payload = json_encode($data);
                $signature = hash_hmac('sha256', $payload, $webhookSecret);
                $data['signature'] = $signature;
            }

            // Send HTTP POST request to ActivePieces
            $client = new \GuzzleHttp\Client([
                'timeout' => 10,
                'verify' => true,
            ]);

            $response = $client->post($webhookUrl, [
                'json' => $data,
                'headers' => [
                    'Content-Type' => 'application/json',
                    'X-Paymenter-Event' => $eventType,
                    'X-Paymenter-Signature' => $data['signature'] ?? '',
                    'User-Agent' => 'Paymenter-Webhook/1.0',
                ]
            ]);

            if ($response->getStatusCode() >= 200 && $response->getStatusCode() < 300) {
                \Log::info("Webhook sent successfully: {$eventType}", [
                    'event' => $eventType,
                    'status_code' => $response->getStatusCode(),
                ]);
            } else {
                \Log::error("Webhook failed: {$eventType}", [
                    'event' => $eventType,
                    'status_code' => $response->getStatusCode(),
                    'response' => $response->getBody()->getContents(),
                ]);
            }
        } catch (\Exception $e) {
            \Log::error('Webhook sending failed', [
                'event' => $eventType,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
        }
    }
}
